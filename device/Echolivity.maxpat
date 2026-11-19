{
 "patcher": {
  "fileversion": 1,
  "appversion": {
   "major": 8,
   "minor": 6,
   "revision": 0,
   "architecture": "x64",
   "modernui": 1
  },
  "classnamespace": "box",
  "rect": [
   40,
   80,
   1300,
   900
  ],
  "openrect": [
   0,
   0,
   0,
   169
  ],
  "openinpresentation": 1,
  "default_fontsize": 10.0,
  "default_fontname": "Arial",
  "gridsize": [
   8,
   8
  ],
  "boxes": [
   {
    "box": {
     "id": "obj-1",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      40,
      40,
      80,
      22
     ],
     "text": "plugin~"
    }
   },
   {
    "box": {
     "id": "obj-2",
     "maxclass": "newobj",
     "numinlets": 4,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      40,
      160,
      160,
      22
     ],
     "text": "gen~",
     "patcher": {
      "fileversion": 1,
      "appversion": {
       "major": 8,
       "minor": 6,
       "revision": 0,
       "architecture": "x64",
       "modernui": 1
      },
      "classnamespace": "dsp.gen",
      "rect": [
       50,
       50,
       760,
       740
      ],
      "boxes": [
       {
        "box": {
         "id": "obj-1",
         "maxclass": "codebox",
         "code": "// ECHOLIVITY gen~ FRONT\n// Port of reference/engine.py: input_stage(), feedback injection, predelay,\n// convolution send routing.\n// in1 L, in2 R, in3 dub feedback return (tapout~), in4 spring->IR send (tapout~)\n// out1 engine input eng (mono), out2 convolution input\n\nParam drive(0.25, min=0, max=1);\nParam predelay(0, min=0, max=250);\nParam engine_mode(2, min=0, max=4);\n\nHistory pe_lp(0);\nHistory de_lp(0);\nHistory dcx(0);\nHistory dcy(0);\nHistory pd_sm(-1);\nDelay pd(30000);\n\nasym(x, k, b) {\n\ttb = tanh(k * b);\n\ts2 = 1 - tb * tb;\n\treturn (tanh(k * (x + b)) - tb) / (k * s2);\n}\n\nmono = 0.5 * (in1 + in2);\n\na_pe = 1 - exp(-twopi * 1500 / samplerate);\npe = 1.5 * drive;\nk = pow(10, drive * 1.5);\nmakeup = pow(k, -0.8);\nh = clamp((drive - 0.6) / 0.4, 0, 1);\nr_dc = 1 - twopi * 10 / samplerate;\n\n// pre-emphasis -> soft/hard saturation -> de-emphasis -> DC block\np1 = pe_lp + a_pe * (mono - pe_lp);\npe_lp = fixdenorm(p1);\nxe = mono + pe * (mono - p1);\nkx = k * xe;\nsoft = asym(kx, 1, 0.15);\nhard = kx / pow(1 + pow(abs(kx), 6), 1 / 6);\ny = ((1 - h) * soft + h * hard) * makeup;\nd1 = de_lp + a_pe * (y - de_lp);\nde_lp = fixdenorm(d1);\ny2 = d1 + (y - d1) / (1 + pe);\ndc = y2 - dcx + r_dc * dcy;\ndcx = y2;\ndcy = fixdenorm(dc);\n\n// dub feedback enters after the drive stage, before predelay (inside the loop)\ne0 = dc + in3;\n\n// predelay (smoothed, linear interpolation)\npd_t = predelay * 0.001 * samplerate;\npd_s = pd_sm < 0 ? pd_t : pd_sm + (pd_t - pd_sm) * 0.002;   // ~10 ms glide, starts on target\npd_sm = pd_s;\npd.write(e0);\neng = pd_s < 1 ? e0 : pd.read(pd_s, interp=\"linear\");\n\nout1 = eng;\n// Model>IR: the IR is excited by the spring output plus half the direct signal\nout2 = engine_mode > 3.5 ? (in4 + 0.5 * eng) : eng;\n",
         "fontface": 0,
         "fontname": "<Monospaced>",
         "fontsize": 11,
         "numinlets": 4,
         "numoutlets": 2,
         "outlettype": [
          "",
          ""
         ],
         "patching_rect": [
          20,
          60,
          700,
          600
         ]
        }
       },
       {
        "box": {
         "id": "obj-2",
         "maxclass": "newobj",
         "text": "in 1",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          20,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-3",
         "maxclass": "newobj",
         "text": "in 2",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          100,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-4",
         "maxclass": "newobj",
         "text": "in 3",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          180,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-5",
         "maxclass": "newobj",
         "text": "in 4",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          260,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-6",
         "maxclass": "newobj",
         "text": "out 1",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          20,
          680,
          45,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-7",
         "maxclass": "newobj",
         "text": "out 2",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          100,
          680,
          45,
          22
         ]
        }
       }
      ],
      "lines": [
       {
        "patchline": {
         "source": [
          "obj-2",
          0
         ],
         "destination": [
          "obj-1",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-3",
          0
         ],
         "destination": [
          "obj-1",
          1
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-4",
          0
         ],
         "destination": [
          "obj-1",
          2
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-5",
          0
         ],
         "destination": [
          "obj-1",
          3
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          0
         ],
         "destination": [
          "obj-6",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          1
         ],
         "destination": [
          "obj-7",
          0
         ]
        }
       }
      ]
     },
     "varname": "ech_front"
    }
   },
   {
    "box": {
     "id": "obj-3",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      40,
      240,
      120,
      22
     ],
     "text": "gen~",
     "patcher": {
      "fileversion": 1,
      "appversion": {
       "major": 8,
       "minor": 6,
       "revision": 0,
       "architecture": "x64",
       "modernui": 1
      },
      "classnamespace": "dsp.gen",
      "rect": [
       50,
       50,
       760,
       740
      ],
      "boxes": [
       {
        "box": {
         "id": "obj-1",
         "maxclass": "codebox",
         "code": "// ECHOLIVITY gen~ CONVOLUTION\n// Uniformly partitioned overlap-save convolution, mono in -> stereo out.\n// Same algorithm as reference/engine.py PartitionedConvolver, but real-time:\n//  - every B samples: IFFT the accumulated spectra (L,R), FFT the newest 2B input frame\n//  - the K partition multiply-accumulates are spread evenly over the B samples\n//    of each block, so CPU per sample is flat apart from the 3 FFTs at the boundary\n//  - latency = 2B samples (B = 512 at <=48 kHz, 1024 at 88.2/96 kHz -> ~21-23 ms),\n//    which behaves like a fixed extra predelay on the IR path (documented)\n// H spectra are written by ir_loader.js into buffer ---echH (2 channels):\n//    sample index (k*(B+1) + bin)*2 + {0 re, 1 im}\n// in1 mono input; out1 L, out2 R\n\nParam nparts(0, min=0, max=400);\nParam bsize(512, min=64, max=1024);\nBuffer H(\"echH_unbound\");\n\nData inb(2048);\nData fdl(820000);\nData acc(2050, 2);\nData outb(1024, 2);\nData re(2048);\nData im(2048);\nData tw(1024, 2);\nHistory cnt(0);\nHistory pos(0);\nHistory twn(0);\nHistory lastK(0);\n\nB = floor(bsize);\nN = 2 * B;\nKp = floor(nparts);\n\n// (re)initialise twiddles and state on block-size or partition-count change\nif (twn != N || lastK != Kp) {\n\tfor (i = 0; i < N / 2; i += 1) {\n\t\tpoke(tw, cos(twopi * i / N), i, 0);\n\t\tpoke(tw, sin(twopi * i / N), i, 1);\n\t}\n\tfor (i = 0; i < 2 * (B + 1); i += 1) {\n\t\tpoke(acc, 0, i, 0);\n\t\tpoke(acc, 0, i, 1);\n\t}\n\tfor (i = 0; i < B; i += 1) {\n\t\tpoke(outb, 0, i, 0);\n\t\tpoke(outb, 0, i, 1);\n\t}\n\tfor (i = 0; i < Kp * (B + 1) * 2; i += 1) {\n\t\tpoke(fdl, 0, i);\n\t}\n\ttwn = N;\n\tlastK = Kp;\n\tcnt = 0;\n\tpos = 0;\n}\n\nc = cnt;\npoke(inb, in1, B + c);\nout1 = peek(outb, c, 0);\nout2 = peek(outb, c, 1);\n\n// spread multiply-accumulate: partitions k0..k1-1 on this sample\nif (Kp > 0) {\n\tk0 = floor(c * Kp / B);\n\tk1 = floor((c + 1) * Kp / B);\n\tfor (k = k0; k < k1; k += 1) {\n\t\tslot = (pos + k) % Kp;\n\t\tfb = slot * (B + 1) * 2;\n\t\thb = k * (B + 1) * 2;\n\t\tfor (b = 0; b <= B; b += 1) {\n\t\t\txr = peek(fdl, fb + 2 * b);\n\t\t\txi = peek(fdl, fb + 2 * b + 1);\n\t\t\thlr = peek(H, hb + 2 * b, 0);\n\t\t\thli = peek(H, hb + 2 * b + 1, 0);\n\t\t\thrr = peek(H, hb + 2 * b, 1);\n\t\t\thri = peek(H, hb + 2 * b + 1, 1);\n\t\t\tpoke(acc, peek(acc, 2 * b, 0) + xr * hlr - xi * hli, 2 * b, 0);\n\t\t\tpoke(acc, peek(acc, 2 * b + 1, 0) + xr * hli + xi * hlr, 2 * b + 1, 0);\n\t\t\tpoke(acc, peek(acc, 2 * b, 1) + xr * hrr - xi * hri, 2 * b, 1);\n\t\t\tpoke(acc, peek(acc, 2 * b + 1, 1) + xr * hri + xi * hrr, 2 * b + 1, 1);\n\t\t}\n\t}\n}\n\n// block boundary: IFFT L, IFFT R, FFT newest input frame\nif (c >= B - 1) {\n\tfor (job = 0; job < 3; job += 1) {\n\t\tsgn = -1;\n\t\tif (job < 2) {\n\t\t\tsgn = 1;\n\t\t\tfor (b = 0; b <= B; b += 1) {\n\t\t\t\tpoke(re, peek(acc, 2 * b, job), b);\n\t\t\t\tpoke(im, peek(acc, 2 * b + 1, job), b);\n\t\t\t\tpoke(acc, 0, 2 * b, job);\n\t\t\t\tpoke(acc, 0, 2 * b + 1, job);\n\t\t\t}\n\t\t\tfor (b = 1; b < B; b += 1) {\n\t\t\t\tpoke(re, peek(re, b), N - b);\n\t\t\t\tpoke(im, -peek(im, b), N - b);\n\t\t\t}\n\t\t} else {\n\t\t\tfor (b = 0; b < N; b += 1) {\n\t\t\t\tpoke(re, peek(inb, b), b);\n\t\t\t\tpoke(im, 0, b);\n\t\t\t}\n\t\t}\n\t\t// in-place radix-2 FFT, sign sgn (-1 forward, +1 inverse)\n\t\tj = 0;\n\t\tfor (i = 0; i < N - 1; i += 1) {\n\t\t\tif (i < j) {\n\t\t\t\ttr = peek(re, i); ti = peek(im, i);\n\t\t\t\tpoke(re, peek(re, j), i); poke(im, peek(im, j), i);\n\t\t\t\tpoke(re, tr, j); poke(im, ti, j);\n\t\t\t}\n\t\t\tm = floor(N / 2);\n\t\t\twhile (m >= 1 && j >= m) {\n\t\t\t\tj -= m;\n\t\t\t\tm = floor(m / 2);\n\t\t\t}\n\t\t\tj += m;\n\t\t}\n\t\tlen = 2;\n\t\twhile (len <= N) {\n\t\t\thalf = floor(len / 2);\n\t\t\ttstep = floor(N / len);\n\t\t\tfor (i = 0; i < N; i += len) {\n\t\t\t\tfor (k = 0; k < half; k += 1) {\n\t\t\t\t\twr = peek(tw, k * tstep, 0);\n\t\t\t\t\twi = sgn * peek(tw, k * tstep, 1);\n\t\t\t\t\tpr = peek(re, i + k + half); pi2 = peek(im, i + k + half);\n\t\t\t\t\tvr = pr * wr - pi2 * wi;\n\t\t\t\t\tvi = pr * wi + pi2 * wr;\n\t\t\t\t\tur = peek(re, i + k); ui = peek(im, i + k);\n\t\t\t\t\tpoke(re, ur + vr, i + k); poke(im, ui + vi, i + k);\n\t\t\t\t\tpoke(re, ur - vr, i + k + half); poke(im, ui - vi, i + k + half);\n\t\t\t\t}\n\t\t\t}\n\t\t\tlen *= 2;\n\t\t}\n\t\tif (job < 2) {\n\t\t\tfor (b = 0; b < B; b += 1) {\n\t\t\t\tpoke(outb, fixdenorm(peek(re, B + b) / N), b, job);\n\t\t\t}\n\t\t} else if (Kp > 0) {\n\t\t\tpos = (pos - 1 + Kp) % Kp;\n\t\t\tbase = pos * (B + 1) * 2;\n\t\t\tfor (b = 0; b <= B; b += 1) {\n\t\t\t\tpoke(fdl, peek(re, b), base + 2 * b);\n\t\t\t\tpoke(fdl, peek(im, b), base + 2 * b + 1);\n\t\t\t}\n\t\t\tfor (b = 0; b < B; b += 1) {\n\t\t\t\tpoke(inb, peek(inb, B + b), b);\n\t\t\t}\n\t\t}\n\t}\n\tcnt = 0;\n} else {\n\tcnt = c + 1;\n}\n",
         "fontface": 0,
         "fontname": "<Monospaced>",
         "fontsize": 11,
         "numinlets": 1,
         "numoutlets": 2,
         "outlettype": [
          "",
          ""
         ],
         "patching_rect": [
          20,
          60,
          700,
          600
         ]
        }
       },
       {
        "box": {
         "id": "obj-2",
         "maxclass": "newobj",
         "text": "in 1",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          20,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-3",
         "maxclass": "newobj",
         "text": "out 1",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          20,
          680,
          45,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-4",
         "maxclass": "newobj",
         "text": "out 2",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          100,
          680,
          45,
          22
         ]
        }
       }
      ],
      "lines": [
       {
        "patchline": {
         "source": [
          "obj-2",
          0
         ],
         "destination": [
          "obj-1",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          0
         ],
         "destination": [
          "obj-3",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          1
         ],
         "destination": [
          "obj-4",
          0
         ]
        }
       }
      ]
     },
     "varname": "ech_conv"
    }
   },
   {
    "box": {
     "id": "obj-4",
     "maxclass": "newobj",
     "numinlets": 5,
     "numoutlets": 4,
     "outlettype": [
      "signal",
      "signal",
      "signal",
      "signal"
     ],
     "patching_rect": [
      40,
      320,
      260,
      22
     ],
     "text": "gen~",
     "patcher": {
      "fileversion": 1,
      "appversion": {
       "major": 8,
       "minor": 6,
       "revision": 0,
       "architecture": "x64",
       "modernui": 1
      },
      "classnamespace": "dsp.gen",
      "rect": [
       50,
       50,
       760,
       740
      ],
      "boxes": [
       {
        "box": {
         "id": "obj-1",
         "maxclass": "codebox",
         "code": "// ECHOLIVITY gen~ BACK\n// Port of reference/engine.py: spring_process(), engine routing,\n// feedback_process(), output_stage().\n// in1 dry L, in2 dry R, in3 engine input e (from FRONT),\n// in4 convolution L, in5 convolution R\n// out1 L, out2 R, out3 dub feedback send (-> tapin~), out4 spring->IR send (-> tapin~)\n\nParam decay(2.0, min=0.3, max=8);\nParam damping(0.8, min=0, max=1);\nParam boing(0.4, min=0, max=1);\nParam tension(0.44, min=0, max=1);\nParam dispersion(0.55, min=0, max=1);\nParam resonance(0.35, min=0, max=1);\nParam movement(0.3, min=0, max=1);\nParam modulation(0.15, min=0, max=1);\nParam engine_mode(2, min=0, max=4);\nParam ir_level(0, min=-24, max=6);\nParam model_level(0, min=-24, max=6);\nParam blend(0.5, min=0, max=1);\nParam feedback(0, min=0, max=1);\nParam fb_tone(0, min=-1, max=1);\nParam fb_drive(0.2, min=0, max=1);\nParam fb_damping(0.3, min=0, max=1);\nParam self_osc(0, min=0, max=1);\nParam tone(0, min=-1, max=1);\nParam width(1, min=0, max=2);\nParam drive(0.25, min=0, max=1);\nParam drywet(0.35, min=0, max=1);   // Live parameter 'Mix' (gen~ reserves the name mix)\nParam output(0, min=-24, max=6);\nParam ir_peak(1, min=0.001, max=100000);   // set by ir_loader.js\nParam have_ir(0, min=0, max=1);            // set by ir_loader.js\n\nDelay sp0(12000);\nDelay sp1(12000);\nData ap(256, 2);          // 64 stages x Kmax 4, per spring\nData st(64);              // misc state, see indices below\n\n// state indices\n// 0,1 delay smooth  2 g smooth  3 hp  4 lp  5 envf  6 envs  7 swx  8 swv  9 slap\n// 10,11 wob  12,13 wob2  14 lfo  15,16 damp  17-20 peak tdf2  21,22 splash\n// 23-26 out dc  27 api  28-38 feedback  39-43,50 output  44 init  45-49 gain smooth  51-56,58,59 tank/recovery  57 osc agc\n\nasym(x, k, b) {\n\ttb = tanh(k * b);\n\ts2 = 1 - tb * tb;\n\treturn (tanh(k * (x + b)) - tb) / (k * s2);\n}\n\nopc(fc) {\n\treturn 1 - exp(-twopi * fc / samplerate);\n}\n\n\nmodelpeak(dec, ten, disp) {\n\tkk = max(1, floor(samplerate / 22050 + 0.5));\n\taa = -(0.45 + 0.35 * disp);\n\tlp = 0.08 - 0.05 * ten;\n\tapd = 64 * kk * (1 - aa) / (1 + aa);\n\ttdl = kk * (1 - aa * aa) / (1 + 2 * aa * cos(kk * twopi * 400 / samplerate) + aa * aa);\n\tle = (max(lp * samplerate - apd, 8) + 64 * tdl) / samplerate;\n\tgg = pow(10, -3 * le / (1.15 * dec));\n\treturn 0.3 * sqrt(1 - gg * gg) * 5.5 / (1 - gg);\n}\n\nmode = floor(engine_mode + 0.5);\nserial = mode >= 3 ? 1 : 0;\n\n// ---------------- parameter smoothing (20 ms) ----------------\nsm = 1 - exp(-1 / (0.02 * samplerate));\nirg_t = pow(10, ir_level / 20);\nmdg_t = pow(10, model_level / 20);\nirg = st.peek(45) + sm * (irg_t - st.peek(45));     st.poke(irg, 45);\nmdg = st.peek(46) + sm * (mdg_t - st.peek(46));     st.poke(mdg, 46);\nbl = st.peek(47) + sm * (blend - st.peek(47));      st.poke(bl, 47);\nmx = st.peek(48) + sm * (drywet - st.peek(48));        st.poke(mx, 48);\ngo_t = pow(10, output / 20);\ngo = st.peek(49) + sm * (go_t - st.peek(49));       st.poke(go, 49);\n\n// ---------------- spring model ----------------\nK = max(1, floor(samplerate / 22050 + 0.5));\ndec = decay * (serial ? 0.3 : 1);\na0 = -(0.45 + 0.35 * dispersion);\n// spring geometry: Fisher K-10 manual, one-way 29 / 37 ms (tension 0.44)\nloop_s = 0.08 - 0.05 * tension;\nratio = 37 / 29;\nap_dc = 64 * K * (1 - a0) / (1 + a0);\n// effective loop time at 400 Hz (the cascade delays lows far more than mids)\ncw = cos(K * twopi * 400 / samplerate);\ntdl_lo = K * (1 - a0 * a0) / (1 + 2 * a0 * cw + a0 * a0);\nloop_eff = (max(loop_s * samplerate - ap_dc, 8) + 64 * tdl_lo) / samplerate;\ng_t = pow(10, -3 * loop_eff / (1.15 * dec));\nfr = 900 + 2100 * tension;\ngdb = 60 * loop_eff * 2 * resonance / dec;\nA = pow(10, gdb / 40);\nw0 = twopi * fr / samplerate;\nalpha = sin(w0) / 3;\na0n = 1 + alpha / A;\nb0 = (1 + alpha * A) / a0n;\nb1 = (-2 * cos(w0)) / a0n;\nb2 = (1 - alpha * A) / a0n;\na1 = (-2 * cos(w0)) / a0n;\na2 = (1 - alpha / A) / a0n;\npnorm = 1 / (A * A);\nc_damp = opc(1500 + 9500 * pow(1 - damping, 2));\nout_scale = sqrt(max(1 - g_t * g_t, 0.0001)) * 5.5;\nr_dc = 1 - twopi * 10 / samplerate;\n\n// spring input: IR>Model feeds the convolution output to the springs\ns_in = mode == 3 ? 0.5 * (in4 + in5) * irg : in3;\n\n// tank feed high-passes, Fisher K-10 values (C1/R3 ~300 Hz, C3/R7 59 Hz)\nhpst = st.peek(3) + opc(300) * (s_in - st.peek(3));\nst.poke(fixdenorm(hpst), 3);\nlpst = st.peek(4) + opc(59) * ((s_in - hpst) - st.peek(4));\nst.poke(fixdenorm(lpst), 4);\nxin = (s_in - hpst) - lpst;\n\n// transient detector -> slap / sway\nax = abs(s_in);\nenvf = st.peek(5) + opc(1 / (twopi * 0.001)) * (ax - st.peek(5));\nenvs = st.peek(6) + opc(1 / (twopi * 0.06)) * (ax - st.peek(6));\nst.poke(fixdenorm(envf), 5);\nst.poke(fixdenorm(envs), 6);\ntr = max(envf - 1.5 * envs, 0);\nhit = min(tr * 8, 1);\nif ((noise() + 1) * 0.5 < movement * 0.4 / samplerate) {\n\thit = max(hit, 0.3 + 0.2 * (noise() + 1));\n}\nslap = max(st.peek(9) * exp(-1 / (0.12 * samplerate)), hit);\nst.poke(fixdenorm(slap), 9);\nw_sw = twopi * 6 / samplerate;\nr_sw = exp(-1 / (0.4 * samplerate));\nsx = st.peek(7);\nsv = st.peek(8);\nnx = r_sw * (cos(w_sw) * sx - sin(w_sw) * sv) + hit * 0.02;\nnv = r_sw * (sin(w_sw) * sx + cos(w_sw) * sv);\nst.poke(fixdenorm(nx), 7);\nst.poke(fixdenorm(nv), 8);\nsway = clamp(nx * 10, -1, 1);\n\nlfo = st.peek(14) + twopi * (0.2 + 0.9 * modulation) / samplerate;\nlfo = lfo > twopi ? lfo - twopi : lfo;\nst.poke(lfo, 14);\n\ng = st.peek(2) + sm * (g_t - st.peek(2));\nst.poke(g, 2);\n\nnz = noise();\nsp_h = st.peek(21) + opc(2500) * (nz - st.peek(21));\nst.poke(fixdenorm(sp_h), 21);\nsp_l = st.peek(22) + opc(6000) * ((nz - sp_h) - st.peek(22));\nst.poke(fixdenorm(sp_l), 22);\nsplash = sp_l * boing * slap * envs * 1.5;\n\nc_wob = opc(0.7);\nw0a = st.peek(10) + c_wob * (noise() - st.peek(10));\nw1a = st.peek(11) + c_wob * (noise() - st.peek(11));\nst.poke(fixdenorm(w0a), 10);\nst.poke(fixdenorm(w1a), 11);\nw0b = st.peek(12) + c_wob * (w0a - st.peek(12));\nw1b = st.peek(13) + c_wob * (w1a - st.peek(13));\nst.poke(fixdenorm(w0b), 12);\nst.poke(fixdenorm(w1b), 13);\n\nmod0 = 1 + 0.006 * movement * w0b * 40 + 0.004 * modulation * sin(lfo) + 0.03 * boing * sway;\nmod1 = 1 + 0.006 * movement * w1b * 40 + 0.004 * modulation * sin(lfo + 0.5 * pi) - 0.024 * boing * sway;\ndt0 = clamp(loop_s * samplerate * mod0 - ap_dc, 8, 11990);\ndt1 = clamp(loop_s * ratio * samplerate * mod1 - ap_dc, 8, 11990);\ninit = st.peek(44);\nd0 = init < 0.5 ? dt0 : st.peek(0) + sm * (dt0 - st.peek(0));\nd1 = init < 0.5 ? dt1 : st.peek(1) + sm * (dt1 - st.peek(1));\nst.poke(d0, 0);\nst.poke(d1, 1);\nst.poke(1, 44);\n\n// read (gen~ read(t) before write == reference read(t-1))\ny0 = sp0.read(d0 + 1, interp=\"cubic\");\ny1 = sp1.read(d1 + 1, interp=\"cubic\");\n// output transducer: one-way = half round trip incl. half the dispersion\ncw1 = cos(K * twopi * 1000 / samplerate);\nap_1k = 64 * K * (1 - a0 * a0) / (1 + 2 * a0 * cw1 + a0 * a0);\no0 = sp0.read(max(1, 0.5 * (d0 - ap_1k)) + 1, interp=\"cubic\");\no1 = sp1.read(max(1, 0.5 * (d1 - ap_1k)) + 1, interp=\"cubic\");\ncth = cos(0.12);\nsth = sin(0.12);\nc0 = cth * y0 + sth * y1;\nc1 = -sth * y0 + cth * y1;\n\na_mod = max(a0 * (1 + 0.04 * movement * w0b * 40), -0.9);\napi = st.peek(27);\nthr = max(1 - 0.7 * boing * slap, 0.25);\n\nv0 = xin + g * c0 + splash;\nv1 = xin + g * c1 + splash;\nfor (i = 0; i < 64; i += 1) {\n\tidx = i * 4 + api;\n\twd0 = ap.peek(idx, 0);\n\twa = v0 - a_mod * wd0;\n\tv0 = a_mod * wa + wd0;\n\tap.poke(fixdenorm(wa), idx, 0);\n\twd1 = ap.peek(idx, 1);\n\twb = v1 - a_mod * wd1;\n\tv1 = a_mod * wb + wd1;\n\tap.poke(fixdenorm(wb), idx, 1);\n}\nst.poke(api + 1 >= K ? 0 : api + 1, 27);\n\ndm0 = st.peek(15) + c_damp * (v0 - st.peek(15));\ndm1 = st.peek(16) + c_damp * (v1 - st.peek(16));\nst.poke(fixdenorm(dm0), 15);\nst.poke(fixdenorm(dm1), 16);\n\nyb0 = b0 * dm0 + st.peek(17);\nst.poke(fixdenorm(b1 * dm0 - a1 * yb0 + st.peek(18)), 17);\nst.poke(fixdenorm(b2 * dm0 - a2 * yb0), 18);\nyb1 = b0 * dm1 + st.peek(19);\nst.poke(fixdenorm(b1 * dm1 - a1 * yb1 + st.peek(20)), 19);\nst.poke(fixdenorm(b2 * dm1 - a2 * yb1), 20);\n\nq0 = thr * tanh(yb0 * pnorm / thr);\nq1 = thr * tanh(yb1 * pnorm / thr);\nsp0.write(fixdenorm(q0));\nsp1.write(fixdenorm(q1));\n\n// output side: tank transducers (fitted to the K-10 IR: HP 200 Hz, 2nd-order LP 8 kHz),\n// then the K-10 recovery amp, which its 680k||12pF feedback makes ~flat (LP 13 kHz)\nc_r1 = opc(200);\nc_r2 = opc(min(8000, 0.45 * samplerate));\nc_r3 = opc(min(13000, 0.45 * samplerate));\nra = st.peek(51) + c_r1 * (o0 - st.peek(51)); st.poke(fixdenorm(ra), 51); o0 = o0 - ra;\nrb = st.peek(52) + c_r2 * (o0 - st.peek(52)); st.poke(fixdenorm(rb), 52); o0 = rb;\nrc = st.peek(53) + c_r2 * (o0 - st.peek(53)); st.poke(fixdenorm(rc), 53); o0 = rc;\nrg = st.peek(58) + c_r3 * (o0 - st.peek(58)); st.poke(fixdenorm(rg), 58); o0 = rg;\nrd = st.peek(54) + c_r1 * (o1 - st.peek(54)); st.poke(fixdenorm(rd), 54); o1 = o1 - rd;\nre2 = st.peek(55) + c_r2 * (o1 - st.peek(55)); st.poke(fixdenorm(re2), 55); o1 = re2;\nrf = st.peek(56) + c_r2 * (o1 - st.peek(56)); st.poke(fixdenorm(rf), 56); o1 = rf;\nrh = st.peek(59) + c_r3 * (o1 - st.peek(59)); st.poke(fixdenorm(rh), 59); o1 = rh;\noo0 = o0 * out_scale;\noo1 = o1 * out_scale;\ndcl = oo0 - st.peek(23) + r_dc * st.peek(24);\nst.poke(oo0, 23);\nst.poke(fixdenorm(dcl), 24);\ndcr = oo1 - st.peek(25) + r_dc * st.peek(26);\nst.poke(oo1, 25);\nst.poke(fixdenorm(dcr), 26);\nsL = dcl * mdg;\nsR = dcr * mdg;\n\n// ---------------- engine routing ----------------\ncL = in4 * irg;\ncR = in5 * irg;\nwL = 0;\nwR = 0;\nif (have_ir < 0.5 && mode != 1) {\n\twL = mode == 0 ? 0 : sL;\n\twR = mode == 0 ? 0 : sR;\n} else if (mode == 0) {\n\twL = cL; wR = cR;\n} else if (mode == 1) {\n\twL = sL; wR = sR;\n} else if (mode == 2) {\n\tgi = cos(0.5 * pi * bl);\n\tgm = sin(0.5 * pi * bl);\n\twL = gi * cL + gm * sL; wR = gi * cR + gm * sR;\n} else if (mode == 3) {\n\twL = (1 - bl) * cL + bl * sL; wR = (1 - bl) * cR + bl * sR;\n} else {\n\twL = (1 - bl) * sL + bl * cL; wR = (1 - bl) * sR + bl * cR;\n}\nout4 = 0.5 * (sL + sR);\n\n// feedback normalisation: 1 / estimated peak gain of the active engine path\npm = modelpeak(decay, tension, dispersion) * mdg;\npms = modelpeak(decay * 0.3, tension, dispersion) * mdg;\npir = ir_peak * irg;\npk = pm;\nif (have_ir < 0.5) {\n\tpk = mode == 0 ? 1 : pm;\n} else if (mode == 0) {\n\tpk = pir;\n} else if (mode == 2) {\n\tpk = sqrt(pow(cos(0.5 * pi * bl) * pir, 2) + pow(sin(0.5 * pi * bl) * pm, 2));\n} else if (mode == 3) {\n\tpk = sqrt(pow((1 - bl) * pir, 2) + pow(bl * pir * sqrt(pms), 2));\n} else if (mode == 4) {\n\tpk = sqrt(pow((1 - bl) * pms, 2) + pow(bl * pir * pow(0.5 + pms, 0.75), 2));\n}\nfbnorm = 1 / max(pk, 0.05);\n\n// ---------------- dub feedback loop ----------------\nf = 0.5 * (wL + wR);\nc_hp = opc(150 * pow(2, fb_tone * 1.6));\nc_lp = opc(min(3000 * pow(2, fb_tone * 1.6), 0.45 * samplerate));\nc_dm = opc(min(16000 * pow(1 - fb_damping, 2) + 800, 0.45 * samplerate));\nh1 = st.peek(28) + c_hp * (f - st.peek(28)); st.poke(fixdenorm(h1), 28); f = f - h1;\nh2 = st.peek(29) + c_hp * (f - st.peek(29)); st.poke(fixdenorm(h2), 29); f = f - h2;\nl1 = st.peek(30) + c_lp * (f - st.peek(30)); st.poke(fixdenorm(l1), 30); f = l1;\nl2 = st.peek(31) + c_lp * (f - st.peek(31)); st.poke(fixdenorm(l2), 31); f = l2;\nl3 = st.peek(32) + c_dm * (f - st.peek(32)); st.poke(fixdenorm(l3), 32); f = l3;\nf = asym(f, 1 + 14 * fb_drive, 0.1 * fb_drive);\ngrms = st.peek(34) + opc(1 / (twopi * 0.5)) * (f * f - st.peek(34));\nst.poke(fixdenorm(grms), 34);\ngs = 1 - self_osc;\nguard = st.peek(35);\nguard = st.peek(36) < 0.5 ? 1 : guard;      // first sample init\nst.poke(1, 36);\ngthr = self_osc > 0 ? max(0.01, 4 * pow(10, (-30 + 16 * self_osc) / 10)) : 0.01;\nif (gs > 0 && grms > gthr) {\n\tguard = max(guard - gs / samplerate, 0.4);\n} else {\n\tguard = min(guard + 0.5 / samplerate, 1);\n}\nst.poke(guard, 35);\n// self-oscillation AGC (state 57): reaches the Self-Osc target level on any engine\nog = st.peek(57);\nog = og < 1 ? 1 : og;\nosc_t = pow(10, (-30 + 16 * self_osc) / 10);\nlvl = st.peek(33) * st.peek(33) * 0.5;      // fast peak envelope -> power\nif (self_osc > 0) {\n\tif (lvl < 0.5 * osc_t) {\n\t\tog = min(og * pow(10, 2 / 20 / samplerate), 16);\n\t} else if (lvl > 2 * osc_t) {\n\t\tog = max(og * pow(10, -12 / 20 / samplerate), 1);\n\t}\n} else {\n\tog = max(og * pow(10, -12 / 20 / samplerate), 1);\n}\nst.poke(og, 57);\nf = f * (0.98 * feedback + 0.6 * self_osc) * fbnorm * guard * (1 + (og - 1) * self_osc);\nfenv = max(abs(f), st.peek(33) * exp(-1 / (0.15 * samplerate)));\nst.poke(fixdenorm(fenv), 33);\nf = fenv > 0.5 ? f * 0.5 / fenv : f;\nfdc = f - st.peek(37) + r_dc * st.peek(38);\nst.poke(f, 37);\nst.poke(fixdenorm(fdc), 38);\nout3 = fdc;\n\n// ---------------- output section ----------------\nc_t = opc(900);\ngl = pow(10, -6 * tone / 40);\ngh = pow(10, 6 * tone / 40);\ntl = st.peek(39) + c_t * (wL - st.peek(39)); st.poke(fixdenorm(tl), 39);\ntrr = st.peek(40) + c_t * (wR - st.peek(40)); st.poke(fixdenorm(trr), 40);\nl = tl * gl + (wL - tl) * gh;\nr = trr * gl + (wR - trr) * gh;\nm = 0.5 * (l + r);\ns = 0.5 * (l - r) * width;\nl = asym(m + s, 1 + 2 * drive, 0.1);\nr = asym(m - s, 1 + 2 * drive, 0.1);\nodl = l - st.peek(41) + r_dc * st.peek(42); st.poke(l, 41); st.poke(fixdenorm(odl), 42);\nodr = r - st.peek(43) + r_dc * st.peek(50); st.poke(r, 43); st.poke(fixdenorm(odr), 50);\ngw = sin(0.5 * pi * mx);\ngd = cos(0.5 * pi * mx);\nout1 = (gd * in1 + gw * odl) * go;\nout2 = (gd * in2 + gw * odr) * go;\n",
         "fontface": 0,
         "fontname": "<Monospaced>",
         "fontsize": 11,
         "numinlets": 5,
         "numoutlets": 4,
         "outlettype": [
          "",
          "",
          "",
          ""
         ],
         "patching_rect": [
          20,
          60,
          700,
          600
         ]
        }
       },
       {
        "box": {
         "id": "obj-2",
         "maxclass": "newobj",
         "text": "in 1",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          20,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-3",
         "maxclass": "newobj",
         "text": "in 2",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          100,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-4",
         "maxclass": "newobj",
         "text": "in 3",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          180,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-5",
         "maxclass": "newobj",
         "text": "in 4",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          260,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-6",
         "maxclass": "newobj",
         "text": "in 5",
         "numinlets": 0,
         "numoutlets": 1,
         "outlettype": [
          ""
         ],
         "patching_rect": [
          340,
          20,
          40,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-7",
         "maxclass": "newobj",
         "text": "out 1",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          20,
          680,
          45,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-8",
         "maxclass": "newobj",
         "text": "out 2",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          100,
          680,
          45,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-9",
         "maxclass": "newobj",
         "text": "out 3",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          180,
          680,
          45,
          22
         ]
        }
       },
       {
        "box": {
         "id": "obj-10",
         "maxclass": "newobj",
         "text": "out 4",
         "numinlets": 1,
         "numoutlets": 0,
         "patching_rect": [
          260,
          680,
          45,
          22
         ]
        }
       }
      ],
      "lines": [
       {
        "patchline": {
         "source": [
          "obj-2",
          0
         ],
         "destination": [
          "obj-1",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-3",
          0
         ],
         "destination": [
          "obj-1",
          1
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-4",
          0
         ],
         "destination": [
          "obj-1",
          2
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-5",
          0
         ],
         "destination": [
          "obj-1",
          3
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-6",
          0
         ],
         "destination": [
          "obj-1",
          4
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          0
         ],
         "destination": [
          "obj-7",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          1
         ],
         "destination": [
          "obj-8",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          2
         ],
         "destination": [
          "obj-9",
          0
         ]
        }
       },
       {
        "patchline": {
         "source": [
          "obj-1",
          3
         ],
         "destination": [
          "obj-10",
          0
         ]
        }
       }
      ]
     },
     "varname": "ech_back"
    }
   },
   {
    "box": {
     "id": "obj-5",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      40,
      420,
      80,
      22
     ],
     "text": "plugout~"
    }
   },
   {
    "box": {
     "id": "obj-6",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "tapconnect"
     ],
     "patching_rect": [
      340,
      380,
      70,
      22
     ],
     "text": "tapin~ 100"
    }
   },
   {
    "box": {
     "id": "obj-7",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      340,
      410,
      70,
      22
     ],
     "text": "tapout~ 0"
    }
   },
   {
    "box": {
     "id": "obj-8",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "tapconnect"
     ],
     "patching_rect": [
      440,
      380,
      70,
      22
     ],
     "text": "tapin~ 100"
    }
   },
   {
    "box": {
     "id": "obj-9",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      440,
      410,
      70,
      22
     ],
     "text": "tapout~ 0"
    }
   },
   {
    "box": {
     "id": "obj-10",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "bang"
     ],
     "patching_rect": [
      600,
      160,
      110,
      22
     ],
     "text": "buffer~ ---echIR"
    }
   },
   {
    "box": {
     "id": "obj-11",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "bang"
     ],
     "patching_rect": [
      600,
      300,
      120,
      22
     ],
     "text": "buffer~ ---echH 1 2"
    }
   },
   {
    "box": {
     "id": "obj-12",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      600,
      240,
      220,
      22
     ],
     "text": "js ech_ir_loader.js ---echIR ---echH"
    }
   },
   {
    "box": {
     "id": "obj-13",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 4,
     "outlettype": [
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      600,
      100,
      80,
      22
     ],
     "text": "js ech_ui.js"
    }
   },
   {
    "box": {
     "id": "obj-14",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 10,
     "outlettype": [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      760,
      190,
      90,
      22
     ],
     "text": "info~ ---echIR"
    }
   },
   {
    "box": {
     "id": "obj-15",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      600,
      190,
      40,
      22
     ],
     "text": "t b b"
    }
   },
   {
    "box": {
     "id": "obj-16",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      600,
      215,
      40,
      22
     ],
     "text": "load"
    }
   },
   {
    "box": {
     "id": "obj-17",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      760,
      215,
      80,
      22
     ],
     "text": "prepend irsr"
    }
   },
   {
    "box": {
     "id": "obj-18",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 5,
     "outlettype": [
      "",
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      600,
      270,
      220,
      22
     ],
     "text": "route bsize nparts ir_peak have_ir"
    }
   },
   {
    "box": {
     "id": "obj-19",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      600,
      340,
      80,
      22
     ],
     "text": "prepend bsize"
    }
   },
   {
    "box": {
     "id": "obj-20",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      690,
      340,
      90,
      22
     ],
     "text": "prepend nparts"
    }
   },
   {
    "box": {
     "id": "obj-21",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      790,
      340,
      90,
      22
     ],
     "text": "prepend ir_peak"
    }
   },
   {
    "box": {
     "id": "obj-22",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      890,
      340,
      90,
      22
     ],
     "text": "prepend have_ir"
    }
   },
   {
    "box": {
     "id": "obj-23",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "bang",
      "int",
      "int"
     ],
     "patching_rect": [
      900,
      40,
      100,
      22
     ],
     "text": "live.thisdevice"
    }
   },
   {
    "box": {
     "id": "obj-24",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      900,
      80,
      80,
      22
     ],
     "text": "H ---echH"
    }
   },
   {
    "box": {
     "id": "obj-25",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 4,
     "outlettype": [
      "int",
      "float",
      "int",
      "int"
     ],
     "patching_rect": [
      1000,
      80,
      70,
      22
     ],
     "text": "dspstate~"
    }
   },
   {
    "box": {
     "id": "obj-26",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1000,
      110,
      70,
      22
     ],
     "text": "prepend sr"
    }
   },
   {
    "box": {
     "id": "obj-27",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 3,
     "outlettype": [
      "",
      "",
      ""
     ],
     "patching_rect": [
      900,
      130,
      160,
      22
     ],
     "text": "pattr userpath"
    }
   },
   {
    "box": {
     "id": "obj-28",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      900,
      160,
      260,
      22
     ],
     "text": "pattrstorage echstore @savemode 0 @autorestore 0",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "echstore",
       "parameter_shortname": "echstore",
       "parameter_type": 3,
       "parameter_invisible": 1,
       "parameter_modmode": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-29",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      900,
      190,
      100,
      22
     ],
     "text": "prepend restore"
    }
   },
   {
    "box": {
     "id": "obj-30",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1000,
      250,
      80,
      22
     ],
     "text": "prepend user"
    }
   },
   {
    "box": {
     "id": "obj-31",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      80,
      150,
      18
     ],
     "text": "CORE",
     "presentation": 1,
     "presentation_rect": [
      8,
      2,
      120,
      16
     ],
     "fontsize": 10,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-32",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      700,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      8,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Drive",
       "parameter_shortname": "Drive",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.25
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Drive",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-33",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      150,
      960,
      100,
      22
     ],
     "text": "prepend drive"
    }
   },
   {
    "box": {
     "id": "obj-34",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      820,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      60,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Decay",
       "parameter_shortname": "Decay",
       "parameter_type": 0,
       "parameter_mmin": 0.3,
       "parameter_mmax": 8.0,
       "parameter_initial": [
        2.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 9,
       "parameter_units": "%.2f s",
       "parameter_exponent": 2.0,
       "parameter_modmode": 0
      }
     },
     "varname": "Decay",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-35",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      260,
      960,
      100,
      22
     ],
     "text": "prepend decay"
    }
   },
   {
    "box": {
     "id": "obj-36",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      260,
      990,
      100,
      22
     ],
     "text": "prepend decay"
    }
   },
   {
    "box": {
     "id": "obj-37",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      1000,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      112,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Tone",
       "parameter_shortname": "Tone",
       "parameter_type": 0,
       "parameter_mmin": -1.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Tone",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-38",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      370,
      960,
      100,
      22
     ],
     "text": "prepend tone"
    }
   },
   {
    "box": {
     "id": "obj-39",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      1120,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      8,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Damping",
       "parameter_shortname": "Damping",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.8
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Damping",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-40",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      480,
      960,
      100,
      22
     ],
     "text": "prepend damping"
    }
   },
   {
    "box": {
     "id": "obj-41",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      480,
      990,
      100,
      22
     ],
     "text": "prepend damping"
    }
   },
   {
    "box": {
     "id": "obj-42",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      100,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      60,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Mix",
       "parameter_shortname": "Mix",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.35
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Mix",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-43",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      590,
      960,
      100,
      22
     ],
     "text": "prepend drywet"
    }
   },
   {
    "box": {
     "id": "obj-44",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      220,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      112,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Output",
       "parameter_shortname": "Output",
       "parameter_type": 0,
       "parameter_mmin": -24.0,
       "parameter_mmax": 6.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 4,
       "parameter_modmode": 0
      }
     },
     "varname": "Output",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-45",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      700,
      960,
      100,
      22
     ],
     "text": "prepend output"
    }
   },
   {
    "box": {
     "id": "obj-46",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      410,
      150,
      18
     ],
     "text": "SPRING",
     "presentation": 1,
     "presentation_rect": [
      178,
      2,
      120,
      16
     ],
     "fontsize": 10,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-47",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      400,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      178,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Boing",
       "parameter_shortname": "Boing",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.4
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Boing",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-48",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      810,
      960,
      100,
      22
     ],
     "text": "prepend boing"
    }
   },
   {
    "box": {
     "id": "obj-49",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      520,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      230,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Tension",
       "parameter_shortname": "Tension",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.44
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Tension",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-50",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      920,
      960,
      100,
      22
     ],
     "text": "prepend tension"
    }
   },
   {
    "box": {
     "id": "obj-51",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      640,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      282,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Dispersion",
       "parameter_shortname": "Dispers.",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.55
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Dispersion",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-52",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1030,
      960,
      100,
      22
     ],
     "text": "prepend dispersion"
    }
   },
   {
    "box": {
     "id": "obj-53",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      760,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      178,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Resonance",
       "parameter_shortname": "Reson.",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.35
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Resonance",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-54",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1140,
      960,
      100,
      22
     ],
     "text": "prepend resonance"
    }
   },
   {
    "box": {
     "id": "obj-55",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      880,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      230,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Movement",
       "parameter_shortname": "Movement",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.3
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Movement",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-56",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1250,
      960,
      100,
      22
     ],
     "text": "prepend movement"
    }
   },
   {
    "box": {
     "id": "obj-57",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      52,
      150,
      18
     ],
     "text": "HYBRID",
     "presentation": 1,
     "presentation_rect": [
      348,
      2,
      120,
      16
     ],
     "fontsize": 10,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-58",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      1060,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      348,
      40,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "IR Level",
       "parameter_shortname": "IR",
       "parameter_type": 0,
       "parameter_mmin": -24.0,
       "parameter_mmax": 6.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 4,
       "parameter_modmode": 0
      }
     },
     "varname": "IR Level",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-59",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1360,
      960,
      100,
      22
     ],
     "text": "prepend ir_level"
    }
   },
   {
    "box": {
     "id": "obj-60",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      1180,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      400,
      40,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Model Level",
       "parameter_shortname": "Model",
       "parameter_type": 0,
       "parameter_mmin": -24.0,
       "parameter_mmax": 6.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 4,
       "parameter_modmode": 0
      }
     },
     "varname": "Model Level",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-61",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1470,
      960,
      100,
      22
     ],
     "text": "prepend model_level"
    }
   },
   {
    "box": {
     "id": "obj-62",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      100,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      348,
      90,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Hybrid Blend",
       "parameter_shortname": "Blend",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.5
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Hybrid Blend",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-63",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1580,
      960,
      100,
      22
     ],
     "text": "prepend blend"
    }
   },
   {
    "box": {
     "id": "obj-64",
     "maxclass": "live.menu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "",
      "",
      "float"
     ],
     "patching_rect": [
      300,
      900,
      100,
      18
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      348,
      18,
      144,
      18
     ],
     "varname": "Engine Mode",
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Engine Mode",
       "parameter_shortname": "Engine",
       "parameter_type": 2,
       "parameter_enum": [
        "IR",
        "Model",
        "Parallel",
        "IR>Model",
        "Model>IR"
       ],
       "parameter_mmax": 4,
       "parameter_initial": [
        2
       ],
       "parameter_initial_enable": 1,
       "parameter_modmode": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-65",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      300,
      930,
      120,
      22
     ],
     "text": "prepend engine_mode"
    }
   },
   {
    "box": {
     "id": "obj-66",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      250,
      150,
      18
     ],
     "text": "DUB",
     "presentation": 1,
     "presentation_rect": [
      510,
      2,
      120,
      16
     ],
     "fontsize": 10,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-67",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      400,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      510,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Feedback",
       "parameter_shortname": "Feedback",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Feedback",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-68",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1800,
      960,
      100,
      22
     ],
     "text": "prepend feedback"
    }
   },
   {
    "box": {
     "id": "obj-69",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      520,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      562,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FB Tone",
       "parameter_shortname": "FB Tone",
       "parameter_type": 0,
       "parameter_mmin": -1.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "FB Tone",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-70",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1910,
      960,
      100,
      22
     ],
     "text": "prepend fb_tone"
    }
   },
   {
    "box": {
     "id": "obj-71",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      640,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      614,
      18,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FB Drive",
       "parameter_shortname": "FB Drive",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.2
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "FB Drive",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-72",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2020,
      960,
      100,
      22
     ],
     "text": "prepend fb_drive"
    }
   },
   {
    "box": {
     "id": "obj-73",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      760,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      510,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FB Damping",
       "parameter_shortname": "FB Damp",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.3
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "FB Damping",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-74",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2130,
      960,
      100,
      22
     ],
     "text": "prepend fb_damping"
    }
   },
   {
    "box": {
     "id": "obj-75",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      880,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      562,
      68,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Self-Osc",
       "parameter_shortname": "Self-Osc",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Self-Osc",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-76",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2240,
      960,
      100,
      22
     ],
     "text": "prepend self_osc"
    }
   },
   {
    "box": {
     "id": "obj-77",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      492,
      150,
      18
     ],
     "text": "ADVANCED",
     "presentation": 1,
     "presentation_rect": [
      680,
      2,
      120,
      16
     ],
     "fontsize": 10,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-78",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      1060,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      680,
      62,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Pre-delay",
       "parameter_shortname": "Pre-dly",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 250.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 2,
       "parameter_exponent": 2.0,
       "parameter_modmode": 0
      }
     },
     "varname": "Pre-delay",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-79",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2350,
      960,
      100,
      22
     ],
     "text": "prepend predelay"
    }
   },
   {
    "box": {
     "id": "obj-80",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      1180,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      732,
      62,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Width",
       "parameter_shortname": "Width",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 2.0,
       "parameter_initial": [
        1.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Width",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-81",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2460,
      960,
      100,
      22
     ],
     "text": "prepend width"
    }
   },
   {
    "box": {
     "id": "obj-82",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      100,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      784,
      62,
      44,
      46
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Modulation",
       "parameter_shortname": "Mod",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 1.0,
       "parameter_initial": [
        0.15
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 1,
       "parameter_modmode": 0
      }
     },
     "varname": "Modulation",
     "showname": 1,
     "shownumber": 1
    }
   },
   {
    "box": {
     "id": "obj-83",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2570,
      960,
      100,
      22
     ],
     "text": "prepend modulation"
    }
   },
   {
    "box": {
     "id": "obj-84",
     "maxclass": "live.menu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "",
      "",
      "float"
     ],
     "patching_rect": [
      500,
      900,
      140,
      18
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      680,
      18,
      216,
      18
     ],
     "varname": "IR",
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "IR",
       "parameter_shortname": "IR",
       "parameter_type": 2,
       "parameter_enum": [
        "TP_FISHER_K10_derickgtwk_STEREO_96k",
        "TP_BF_BirdVerb_FenderDeluxe_ST_44k",
        "TP_BF_BirdVerb_Supro_ST_44k",
        "TP_BF_FenderDeluxe_MONO_44k",
        "TP_BF_Supro_MONO_44k",
        "TP_MT_70sStereoSpring_01",
        "TP_MT_SilverFace_Spring_01",
        "TP_MT_Spring_Webcor",
        "SYN_DarkTank2S_C",
        "SYN_K10Spec_2S",
        "SYN_LongTank2S_A",
        "SYN_ShortTank3S_B",
        "SYN_SplashTank1S_D",
        "User IR"
       ],
       "parameter_mmax": 13,
       "parameter_initial": [
        0
       ],
       "parameter_initial_enable": 1,
       "parameter_modmode": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-85",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      500,
      930,
      80,
      22
     ],
     "text": "prepend lib"
    }
   },
   {
    "box": {
     "id": "obj-86",
     "maxclass": "live.drop",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      650,
      900,
      140,
      20
     ],
     "presentation": 1,
     "presentation_rect": [
      680,
      38,
      216,
      20
     ],
     "parameter_enable": 0
    }
   },
   {
    "box": {
     "id": "obj-87",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      600,
      380,
      300,
      18
     ],
     "text": "no IR loaded",
     "presentation": 1,
     "presentation_rect": [
      8,
      150,
      420,
      16
     ],
     "fontsize": 9
    }
   },
   {
    "box": {
     "id": "obj-88",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      134,
      150,
      18
     ],
     "text": "PRESET",
     "presentation": 1,
     "presentation_rect": [
      440,
      150,
      50,
      16
     ],
     "fontsize": 9,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-89",
     "maxclass": "umenu",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "int",
      "",
      ""
     ],
     "patching_rect": [
      40,
      1100,
      200,
      20
     ],
     "presentation": 1,
     "presentation_rect": [
      490,
      148,
      220,
      18
     ],
     "items": [
      "01 Fisher Reference",
      "02 Vintage Splash",
      "03 Deep Dub Spring",
      "04 Metallic Resonance",
      "05 Heavy Pressure",
      "06 Dark Chamber",
      "07 Infinite Dub",
      "08 Broken Spring",
      "09 Short Percussion Spring",
      "10 Experimental Mechanical"
     ]
    }
   },
   {
    "box": {
     "id": "obj-90",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 11,
     "outlettype": [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      40,
      1130,
      300,
      22
     ],
     "text": "sel 0 1 2 3 4 5 6 7 8 9"
    }
   },
   {
    "box": {
     "id": "obj-91",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 25,
     "outlettype": [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
     ],
     "patching_rect": [
      40,
      1220,
      900,
      22
     ],
     "text": "route drive decay tone damping mix output boing tension dispersion resonance movement ir_level model_level blend engine_mode feedback fb_tone fb_drive fb_damping self_osc predelay width modulation ir"
    }
   },
   {
    "box": {
     "id": "obj-92",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      40,
      1160,
      200,
      22
     ],
     "text": "drive 0.15, decay 8.0, tone 0.0, damping 0.0, mix 1.0, output -2.0, boing 0.4, tension 0.44, dispersion 0.55, resonance 0.35, movement 0.3, ir_level 0.0, model_level 0.0, blend 0.5, engine_mode 0, feedback 0.0, fb_tone 0.0, fb_drive 0.2, fb_damping 0.3, self_osc 0.0, predelay 0, width 1.0, modulation 0.15, ir 0"
    }
   },
   {
    "box": {
     "id": "obj-93",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      60,
      1162,
      200,
      22
     ],
     "text": "drive 0.35, decay 2.2, tone 0.35, damping 0.15, mix 0.4, output -3.0, boing 0.8, tension 0.55, dispersion 0.7, resonance 0.3, movement 0.25, ir_level 0.0, model_level 0.0, blend 0.45, engine_mode 2, feedback 0.0, fb_tone 0.0, fb_drive 0.2, fb_damping 0.3, self_osc 0.0, predelay 0.0, width 1.0, modulation 0.15, ir 3"
    }
   },
   {
    "box": {
     "id": "obj-94",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      80,
      1164,
      200,
      22
     ],
     "text": "drive 0.3, decay 3.5, tone -0.25, damping 0.45, mix 1.0, output -6.0, boing 0.55, tension 0.35, dispersion 0.6, resonance 0.4, movement 0.3, ir_level 0.0, model_level 0.0, blend 0.4, engine_mode 2, feedback 0.45, fb_tone -0.2, fb_drive 0.3, fb_damping 0.4, self_osc 0.0, predelay 12, width 1.0, modulation 0.15, ir 0"
    }
   },
   {
    "box": {
     "id": "obj-95",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      100,
      1166,
      200,
      22
     ],
     "text": "drive 0.2, decay 4.5, tone 0.2, damping 0.1, mix 0.4, output 0.0, boing 0.3, tension 0.7, dispersion 0.9, resonance 0.95, movement 0.15, ir_level 0.0, model_level 0.0, blend 0.5, engine_mode 1, feedback 0.0, fb_tone 0.0, fb_drive 0.2, fb_damping 0.3, self_osc 0.0, predelay 0.0, width 1.0, modulation 0.1, ir 11"
    }
   },
   {
    "box": {
     "id": "obj-96",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      120,
      1168,
      200,
      22
     ],
     "text": "drive 0.85, decay 2.8, tone -0.1, damping 0.5, mix 0.45, output -4.0, boing 0.5, tension 0.4, dispersion 0.5, resonance 0.5, movement 0.35, ir_level 0.0, model_level 0.0, blend 0.6, engine_mode 4, feedback 0.6, fb_tone -0.3, fb_drive 0.8, fb_damping 0.35, self_osc 0.0, predelay 0.0, width 1.0, modulation 0.15, ir 8"
    }
   },
   {
    "box": {
     "id": "obj-97",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      140,
      1170,
      200,
      22
     ],
     "text": "drive 0.1, decay 3.0, tone -0.55, damping 0.75, mix 0.35, output -4.0, boing 0.1, tension 0.25, dispersion 0.4, resonance 0.15, movement 0.1, ir_level 0.0, model_level 0.0, blend 0.3, engine_mode 2, feedback 0.0, fb_tone 0.0, fb_drive 0.2, fb_damping 0.3, self_osc 0.0, predelay 25, width 1.3, modulation 0.25, ir 8"
    }
   },
   {
    "box": {
     "id": "obj-98",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      160,
      1172,
      200,
      22
     ],
     "text": "drive 0.3, decay 6.0, tone -0.1, damping 0.35, mix 1.0, output -6.0, boing 0.45, tension 0.45, dispersion 0.6, resonance 0.45, movement 0.3, ir_level 0.0, model_level 0.0, blend 0.5, engine_mode 2, feedback 1.0, fb_tone 0.0, fb_drive 0.45, fb_damping 0.5, self_osc 0.35, predelay 0.0, width 1.0, modulation 0.15, ir 0"
    }
   },
   {
    "box": {
     "id": "obj-99",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      180,
      1174,
      200,
      22
     ],
     "text": "drive 0.55, decay 2.0, tone 0.1, damping 0.3, mix 0.5, output -5.0, boing 1.0, tension 0.3, dispersion 0.8, resonance 0.6, movement 1.0, ir_level 0.0, model_level 0.0, blend 0.75, engine_mode 3, feedback 0.3, fb_tone 0.0, fb_drive 0.5, fb_damping 0.3, self_osc 0.0, predelay 0.0, width 1.0, modulation 0.4, ir 12"
    }
   },
   {
    "box": {
     "id": "obj-100",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      200,
      1176,
      200,
      22
     ],
     "text": "drive 0.15, decay 0.7, tone 0.3, damping 0.25, mix 0.3, output 0.0, boing 0.35, tension 0.85, dispersion 0.45, resonance 0.25, movement 0.15, ir_level 0.0, model_level 0.0, blend 0.35, engine_mode 2, feedback 0.0, fb_tone 0.0, fb_drive 0.2, fb_damping 0.3, self_osc 0.0, predelay 0.0, width 1.4, modulation 0.15, ir 5"
    }
   },
   {
    "box": {
     "id": "obj-101",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      220,
      1178,
      200,
      22
     ],
     "text": "drive 0.6, decay 5.0, tone 0.0, damping 0.2, mix 0.5, output -6.0, boing 0.7, tension 0.15, dispersion 1.0, resonance 0.8, movement 0.6, ir_level 0.0, model_level 0.0, blend 0.5, engine_mode 4, feedback 0.75, fb_tone 0.4, fb_drive 0.7, fb_damping 0.2, self_osc 0.15, predelay 0.0, width 1.6, modulation 0.8, ir 8"
    }
   },
   {
    "box": {
     "id": "obj-102",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      442,
      150,
      18
     ],
     "text": "ECHOLIVITY  Fisher Spring Hybrid",
     "presentation": 1,
     "presentation_rect": [
      730,
      148,
      260,
      18
     ],
     "fontsize": 11,
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-103",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      900,
      60,
      40,
      22
     ],
     "text": "t b b"
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "source": [
      "obj-1",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-1",
      1
     ],
     "destination": [
      "obj-2",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-1",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-1",
      1
     ],
     "destination": [
      "obj-4",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-2",
      0
     ],
     "destination": [
      "obj-4",
      2
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-2",
      1
     ],
     "destination": [
      "obj-3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-3",
      0
     ],
     "destination": [
      "obj-4",
      3
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-3",
      1
     ],
     "destination": [
      "obj-4",
      4
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-4",
      0
     ],
     "destination": [
      "obj-5",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-4",
      1
     ],
     "destination": [
      "obj-5",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-4",
      2
     ],
     "destination": [
      "obj-6",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-6",
      0
     ],
     "destination": [
      "obj-7",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-7",
      0
     ],
     "destination": [
      "obj-2",
      2
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-4",
      3
     ],
     "destination": [
      "obj-8",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-8",
      0
     ],
     "destination": [
      "obj-9",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-9",
      0
     ],
     "destination": [
      "obj-2",
      3
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-13",
      0
     ],
     "destination": [
      "obj-10",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-10",
      1
     ],
     "destination": [
      "obj-15",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-15",
      1
     ],
     "destination": [
      "obj-14",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-15",
      0
     ],
     "destination": [
      "obj-16",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-14",
      0
     ],
     "destination": [
      "obj-17",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-17",
      0
     ],
     "destination": [
      "obj-12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-16",
      0
     ],
     "destination": [
      "obj-12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-12",
      0
     ],
     "destination": [
      "obj-18",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-18",
      0
     ],
     "destination": [
      "obj-19",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-18",
      1
     ],
     "destination": [
      "obj-20",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-18",
      2
     ],
     "destination": [
      "obj-21",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-18",
      3
     ],
     "destination": [
      "obj-22",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-19",
      0
     ],
     "destination": [
      "obj-3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-20",
      0
     ],
     "destination": [
      "obj-3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-21",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-22",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-23",
      0
     ],
     "destination": [
      "obj-24",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-24",
      0
     ],
     "destination": [
      "obj-3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-23",
      0
     ],
     "destination": [
      "obj-25",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-25",
      1
     ],
     "destination": [
      "obj-26",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-26",
      0
     ],
     "destination": [
      "obj-12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-13",
      3
     ],
     "destination": [
      "obj-27",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-27",
      0
     ],
     "destination": [
      "obj-29",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-29",
      0
     ],
     "destination": [
      "obj-13",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-32",
      0
     ],
     "destination": [
      "obj-33",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-33",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-33",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-34",
      0
     ],
     "destination": [
      "obj-35",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-35",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-34",
      0
     ],
     "destination": [
      "obj-36",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-36",
      0
     ],
     "destination": [
      "obj-12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-37",
      0
     ],
     "destination": [
      "obj-38",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-38",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-39",
      0
     ],
     "destination": [
      "obj-40",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-40",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-39",
      0
     ],
     "destination": [
      "obj-41",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-41",
      0
     ],
     "destination": [
      "obj-12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-42",
      0
     ],
     "destination": [
      "obj-43",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-43",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-44",
      0
     ],
     "destination": [
      "obj-45",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-45",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-47",
      0
     ],
     "destination": [
      "obj-48",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-48",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-49",
      0
     ],
     "destination": [
      "obj-50",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-50",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-51",
      0
     ],
     "destination": [
      "obj-52",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-52",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-53",
      0
     ],
     "destination": [
      "obj-54",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-54",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-55",
      0
     ],
     "destination": [
      "obj-56",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-56",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-58",
      0
     ],
     "destination": [
      "obj-59",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-59",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-60",
      0
     ],
     "destination": [
      "obj-61",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-61",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-62",
      0
     ],
     "destination": [
      "obj-63",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-63",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-64",
      0
     ],
     "destination": [
      "obj-65",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-65",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-65",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-67",
      0
     ],
     "destination": [
      "obj-68",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-68",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-69",
      0
     ],
     "destination": [
      "obj-70",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-70",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-71",
      0
     ],
     "destination": [
      "obj-72",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-72",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-73",
      0
     ],
     "destination": [
      "obj-74",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-74",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-75",
      0
     ],
     "destination": [
      "obj-76",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-76",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-78",
      0
     ],
     "destination": [
      "obj-79",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-79",
      0
     ],
     "destination": [
      "obj-2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-80",
      0
     ],
     "destination": [
      "obj-81",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-81",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-82",
      0
     ],
     "destination": [
      "obj-83",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-83",
      0
     ],
     "destination": [
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-84",
      0
     ],
     "destination": [
      "obj-85",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-85",
      0
     ],
     "destination": [
      "obj-13",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-13",
      1
     ],
     "destination": [
      "obj-84",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-86",
      0
     ],
     "destination": [
      "obj-30",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-30",
      0
     ],
     "destination": [
      "obj-13",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-12",
      1
     ],
     "destination": [
      "obj-87",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-13",
      2
     ],
     "destination": [
      "obj-87",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-89",
      0
     ],
     "destination": [
      "obj-90",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      0
     ],
     "destination": [
      "obj-32",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      1
     ],
     "destination": [
      "obj-34",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      2
     ],
     "destination": [
      "obj-37",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      3
     ],
     "destination": [
      "obj-39",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      4
     ],
     "destination": [
      "obj-42",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      5
     ],
     "destination": [
      "obj-44",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      6
     ],
     "destination": [
      "obj-47",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      7
     ],
     "destination": [
      "obj-49",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      8
     ],
     "destination": [
      "obj-51",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      9
     ],
     "destination": [
      "obj-53",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      10
     ],
     "destination": [
      "obj-55",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      11
     ],
     "destination": [
      "obj-58",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      12
     ],
     "destination": [
      "obj-60",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      13
     ],
     "destination": [
      "obj-62",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      14
     ],
     "destination": [
      "obj-64",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      15
     ],
     "destination": [
      "obj-67",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      16
     ],
     "destination": [
      "obj-69",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      17
     ],
     "destination": [
      "obj-71",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      18
     ],
     "destination": [
      "obj-73",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      19
     ],
     "destination": [
      "obj-75",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      20
     ],
     "destination": [
      "obj-78",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      21
     ],
     "destination": [
      "obj-80",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      22
     ],
     "destination": [
      "obj-82",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-91",
      23
     ],
     "destination": [
      "obj-84",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      0
     ],
     "destination": [
      "obj-92",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-92",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      1
     ],
     "destination": [
      "obj-93",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-93",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      2
     ],
     "destination": [
      "obj-94",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-94",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      3
     ],
     "destination": [
      "obj-95",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-95",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      4
     ],
     "destination": [
      "obj-96",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-96",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      5
     ],
     "destination": [
      "obj-97",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-97",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      6
     ],
     "destination": [
      "obj-98",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-98",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      7
     ],
     "destination": [
      "obj-99",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-99",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      8
     ],
     "destination": [
      "obj-100",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-100",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-90",
      9
     ],
     "destination": [
      "obj-101",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-101",
      0
     ],
     "destination": [
      "obj-91",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-23",
      0
     ],
     "destination": [
      "obj-103",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-103",
      0
     ],
     "destination": [
      "obj-84",
      0
     ]
    }
   }
  ],
  "description": "Echolivity - Fisher Spring Hybrid. Convolution + physical spring model + dub feedback.",
  "digest": "Hybrid spring reverb",
  "tags": "reverb spring dub",
  "dependency_cache": [
   {
    "name": "ech_ir_loader.js",
    "bootpath": ".",
    "type": "TEXT",
    "implicit": 1
   },
   {
    "name": "ech_ui.js",
    "bootpath": ".",
    "type": "TEXT",
    "implicit": 1
   }
  ],
  "latency": 0,
  "is_mpe": 0,
  "minimum_live_version": "12.0",
  "minimum_max_version": "8.6",
  "bglocked": 0,
  "default_fontface": 0,
  "gridonopen": 1,
  "gridsnaponopen": 1,
  "objectsnaponopen": 1,
  "statusbarvisible": 2,
  "toolbarvisible": 1,
  "lefttoolbarpinned": 0,
  "toptoolbarpinned": 0,
  "righttoolbarpinned": 0,
  "bottomtoolbarpinned": 0,
  "toolbars_unpinned_last_save": 0,
  "tallnewobj": 0,
  "boxanimatetime": 200,
  "enablehscroll": 1,
  "enablevscroll": 1,
  "subpatcher_template": "",
  "style": "",
  "autosave": 0,
  "assistshowspatchername": 0,
  "external_mpe_tuning_enabled": 0,
  "platform_compatibility": 0,
  "openrectmode": 0,
  "devicewidth": 998.0,
  "project": {
   "version": 1,
   "creationdate": 1763424000,
   "modificationdate": 1763424000,
   "viewrect": [
    0.0,
    0.0,
    300.0,
    500.0
   ],
   "autoorganize": 1,
   "hideprojectwindow": 1,
   "showdependencies": 1,
   "autolocalize": 0,
   "contents": {
    "patchers": {}
   },
   "layout": {},
   "searchpath": {},
   "detailsvisible": 0,
   "amxdtype": 1633771873,
   "readonly": 0,
   "devpathtype": 0,
   "devpath": ".",
   "sortmode": 0,
   "viewmode": 0,
   "includepackages": 0
  },
  "parameters": {
   "obj-28": [
    "echstore",
    "echstore",
    0
   ],
   "obj-32": [
    "Drive",
    "Drive",
    0
   ],
   "obj-34": [
    "Decay",
    "Decay",
    0
   ],
   "obj-37": [
    "Tone",
    "Tone",
    0
   ],
   "obj-39": [
    "Damping",
    "Damping",
    0
   ],
   "obj-42": [
    "Mix",
    "Mix",
    0
   ],
   "obj-44": [
    "Output",
    "Output",
    0
   ],
   "obj-47": [
    "Boing",
    "Boing",
    0
   ],
   "obj-49": [
    "Tension",
    "Tension",
    0
   ],
   "obj-51": [
    "Dispersion",
    "Dispers.",
    0
   ],
   "obj-53": [
    "Resonance",
    "Reson.",
    0
   ],
   "obj-55": [
    "Movement",
    "Movement",
    0
   ],
   "obj-58": [
    "IR Level",
    "IR",
    0
   ],
   "obj-60": [
    "Model Level",
    "Model",
    0
   ],
   "obj-62": [
    "Hybrid Blend",
    "Blend",
    0
   ],
   "obj-64": [
    "Engine Mode",
    "Engine",
    0
   ],
   "obj-67": [
    "Feedback",
    "Feedback",
    0
   ],
   "obj-69": [
    "FB Tone",
    "FB Tone",
    0
   ],
   "obj-71": [
    "FB Drive",
    "FB Drive",
    0
   ],
   "obj-73": [
    "FB Damping",
    "FB Damp",
    0
   ],
   "obj-75": [
    "Self-Osc",
    "Self-Osc",
    0
   ],
   "obj-78": [
    "Pre-delay",
    "Pre-dly",
    0
   ],
   "obj-80": [
    "Width",
    "Width",
    0
   ],
   "obj-82": [
    "Modulation",
    "Mod",
    0
   ],
   "obj-84": [
    "IR",
    "IR",
    0
   ],
   "parameterbanks": {
    "0": {
     "index": 0,
     "name": "Core",
     "parameters": [
      "Drive",
      "Decay",
      "Tone",
      "Damping",
      "Mix",
      "Output",
      "-",
      "-"
     ]
    },
    "1": {
     "index": 1,
     "name": "Spring",
     "parameters": [
      "Boing",
      "Tension",
      "Dispersion",
      "Resonance",
      "Movement",
      "-",
      "-",
      "-"
     ]
    },
    "2": {
     "index": 2,
     "name": "Hybrid",
     "parameters": [
      "Engine Mode",
      "IR",
      "IR Level",
      "Model Level",
      "Hybrid Blend",
      "-",
      "-",
      "-"
     ]
    },
    "3": {
     "index": 3,
     "name": "Dub",
     "parameters": [
      "Feedback",
      "FB Tone",
      "FB Drive",
      "FB Damping",
      "Self-Osc",
      "-",
      "-",
      "-"
     ]
    },
    "4": {
     "index": 4,
     "name": "Advanced",
     "parameters": [
      "Pre-delay",
      "Width",
      "Modulation",
      "-",
      "-",
      "-",
      "-",
      "-"
     ]
    }
   },
   "inherited_shortname": 1
  }
 }
}