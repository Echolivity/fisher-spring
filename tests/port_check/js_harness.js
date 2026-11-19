// Runs device/code/ech_ir_loader.js under Node with mocked Max js globals.
// usage: node js_harness.js <ir.f32 interleaved> <channels> <irsr> <hostsr> <decay> <damping> <out.json>
const fs = require("fs"), vm = require("vm"), path = require("path");
const [irPath, chans, irsr, hostsr, decay, damping, outPath] = process.argv.slice(2);
const raw = new Float32Array(fs.readFileSync(irPath).buffer.slice(0));
const C = +chans, frames = raw.length / C;
const store = {
  IR: { data: [...Array(C)].map((_, c) => Array.from({ length: frames }, (_, i) => raw[i * C + c])) },
  H: { data: [[0], [0]] },
};
class Buffer {
  constructor(name) { this.b = store[name]; }
  framecount() { return this.b.data[0].length; }
  channelcount() { return this.b.data.length; }
  peek(ch, f, n) { return this.b.data[ch - 1].slice(f, f + n); }
  poke(ch, f, v) { const d = this.b.data[ch - 1]; (Array.isArray(v) ? v : [v]).forEach((x, i) => d[f + i] = x); }
  send(msg, n) { if (msg === "sizeinsamps") this.b.data = this.b.data.map(() => new Array(n).fill(0)); }
}
const outs = [];
const ctx = { Buffer, Math, Array, console,
  Task: class { constructor(f, t) { this.f = f; } schedule() {} cancel() {} },
  outlet: (i, ...a) => outs.push([i, ...a]) };
vm.createContext(ctx);
// run the code exactly as embedded in the device (v8.codebox "ech_ir_loader")
const pat = JSON.parse(fs.readFileSync(path.join(__dirname, "../../device/Echolivity.maxpat"), "utf8")).patcher;
const code = pat.boxes.map(b => b.box).find(b => b.varname === "ech_ir_loader").code;
vm.runInContext(code, ctx);
ctx.names("IR", "H");
ctx.sr(+hostsr); ctx.irsr(+irsr); ctx.decay(+decay); ctx.damping(+damping);
const t0 = Date.now(); ctx.load(); const ms = Date.now() - t0;
fs.writeFileSync(outPath, JSON.stringify({ outs, ms, H: store.H.data }));
