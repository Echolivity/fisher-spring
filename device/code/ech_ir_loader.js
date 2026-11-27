// ECHOLIVITY - IR conditioning + partition-spectrum builder for gen~ ech_conv.
// Mirrors reference/engine.py prepare_ir(): resample -> decay/damping envelope
// -> energy normalisation -> head FIR + mid/tail partition spectra (zero latency).
//
// [js ech_ir_loader.js ---echIR ---echH]
// inlet messages:  sr <hz>          host sample rate (dspstate~)
//                  irsr <hz>        sample rate of the loaded IR file (info~)
//                  decay <s>        damping <0..1>   (debounced recompute)
//                  load             IR buffer has been (re)filled
//                  clear            unload IR
// outlet 0: messages for gen~ (bsize, nparts, have_ir)
// outlet 1: status text for the UI

autowatch = 1;
inlets = 1;
outlets = 2;

var irName = jsarguments[1] || "echIR";
var hName = jsarguments[2] || "echH";
var SR = 48000, IRSR = 48000, DECAY = 2.5, DAMP = 0.35;
var MAX_S = 4.0, MAX_PARTS = 400;
var loaded = false;
var task = new Task(rebuild, this);
var cache = null, cacheKey = "";            // resampled IR, reused for decay/damping edits

function sr(x) { if (x > 0 && x !== SR) { SR = x; schedule(); } }
function irsr(x) { if (x > 0) IRSR = x; }
function decay(x) { DECAY = x; schedule(); }
function damping(x) { DAMP = x; schedule(); }
function load() { loaded = true; cacheKey = ""; rebuild(); }
function clear() {
	loaded = false;
	outlet(0, "nparts", -1);
	outlet(0, "have_ir", 0);
	outlet(1, "set", "no IR loaded");
}
function schedule() { if (loaded) { task.cancel(); task.schedule(250); } }

// ---------------------------------------------------------------- helpers
function fft(re, im, n, sgn) {
	var i, j = 0, m, len, half, step, k, wr, wi, ang, vr, vi, ur, ui, t;
	for (i = 0; i < n - 1; i++) {
		if (i < j) {
			t = re[i]; re[i] = re[j]; re[j] = t;
			t = im[i]; im[i] = im[j]; im[j] = t;
		}
		m = n >> 1;
		while (m >= 1 && j >= m) { j -= m; m >>= 1; }
		j += m;
	}
	for (len = 2; len <= n; len <<= 1) {
		half = len >> 1;
		ang = sgn * 2 * Math.PI / len;
		for (k = 0; k < half; k++) {
			wr = Math.cos(ang * k); wi = Math.sin(ang * k);
			for (i = 0; i < n; i += len) {
				vr = re[i + k + half] * wr - im[i + k + half] * wi;
				vi = re[i + k + half] * wi + im[i + k + half] * wr;
				ur = re[i + k]; ui = im[i + k];
				re[i + k] = ur + vr; im[i + k] = ui + vi;
				re[i + k + half] = ur - vr; im[i + k + half] = ui - vi;
			}
		}
	}
}

function zeros(n) { var a = new Array(n); for (var i = 0; i < n; i++) a[i] = 0; return a; }

function lanczosResample(x, ratio) {           // ratio = outSR / inSR
	var a = 8, n = Math.floor(x.length * ratio), y = new Array(n);
	var scale = Math.min(1, ratio);             // low-pass when downsampling
	for (var i = 0; i < n; i++) {
		var t = i / ratio, c = Math.floor(t), s = 0, w = 0;
		for (var k = c - a + 1; k <= c + a; k++) {
			if (k < 0 || k >= x.length) continue;
			var d = (t - k) * scale, L;
			if (d === 0) L = 1;
			else if (Math.abs(d) >= a) L = 0;
			else L = a * Math.sin(Math.PI * d) * Math.sin(Math.PI * d / a) / (Math.PI * Math.PI * d * d);
			s += x[k] * L; w += L;
		}
		y[i] = w !== 0 ? s / w : 0;
	}
	return y;
}

function rt60(x, sr) {                          // Schroeder T20, as estimate_rt60()
	var n = x.length, e = new Array(n), acc = 0, i;
	for (i = n - 1; i >= 0; i--) { acc += x[i] * x[i]; e[i] = acc; }
	if (acc <= 0) return 0;
	var i5 = -1, i25 = -1;
	for (i = 0; i < n; i++) {
		var db = 10 * Math.log(e[i] / e[0] + 1e-30) / Math.LN10;
		if (i5 < 0 && db <= -5) i5 = i;
		if (i25 < 0 && db <= -25) { i25 = i; break; }
	}
	if (i5 < 0 || i25 <= i5) return n / sr;
	var sx = 0, sy = 0, sxx = 0, sxy = 0, m = i25 - i5;
	for (i = i5; i < i25; i++) {
		var tt = i / sr, yy = 10 * Math.log(e[i] / e[0] + 1e-30) / Math.LN10;
		sx += tt; sy += yy; sxx += tt * tt; sxy += tt * yy;
	}
	var slope = (m * sxy - sx * sy) / (m * sxx - sx * sx);
	return slope < 0 ? -60 / slope : 1e9;
}

function fbOnePole(x, c) {                      // zero-phase one-pole low-pass
	var n = x.length, y = new Array(n), s = 0, i;
	for (i = 0; i < n; i++) { s += c * (x[i] - s); y[i] = s; }
	s = 0;
	for (i = n - 1; i >= 0; i--) { s += c * (y[i] - s); y[i] = s; }
	return y;
}

// ---------------------------------------------------------------- main
function rebuild() {
	if (!loaded) return;
	var ib = new Buffer(irName);
	var frames = ib.framecount(), chans = Math.min(ib.channelcount(), 2);
	if (frames < 2) { clear(); outlet(1, "set", "IR empty"); return; }
	outlet(0, "nparts", -1);                    // mute convolver while rewriting H

	var ch = [], c, i, key = SR + "/" + IRSR + "/" + frames;
	if (key !== cacheKey) {
		cache = [];
		for (c = 0; c < chans; c++) {
			var raw = ib.peek(c + 1, 0, frames);
			if (typeof raw === "number") raw = [raw];
			if (raw.length > MAX_S * IRSR + 8) raw = raw.slice(0, Math.ceil(MAX_S * IRSR) + 8);
			if (IRSR !== SR) raw = lanczosResample(raw, SR / IRSR);
			cache.push(raw);
		}
		if (chans === 1) cache.push(cache[0]);
		cacheKey = key;
	}
	for (c = 0; c < 2; c++) ch.push(cache[c].slice(0));
	var n = Math.min(ch[0].length, Math.floor(MAX_S * SR));
	var fade = Math.floor(0.05 * SR);
	for (c = 0; c < 2; c++) {
		ch[c].length = n;
		if (ch[0].length >= MAX_S * SR - 1)
			for (i = 0; i < fade; i++) ch[c][n - 1 - i] *= i / fade;
	}

	// decay / damping envelopes (prepare_ir)
	var mono = new Array(n);
	for (i = 0; i < n; i++) mono[i] = 0.5 * (ch[0][i] + ch[1][i]);
	var rtIr = rt60(mono, SR);
	var extra = Math.max(0, 6.91 * (1 / DECAY - 1 / Math.max(rtIr, 1e-3)));
	var hiExtra = extra + DAMP * 6.91 / 0.6;
	var cs = 1 - Math.exp(-2 * Math.PI * 2000 / SR);
	var energy = 0;
	for (c = 0; c < 2; c++) {
		var lo = fbOnePole(ch[c], cs);
		for (i = 0; i < n; i++) {
			var t = i / SR;
			var v = lo[i] * Math.exp(-extra * t) + (ch[c][i] - lo[i]) * Math.exp(-hiExtra * t);
			ch[c][i] = v;
			energy += v * v;
		}
	}
	var g = 1 / (Math.sqrt(energy / 2) + 1e-12);
	for (c = 0; c < 2; c++) for (i = 0; i < n; i++) ch[c][i] *= g;

	// three-stage layout for ech_conv.genexpr (zero latency):
	//   [0, F)               head FIR taps h[0..F)
	//   [F, offT)            mid: 64-sample partitions of h[F..T0), FFT 128
	//   [offT, ...)          tail: B-sample partitions of h[T0..), FFT 2B
	var F = 128, BM = 64, B = SR > 50000 ? 1024 : 512, T0 = 4 * B;
	var KM = (T0 - F) / BM, offT = F + KM * (BM + 1) * 2;
	var K = Math.min(Math.max(0, Math.ceil((n - T0) / B)), MAX_PARTS);
	var hb = new Buffer(hName);
	hb.send("sizeinsamps", offT + K * (B + 1) * 2);
	var re, im, k, out, idx;
	function spectrum(c, start, len, nfft, at) {
		re = zeros(nfft); im = zeros(nfft);
		for (i = 0; i < len; i++) {
			idx = start + i;
			re[i] = idx < n ? ch[c][idx] : 0;
		}
		fft(re, im, nfft, -1);
		out = new Array(nfft + 2);
		for (i = 0; i <= nfft / 2; i++) { out[2 * i] = re[i]; out[2 * i + 1] = im[i]; }
		hb.poke(c + 1, at, out);
	}
	for (c = 0; c < 2; c++) {
		out = new Array(F);
		for (i = 0; i < F; i++) out[i] = i < n ? ch[c][i] : 0;
		hb.poke(c + 1, 0, out);
		for (k = 0; k < KM; k++) spectrum(c, F + k * BM, BM, 2 * BM, F + k * (BM + 1) * 2);
		for (k = 0; k < K; k++) spectrum(c, T0 + k * B, B, 2 * B, offT + k * (B + 1) * 2);
	}

	outlet(0, "bsize", B);
	outlet(0, "nparts", K);
	outlet(0, "have_ir", 1);
	outlet(1, "set", "IR " + chans + "ch " + IRSR + "Hz  RT60 " + rtIr.toFixed(2) + "s  " +
		(n / SR).toFixed(2) + "s");
}
