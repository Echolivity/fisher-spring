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
   826,
   169
  ],
  "openinpresentation": 1,
  "devicewidth": 826.0,
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
         "code": "// ECHOLIVITY gen~ FRONT\n// Port of reference/engine.py: input_stage(), feedback injection, predelay,\n// convolution send routing.\n// in1 L, in2 R, in3 dub feedback return (tapout~), in4 spring->IR send (tapout~)\n// out1 engine input eng (mono), out2 convolution input\n// gen~ rule: function definitions must come before every other statement\n\nasym(x, k, b) {\n\ttb = tanh(k * b);\n\ts2 = 1 - tb * tb;\n\treturn (tanh(k * (x + b)) - tb) / (k * s2);\n}\n\nParam drive(0.25, min=0, max=1);\nParam predelay(0, min=0, max=250);\nParam engine_mode(2, min=0, max=4);\n\nHistory pe_lp(0);\nHistory de_lp(0);\nHistory dcx(0);\nHistory dcy(0);\nHistory pd_sm(-1);\nDelay pd(30000);\n\nmono = 0.5 * (in1 + in2);\n\na_pe = 1 - exp(-twopi * 1500 / samplerate);\npe = 1.5 * drive;\nk = pow(10, drive * 1.5);\nmakeup = pow(k, -0.8);\nh = clamp((drive - 0.6) / 0.4, 0, 1);\nr_dc = 1 - twopi * 10 / samplerate;\n\n// pre-emphasis -> soft/hard saturation -> de-emphasis -> DC block\np1 = pe_lp + a_pe * (mono - pe_lp);\npe_lp = fixdenorm(p1);\nxe = mono + pe * (mono - p1);\nkx = k * xe;\nsoft = asym(kx, 1, 0.15);\nhard = kx / pow(1 + pow(abs(kx), 6), 1 / 6);\ny = ((1 - h) * soft + h * hard) * makeup;\nd1 = de_lp + a_pe * (y - de_lp);\nde_lp = fixdenorm(d1);\ny2 = d1 + (y - d1) / (1 + pe);\ndc = y2 - dcx + r_dc * dcy;\ndcx = y2;\ndcy = fixdenorm(dc);\n\n// dub feedback enters after the drive stage, before predelay (inside the loop)\ne0 = dc + in3;\n\n// predelay (smoothed, linear interpolation)\npd_t = predelay * 0.001 * samplerate;\npd_s = pd_sm < 0 ? pd_t : pd_sm + (pd_t - pd_sm) * 0.002;   // ~10 ms glide, starts on target\npd_sm = pd_s;\npd.write(e0);\neng = pd_s < 1 ? e0 : pd.read(pd_s, interp=\"linear\");\n\nout1 = eng;\n// Model>IR: the IR is excited by the spring output plus half the direct signal\nout2 = engine_mode > 3.5 ? (in4 + 0.5 * eng) : eng;\n",
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
         "code": "// ECHOLIVITY gen~ CONVOLUTION\n// Uniformly partitioned overlap-save convolution, mono in -> stereo out.\n// Same algorithm as reference/engine.py PartitionedConvolver, but real-time:\n//  - every B samples: IFFT the accumulated spectra (L,R), FFT the newest 2B input frame\n//  - the K partition multiply-accumulates are spread evenly over the B samples\n//    of each block, so CPU per sample is flat apart from the 3 FFTs at the boundary\n//  - latency = 2B samples (B = 512 at <=48 kHz, 1024 at 88.2/96 kHz -> ~21-23 ms),\n//    which behaves like a fixed extra predelay on the IR path (documented)\n// H spectra are written by ir_loader.js into buffer ---echH (2 channels):\n//    sample index (k*(B+1) + bin)*2 + {0 re, 1 im}\n// in1 mono input; out1 L, out2 R\n\nParam nparts(0, min=0, max=400);\nParam bsize(512, min=64, max=1024);\nBuffer H(\"echH_unbound\");\n\nData inb(2048);\nData fdl(820000);\nData acc(2050, 2);\nData outb(1024, 2);\nData re(2048);\nData im(2048);\nData tw(1024, 2);\nHistory cnt(0);\nHistory pos(0);\nHistory twn(0);\nHistory lastK(0);\n\n// gen~ scoping: declare every variable used inside loops/ifs at the top level\ni = 0; j = 0; k = 0; b = 0; m = 0; k0 = 0; k1 = 0; slot = 0; fb = 0; hb = 0;\nxr = 0; xi = 0; hlr = 0; hli = 0; hrr = 0; hri = 0; job = 0; sgn = 0;\ntr = 0; ti = 0; span = 0; half = 0; tstep = 0; wr = 0; wi = 0; pr = 0; pi2 = 0;\nvr = 0; vi = 0; ur = 0; ui = 0; fbase = 0;\n\nB = floor(bsize);\nN = 2 * B;\nKp = floor(nparts);\n\n// (re)initialise twiddles and state on block-size or partition-count change\nif (twn != N || lastK != Kp) {\n\tfor (i = 0; i < N / 2; i += 1) {\n\t\tpoke(tw, cos(twopi * i / N), i, 0);\n\t\tpoke(tw, sin(twopi * i / N), i, 1);\n\t}\n\tfor (i = 0; i < 2 * (B + 1); i += 1) {\n\t\tpoke(acc, 0, i, 0);\n\t\tpoke(acc, 0, i, 1);\n\t}\n\tfor (i = 0; i < B; i += 1) {\n\t\tpoke(outb, 0, i, 0);\n\t\tpoke(outb, 0, i, 1);\n\t}\n\tfor (i = 0; i < Kp * (B + 1) * 2; i += 1) {\n\t\tpoke(fdl, 0, i);\n\t}\n\ttwn = N;\n\tlastK = Kp;\n\tcnt = 0;\n\tpos = 0;\n}\n\nc = cnt;\npoke(inb, in1, B + c);\nout1 = peek(outb, c, 0);\nout2 = peek(outb, c, 1);\n\n// spread multiply-accumulate: partitions k0..k1-1 on this sample\nif (Kp > 0) {\n\tk0 = floor(c * Kp / B);\n\tk1 = floor((c + 1) * Kp / B);\n\tfor (k = k0; k < k1; k += 1) {\n\t\tslot = (pos + k) % Kp;\n\t\tfb = slot * (B + 1) * 2;\n\t\thb = k * (B + 1) * 2;\n\t\tfor (b = 0; b <= B; b += 1) {\n\t\t\txr = peek(fdl, fb + 2 * b);\n\t\t\txi = peek(fdl, fb + 2 * b + 1);\n\t\t\thlr = peek(H, hb + 2 * b, 0);\n\t\t\thli = peek(H, hb + 2 * b + 1, 0);\n\t\t\thrr = peek(H, hb + 2 * b, 1);\n\t\t\thri = peek(H, hb + 2 * b + 1, 1);\n\t\t\tpoke(acc, peek(acc, 2 * b, 0) + xr * hlr - xi * hli, 2 * b, 0);\n\t\t\tpoke(acc, peek(acc, 2 * b + 1, 0) + xr * hli + xi * hlr, 2 * b + 1, 0);\n\t\t\tpoke(acc, peek(acc, 2 * b, 1) + xr * hrr - xi * hri, 2 * b, 1);\n\t\t\tpoke(acc, peek(acc, 2 * b + 1, 1) + xr * hri + xi * hrr, 2 * b + 1, 1);\n\t\t}\n\t}\n}\n\n// block boundary: IFFT L, IFFT R, FFT newest input frame\nif (c >= B - 1) {\n\tfor (job = 0; job < 3; job += 1) {\n\t\tsgn = -1;\n\t\tif (job < 2) {\n\t\t\tsgn = 1;\n\t\t\tfor (b = 0; b <= B; b += 1) {\n\t\t\t\tpoke(re, peek(acc, 2 * b, job), b);\n\t\t\t\tpoke(im, peek(acc, 2 * b + 1, job), b);\n\t\t\t\tpoke(acc, 0, 2 * b, job);\n\t\t\t\tpoke(acc, 0, 2 * b + 1, job);\n\t\t\t}\n\t\t\tfor (b = 1; b < B; b += 1) {\n\t\t\t\tpoke(re, peek(re, b), N - b);\n\t\t\t\tpoke(im, -peek(im, b), N - b);\n\t\t\t}\n\t\t} else {\n\t\t\tfor (b = 0; b < N; b += 1) {\n\t\t\t\tpoke(re, peek(inb, b), b);\n\t\t\t\tpoke(im, 0, b);\n\t\t\t}\n\t\t}\n\t\t// in-place radix-2 FFT, sign sgn (-1 forward, +1 inverse)\n\t\tj = 0;\n\t\tfor (i = 0; i < N - 1; i += 1) {\n\t\t\tif (i < j) {\n\t\t\t\ttr = peek(re, i); ti = peek(im, i);\n\t\t\t\tpoke(re, peek(re, j), i); poke(im, peek(im, j), i);\n\t\t\t\tpoke(re, tr, j); poke(im, ti, j);\n\t\t\t}\n\t\t\tm = floor(N / 2);\n\t\t\twhile (m >= 1 && j >= m) {\n\t\t\t\tj -= m;\n\t\t\t\tm = floor(m / 2);\n\t\t\t}\n\t\t\tj += m;\n\t\t}\n\t\tspan = 2;\n\t\twhile (span <= N) {\n\t\t\thalf = floor(span / 2);\n\t\t\ttstep = floor(N / span);\n\t\t\tfor (i = 0; i < N; i += span) {\n\t\t\t\tfor (k = 0; k < half; k += 1) {\n\t\t\t\t\twr = peek(tw, k * tstep, 0);\n\t\t\t\t\twi = sgn * peek(tw, k * tstep, 1);\n\t\t\t\t\tpr = peek(re, i + k + half); pi2 = peek(im, i + k + half);\n\t\t\t\t\tvr = pr * wr - pi2 * wi;\n\t\t\t\t\tvi = pr * wi + pi2 * wr;\n\t\t\t\t\tur = peek(re, i + k); ui = peek(im, i + k);\n\t\t\t\t\tpoke(re, ur + vr, i + k); poke(im, ui + vi, i + k);\n\t\t\t\t\tpoke(re, ur - vr, i + k + half); poke(im, ui - vi, i + k + half);\n\t\t\t\t}\n\t\t\t}\n\t\t\tspan *= 2;\n\t\t}\n\t\tif (job < 2) {\n\t\t\tfor (b = 0; b < B; b += 1) {\n\t\t\t\tpoke(outb, fixdenorm(peek(re, B + b) / N), b, job);\n\t\t\t}\n\t\t} else if (Kp > 0) {\n\t\t\tpos = (pos - 1 + Kp) % Kp;\n\t\t\tfbase = pos * (B + 1) * 2;\n\t\t\tfor (b = 0; b <= B; b += 1) {\n\t\t\t\tpoke(fdl, peek(re, b), fbase + 2 * b);\n\t\t\t\tpoke(fdl, peek(im, b), fbase + 2 * b + 1);\n\t\t\t}\n\t\t\tfor (b = 0; b < B; b += 1) {\n\t\t\t\tpoke(inb, peek(inb, B + b), b);\n\t\t\t}\n\t\t}\n\t}\n\tcnt = 0;\n} else {\n\tcnt = c + 1;\n}\n",
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
         "code": "// ECHOLIVITY gen~ BACK\n// Port of reference/engine.py: spring_process(), engine routing,\n// feedback_process(), output_stage().\n// in1 dry L, in2 dry R, in3 engine input e (from FRONT),\n// in4 convolution L, in5 convolution R\n// out1 L, out2 R, out3 dub feedback send (-> tapin~), out4 spring->IR send (-> tapin~)\n// gen~ rule: function definitions must come before every other statement\n\nasym(x, k, b) {\n\ttb = tanh(k * b);\n\ts2 = 1 - tb * tb;\n\treturn (tanh(k * (x + b)) - tb) / (k * s2);\n}\n\nopc(fc) {\n\treturn 1 - exp(-twopi * fc / samplerate);\n}\n\nmodelpeak(dec, ten, disp) {\n\tkk = max(1, floor(samplerate / 22050 + 0.5));\n\taa = -(0.45 + 0.35 * disp);\n\tlp = 0.08 - 0.05 * ten;\n\tapd = 64 * kk * (1 - aa) / (1 + aa);\n\ttdl = kk * (1 - aa * aa) / (1 + 2 * aa * cos(kk * twopi * 400 / samplerate) + aa * aa);\n\tle = (max(lp * samplerate - apd, 8) + 64 * tdl) / samplerate;\n\tgg = pow(10, -3 * le / (1.15 * dec));\n\treturn 0.3 * sqrt(1 - gg * gg) * 5.5 / (1 - gg);\n}\n\nParam decay(2.0, min=0.3, max=8);\nParam damping(0.8, min=0, max=1);\nParam boing(0.4, min=0, max=1);\nParam tension(0.44, min=0, max=1);\nParam dispersion(0.55, min=0, max=1);\nParam resonance(0.35, min=0, max=1);\nParam movement(0.3, min=0, max=1);\nParam modulation(0.15, min=0, max=1);\nParam engine_mode(2, min=0, max=4);\nParam ir_level(0, min=-24, max=6);\nParam model_level(0, min=-24, max=6);\nParam blend(0.5, min=0, max=1);\nParam feedback(0, min=0, max=1);\nParam fb_tone(0, min=-1, max=1);\nParam fb_drive(0.2, min=0, max=1);\nParam fb_damping(0.3, min=0, max=1);\nParam self_osc(0, min=0, max=1);\nParam tone(0, min=-1, max=1);\nParam width(1, min=0, max=2);\nParam drive(0.25, min=0, max=1);\nParam drywet(0.35, min=0, max=1);   // Live parameter 'Mix' (gen~ reserves the name mix)\nParam output(0, min=-24, max=6);\nParam ir_peak(1, min=0.001, max=100000);   // set by ir_loader.js\nParam have_ir(0, min=0, max=1);            // set by ir_loader.js\n\nDelay sp0(12000);\nDelay sp1(12000);\nData ap(256, 2);          // 64 stages x Kmax 4, per spring\nData st(64);              // misc state, see indices below\n\n// state indices\n// 0,1 delay smooth  2 g smooth  3 hp  4 lp  5 envf  6 envs  7 swx  8 swv  9 slap\n// 10,11 wob  12,13 wob2  14 lfo  15,16 damp  17-20 peak tdf2  21,22 splash\n// 23-26 out dc  27 api  28-38 feedback  39-43,50 output  44 init  45-49 gain smooth  51-56,58,59 tank/recovery  57 osc agc\n\n\n// gen~ scoping: declare variables used inside loops/ifs at the top level\ni = 0; idx = 0; wd0 = 0; wa = 0; wd1 = 0; wb = 0; gi = 0; gm = 0;\n\nmode = floor(engine_mode + 0.5);\nserial = mode >= 3 ? 1 : 0;\n\n// ---------------- parameter smoothing (20 ms) ----------------\nsm = 1 - exp(-1 / (0.02 * samplerate));\nirg_t = pow(10, ir_level / 20);\nmdg_t = pow(10, model_level / 20);\nirg = st.peek(45) + sm * (irg_t - st.peek(45));     st.poke(irg, 45);\nmdg = st.peek(46) + sm * (mdg_t - st.peek(46));     st.poke(mdg, 46);\nbl = st.peek(47) + sm * (blend - st.peek(47));      st.poke(bl, 47);\nmx = st.peek(48) + sm * (drywet - st.peek(48));        st.poke(mx, 48);\ngo_t = pow(10, output / 20);\ngo = st.peek(49) + sm * (go_t - st.peek(49));       st.poke(go, 49);\n\n// ---------------- spring model ----------------\nK = max(1, floor(samplerate / 22050 + 0.5));\ndec = decay * (serial ? 0.3 : 1);\na0 = -(0.45 + 0.35 * dispersion);\n// spring geometry: Fisher K-10 manual, one-way 29 / 37 ms (tension 0.44)\nloop_s = 0.08 - 0.05 * tension;\nratio = 37 / 29;\nap_dc = 64 * K * (1 - a0) / (1 + a0);\n// effective loop time at 400 Hz (the cascade delays lows far more than mids)\ncw = cos(K * twopi * 400 / samplerate);\ntdl_lo = K * (1 - a0 * a0) / (1 + 2 * a0 * cw + a0 * a0);\nloop_eff = (max(loop_s * samplerate - ap_dc, 8) + 64 * tdl_lo) / samplerate;\ng_t = pow(10, -3 * loop_eff / (1.15 * dec));\nfr = 900 + 2100 * tension;\ngdb = 60 * loop_eff * 2 * resonance / dec;\nA = pow(10, gdb / 40);\nw0 = twopi * fr / samplerate;\nalpha = sin(w0) / 3;\na0n = 1 + alpha / A;\nb0 = (1 + alpha * A) / a0n;\nb1 = (-2 * cos(w0)) / a0n;\nb2 = (1 - alpha * A) / a0n;\na1 = (-2 * cos(w0)) / a0n;\na2 = (1 - alpha / A) / a0n;\npnorm = 1 / (A * A);\nc_damp = opc(1500 + 9500 * pow(1 - damping, 2));\nout_scale = sqrt(max(1 - g_t * g_t, 0.0001)) * 5.5;\nr_dc = 1 - twopi * 10 / samplerate;\n\n// spring input: IR>Model feeds the convolution output to the springs\ns_in = mode == 3 ? 0.5 * (in4 + in5) * irg : in3;\n\n// tank feed high-passes, Fisher K-10 values (C1/R3 ~300 Hz, C3/R7 59 Hz)\nhpst = st.peek(3) + opc(300) * (s_in - st.peek(3));\nst.poke(fixdenorm(hpst), 3);\nlpst = st.peek(4) + opc(59) * ((s_in - hpst) - st.peek(4));\nst.poke(fixdenorm(lpst), 4);\nxin = (s_in - hpst) - lpst;\n\n// transient detector -> slap / sway\nax = abs(s_in);\nenvf = st.peek(5) + opc(1 / (twopi * 0.001)) * (ax - st.peek(5));\nenvs = st.peek(6) + opc(1 / (twopi * 0.06)) * (ax - st.peek(6));\nst.poke(fixdenorm(envf), 5);\nst.poke(fixdenorm(envs), 6);\ntr = max(envf - 1.5 * envs, 0);\nhit = min(tr * 8, 1);\nif ((noise() + 1) * 0.5 < movement * 0.4 / samplerate) {\n\thit = max(hit, 0.3 + 0.2 * (noise() + 1));\n}\nslap = max(st.peek(9) * exp(-1 / (0.12 * samplerate)), hit);\nst.poke(fixdenorm(slap), 9);\nw_sw = twopi * 6 / samplerate;\nr_sw = exp(-1 / (0.4 * samplerate));\nsx = st.peek(7);\nsv = st.peek(8);\nnx = r_sw * (cos(w_sw) * sx - sin(w_sw) * sv) + hit * 0.02;\nnv = r_sw * (sin(w_sw) * sx + cos(w_sw) * sv);\nst.poke(fixdenorm(nx), 7);\nst.poke(fixdenorm(nv), 8);\nsway = clamp(nx * 10, -1, 1);\n\nlfo = st.peek(14) + twopi * (0.2 + 0.9 * modulation) / samplerate;\nlfo = lfo > twopi ? lfo - twopi : lfo;\nst.poke(lfo, 14);\n\ng = st.peek(2) + sm * (g_t - st.peek(2));\nst.poke(g, 2);\n\nnz = noise();\nsp_h = st.peek(21) + opc(2500) * (nz - st.peek(21));\nst.poke(fixdenorm(sp_h), 21);\nsp_l = st.peek(22) + opc(6000) * ((nz - sp_h) - st.peek(22));\nst.poke(fixdenorm(sp_l), 22);\nsplash = sp_l * boing * slap * envs * 1.5;\n\nc_wob = opc(0.7);\nw0a = st.peek(10) + c_wob * (noise() - st.peek(10));\nw1a = st.peek(11) + c_wob * (noise() - st.peek(11));\nst.poke(fixdenorm(w0a), 10);\nst.poke(fixdenorm(w1a), 11);\nw0b = st.peek(12) + c_wob * (w0a - st.peek(12));\nw1b = st.peek(13) + c_wob * (w1a - st.peek(13));\nst.poke(fixdenorm(w0b), 12);\nst.poke(fixdenorm(w1b), 13);\n\nmod0 = 1 + 0.006 * movement * w0b * 40 + 0.004 * modulation * sin(lfo) + 0.03 * boing * sway;\nmod1 = 1 + 0.006 * movement * w1b * 40 + 0.004 * modulation * sin(lfo + 0.5 * pi) - 0.024 * boing * sway;\ndt0 = clamp(loop_s * samplerate * mod0 - ap_dc, 8, 11990);\ndt1 = clamp(loop_s * ratio * samplerate * mod1 - ap_dc, 8, 11990);\ninit = st.peek(44);\nd0 = init < 0.5 ? dt0 : st.peek(0) + sm * (dt0 - st.peek(0));\nd1 = init < 0.5 ? dt1 : st.peek(1) + sm * (dt1 - st.peek(1));\nst.poke(d0, 0);\nst.poke(d1, 1);\nst.poke(1, 44);\n\n// read (gen~ read(t) before write == reference read(t-1))\ny0 = sp0.read(d0 + 1, interp=\"cubic\");\ny1 = sp1.read(d1 + 1, interp=\"cubic\");\n// output transducer: one-way = half round trip incl. half the dispersion\ncw1 = cos(K * twopi * 1000 / samplerate);\nap_1k = 64 * K * (1 - a0 * a0) / (1 + 2 * a0 * cw1 + a0 * a0);\no0 = sp0.read(max(1, 0.5 * (d0 - ap_1k)) + 1, interp=\"cubic\");\no1 = sp1.read(max(1, 0.5 * (d1 - ap_1k)) + 1, interp=\"cubic\");\ncth = cos(0.12);\nsth = sin(0.12);\nc0 = cth * y0 + sth * y1;\nc1 = -sth * y0 + cth * y1;\n\na_mod = max(a0 * (1 + 0.04 * movement * w0b * 40), -0.9);\napi = st.peek(27);\nthr = max(1 - 0.7 * boing * slap, 0.25);\n\nv0 = xin + g * c0 + splash;\nv1 = xin + g * c1 + splash;\nfor (i = 0; i < 64; i += 1) {\n\tidx = i * 4 + api;\n\twd0 = ap.peek(idx, 0);\n\twa = v0 - a_mod * wd0;\n\tv0 = a_mod * wa + wd0;\n\tap.poke(fixdenorm(wa), idx, 0);\n\twd1 = ap.peek(idx, 1);\n\twb = v1 - a_mod * wd1;\n\tv1 = a_mod * wb + wd1;\n\tap.poke(fixdenorm(wb), idx, 1);\n}\nst.poke(api + 1 >= K ? 0 : api + 1, 27);\n\ndm0 = st.peek(15) + c_damp * (v0 - st.peek(15));\ndm1 = st.peek(16) + c_damp * (v1 - st.peek(16));\nst.poke(fixdenorm(dm0), 15);\nst.poke(fixdenorm(dm1), 16);\n\nyb0 = b0 * dm0 + st.peek(17);\nst.poke(fixdenorm(b1 * dm0 - a1 * yb0 + st.peek(18)), 17);\nst.poke(fixdenorm(b2 * dm0 - a2 * yb0), 18);\nyb1 = b0 * dm1 + st.peek(19);\nst.poke(fixdenorm(b1 * dm1 - a1 * yb1 + st.peek(20)), 19);\nst.poke(fixdenorm(b2 * dm1 - a2 * yb1), 20);\n\nq0 = thr * tanh(yb0 * pnorm / thr);\nq1 = thr * tanh(yb1 * pnorm / thr);\nsp0.write(fixdenorm(q0));\nsp1.write(fixdenorm(q1));\n\n// output side: tank transducers (fitted to the K-10 IR: HP 200 Hz, 2nd-order LP 8 kHz),\n// then the K-10 recovery amp, which its 680k||12pF feedback makes ~flat (LP 13 kHz)\nc_r1 = opc(200);\nc_r2 = opc(min(8000, 0.45 * samplerate));\nc_r3 = opc(min(13000, 0.45 * samplerate));\nra = st.peek(51) + c_r1 * (o0 - st.peek(51)); st.poke(fixdenorm(ra), 51); o0 = o0 - ra;\nrb = st.peek(52) + c_r2 * (o0 - st.peek(52)); st.poke(fixdenorm(rb), 52); o0 = rb;\nrc = st.peek(53) + c_r2 * (o0 - st.peek(53)); st.poke(fixdenorm(rc), 53); o0 = rc;\nrg = st.peek(58) + c_r3 * (o0 - st.peek(58)); st.poke(fixdenorm(rg), 58); o0 = rg;\nrd = st.peek(54) + c_r1 * (o1 - st.peek(54)); st.poke(fixdenorm(rd), 54); o1 = o1 - rd;\nre2 = st.peek(55) + c_r2 * (o1 - st.peek(55)); st.poke(fixdenorm(re2), 55); o1 = re2;\nrf = st.peek(56) + c_r2 * (o1 - st.peek(56)); st.poke(fixdenorm(rf), 56); o1 = rf;\nrh = st.peek(59) + c_r3 * (o1 - st.peek(59)); st.poke(fixdenorm(rh), 59); o1 = rh;\noo0 = o0 * out_scale;\noo1 = o1 * out_scale;\ndcl = oo0 - st.peek(23) + r_dc * st.peek(24);\nst.poke(oo0, 23);\nst.poke(fixdenorm(dcl), 24);\ndcr = oo1 - st.peek(25) + r_dc * st.peek(26);\nst.poke(oo1, 25);\nst.poke(fixdenorm(dcr), 26);\nsL = dcl * mdg;\nsR = dcr * mdg;\n\n// ---------------- engine routing ----------------\ncL = in4 * irg;\ncR = in5 * irg;\nwL = 0;\nwR = 0;\nif (have_ir < 0.5 && mode != 1) {\n\twL = mode == 0 ? 0 : sL;\n\twR = mode == 0 ? 0 : sR;\n} else if (mode == 0) {\n\twL = cL; wR = cR;\n} else if (mode == 1) {\n\twL = sL; wR = sR;\n} else if (mode == 2) {\n\tgi = cos(0.5 * pi * bl);\n\tgm = sin(0.5 * pi * bl);\n\twL = gi * cL + gm * sL; wR = gi * cR + gm * sR;\n} else if (mode == 3) {\n\twL = (1 - bl) * cL + bl * sL; wR = (1 - bl) * cR + bl * sR;\n} else {\n\twL = (1 - bl) * sL + bl * cL; wR = (1 - bl) * sR + bl * cR;\n}\nout4 = 0.5 * (sL + sR);\n\n// feedback normalisation: 1 / estimated peak gain of the active engine path\npm = modelpeak(decay, tension, dispersion) * mdg;\npms = modelpeak(decay * 0.3, tension, dispersion) * mdg;\npir = ir_peak * irg;\npk = pm;\nif (have_ir < 0.5) {\n\tpk = mode == 0 ? 1 : pm;\n} else if (mode == 0) {\n\tpk = pir;\n} else if (mode == 2) {\n\tpk = sqrt(pow(cos(0.5 * pi * bl) * pir, 2) + pow(sin(0.5 * pi * bl) * pm, 2));\n} else if (mode == 3) {\n\tpk = sqrt(pow((1 - bl) * pir, 2) + pow(bl * pir * sqrt(pms), 2));\n} else if (mode == 4) {\n\tpk = sqrt(pow((1 - bl) * pms, 2) + pow(bl * pir * pow(0.5 + pms, 0.75), 2));\n}\nfbnorm = 1 / max(pk, 0.05);\n\n// ---------------- dub feedback loop ----------------\nf = 0.5 * (wL + wR);\nc_hp = opc(150 * pow(2, fb_tone * 1.6));\nc_lp = opc(min(3000 * pow(2, fb_tone * 1.6), 0.45 * samplerate));\nc_dm = opc(min(16000 * pow(1 - fb_damping, 2) + 800, 0.45 * samplerate));\nh1 = st.peek(28) + c_hp * (f - st.peek(28)); st.poke(fixdenorm(h1), 28); f = f - h1;\nh2 = st.peek(29) + c_hp * (f - st.peek(29)); st.poke(fixdenorm(h2), 29); f = f - h2;\nl1 = st.peek(30) + c_lp * (f - st.peek(30)); st.poke(fixdenorm(l1), 30); f = l1;\nl2 = st.peek(31) + c_lp * (f - st.peek(31)); st.poke(fixdenorm(l2), 31); f = l2;\nl3 = st.peek(32) + c_dm * (f - st.peek(32)); st.poke(fixdenorm(l3), 32); f = l3;\nf = asym(f, 1 + 14 * fb_drive, 0.1 * fb_drive);\ngrms = st.peek(34) + opc(1 / (twopi * 0.5)) * (f * f - st.peek(34));\nst.poke(fixdenorm(grms), 34);\ngs = 1 - self_osc;\nguard = st.peek(35);\nguard = st.peek(36) < 0.5 ? 1 : guard;      // first sample init\nst.poke(1, 36);\ngthr = self_osc > 0 ? max(0.01, 4 * pow(10, (-30 + 16 * self_osc) / 10)) : 0.01;\nif (gs > 0 && grms > gthr) {\n\tguard = max(guard - gs / samplerate, 0.4);\n} else {\n\tguard = min(guard + 0.5 / samplerate, 1);\n}\nst.poke(guard, 35);\n// self-oscillation AGC (state 57): reaches the Self-Osc target level on any engine\nog = st.peek(57);\nog = og < 1 ? 1 : og;\nosc_t = pow(10, (-30 + 16 * self_osc) / 10);\nlvl = st.peek(33) * st.peek(33) * 0.5;      // fast peak envelope -> power\nif (self_osc > 0) {\n\tif (lvl < 0.5 * osc_t) {\n\t\tog = min(og * pow(10, 2 / 20 / samplerate), 16);\n\t} else if (lvl > 2 * osc_t) {\n\t\tog = max(og * pow(10, -12 / 20 / samplerate), 1);\n\t}\n} else {\n\tog = max(og * pow(10, -12 / 20 / samplerate), 1);\n}\nst.poke(og, 57);\nf = f * (0.98 * feedback + 0.6 * self_osc) * fbnorm * guard * (1 + (og - 1) * self_osc);\nfenv = max(abs(f), st.peek(33) * exp(-1 / (0.15 * samplerate)));\nst.poke(fixdenorm(fenv), 33);\nf = fenv > 0.5 ? f * 0.5 / fenv : f;\nfdc = f - st.peek(37) + r_dc * st.peek(38);\nst.poke(f, 37);\nst.poke(fixdenorm(fdc), 38);\nout3 = fdc;\n\n// ---------------- output section ----------------\nc_t = opc(900);\ngl = pow(10, -6 * tone / 40);\ngh = pow(10, 6 * tone / 40);\ntl = st.peek(39) + c_t * (wL - st.peek(39)); st.poke(fixdenorm(tl), 39);\ntrr = st.peek(40) + c_t * (wR - st.peek(40)); st.poke(fixdenorm(trr), 40);\nl = tl * gl + (wL - tl) * gh;\nr = trr * gl + (wR - trr) * gh;\nm = 0.5 * (l + r);\ns = 0.5 * (l - r) * width;\nl = asym(m + s, 1 + 2 * drive, 0.1);\nr = asym(m - s, 1 + 2 * drive, 0.1);\nodl = l - st.peek(41) + r_dc * st.peek(42); st.poke(l, 41); st.poke(fixdenorm(odl), 42);\nodr = r - st.peek(43) + r_dc * st.peek(50); st.poke(r, 43); st.poke(fixdenorm(odr), 50);\ngw = sin(0.5 * pi * mx);\ngd = cos(0.5 * pi * mx);\nout1 = (gd * in1 + gw * odl) * go;\nout2 = (gd * in2 + gw * odr) * go;\n",
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
     "maxclass": "v8.codebox",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      ""
     ],
     "patching_rect": [
      600,
      240,
      260,
      120
     ],
     "code": "// ECHOLIVITY - IR conditioning + partition-spectrum builder for gen~ ech_conv.\n// Mirrors reference/engine.py prepare_ir(): resample -> decay/damping envelope\n// -> energy normalisation -> uniform partitions -> FFT spectra.\n//\n// [js ech_ir_loader.js ---echIR ---echH]\n// inlet messages:  sr <hz>          host sample rate (dspstate~)\n//                  irsr <hz>        sample rate of the loaded IR file (info~)\n//                  decay <s>        damping <0..1>   (debounced recompute)\n//                  load             IR buffer has been (re)filled\n//                  clear            unload IR\n// outlet 0: messages for gen~ (bsize, nparts, ir_peak, have_ir)\n// outlet 1: status text for the UI\n\nautowatch = 1;\ninlets = 1;\noutlets = 2;\n\nvar irName = \"echIR\";\nvar hName = \"echH\";\nfunction names(a, b) { irName = String(a); hName = String(b); }\nvar SR = 48000, IRSR = 48000, DECAY = 2.5, DAMP = 0.35;\nvar MAX_S = 4.0, MAX_PARTS = 400;\nvar loaded = false;\nvar task = new Task(rebuild, this);\nvar cache = null, cacheKey = \"\";            // resampled IR, reused for decay/damping edits\n\nfunction sr(x) { if (x > 0 && x !== SR) { SR = x; schedule(); } }\nfunction irsr(x) { if (x > 0) IRSR = x; }\nfunction decay(x) { DECAY = x; schedule(); }\nfunction damping(x) { DAMP = x; schedule(); }\nfunction load() { loaded = true; cacheKey = \"\"; rebuild(); }\nfunction clear() {\n\tloaded = false;\n\toutlet(0, \"nparts\", 0);\n\toutlet(0, \"have_ir\", 0);\n\toutlet(1, \"set\", \"no IR loaded\");\n}\nfunction schedule() { if (loaded) { task.cancel(); task.schedule(250); } }\n\n// ---------------------------------------------------------------- helpers\nfunction fft(re, im, n, sgn) {\n\tvar i, j = 0, m, len, half, step, k, wr, wi, ang, vr, vi, ur, ui, t;\n\tfor (i = 0; i < n - 1; i++) {\n\t\tif (i < j) {\n\t\t\tt = re[i]; re[i] = re[j]; re[j] = t;\n\t\t\tt = im[i]; im[i] = im[j]; im[j] = t;\n\t\t}\n\t\tm = n >> 1;\n\t\twhile (m >= 1 && j >= m) { j -= m; m >>= 1; }\n\t\tj += m;\n\t}\n\tfor (len = 2; len <= n; len <<= 1) {\n\t\thalf = len >> 1;\n\t\tang = sgn * 2 * Math.PI / len;\n\t\tfor (k = 0; k < half; k++) {\n\t\t\twr = Math.cos(ang * k); wi = Math.sin(ang * k);\n\t\t\tfor (i = 0; i < n; i += len) {\n\t\t\t\tvr = re[i + k + half] * wr - im[i + k + half] * wi;\n\t\t\t\tvi = re[i + k + half] * wi + im[i + k + half] * wr;\n\t\t\t\tur = re[i + k]; ui = im[i + k];\n\t\t\t\tre[i + k] = ur + vr; im[i + k] = ui + vi;\n\t\t\t\tre[i + k + half] = ur - vr; im[i + k + half] = ui - vi;\n\t\t\t}\n\t\t}\n\t}\n}\n\nfunction zeros(n) { var a = new Array(n); for (var i = 0; i < n; i++) a[i] = 0; return a; }\n\nfunction lanczosResample(x, ratio) {           // ratio = outSR / inSR\n\tvar a = 8, n = Math.floor(x.length * ratio), y = new Array(n);\n\tvar scale = Math.min(1, ratio);             // low-pass when downsampling\n\tfor (var i = 0; i < n; i++) {\n\t\tvar t = i / ratio, c = Math.floor(t), s = 0, w = 0;\n\t\tfor (var k = c - a + 1; k <= c + a; k++) {\n\t\t\tif (k < 0 || k >= x.length) continue;\n\t\t\tvar d = (t - k) * scale, L;\n\t\t\tif (d === 0) L = 1;\n\t\t\telse if (Math.abs(d) >= a) L = 0;\n\t\t\telse L = a * Math.sin(Math.PI * d) * Math.sin(Math.PI * d / a) / (Math.PI * Math.PI * d * d);\n\t\t\ts += x[k] * L; w += L;\n\t\t}\n\t\ty[i] = w !== 0 ? s / w : 0;\n\t}\n\treturn y;\n}\n\nfunction rt60(x, sr) {                          // Schroeder T20, as estimate_rt60()\n\tvar n = x.length, e = new Array(n), acc = 0, i;\n\tfor (i = n - 1; i >= 0; i--) { acc += x[i] * x[i]; e[i] = acc; }\n\tif (acc <= 0) return 0;\n\tvar i5 = -1, i25 = -1;\n\tfor (i = 0; i < n; i++) {\n\t\tvar db = 10 * Math.log(e[i] / e[0] + 1e-30) / Math.LN10;\n\t\tif (i5 < 0 && db <= -5) i5 = i;\n\t\tif (i25 < 0 && db <= -25) { i25 = i; break; }\n\t}\n\tif (i5 < 0 || i25 <= i5) return n / sr;\n\tvar sx = 0, sy = 0, sxx = 0, sxy = 0, m = i25 - i5;\n\tfor (i = i5; i < i25; i++) {\n\t\tvar tt = i / sr, yy = 10 * Math.log(e[i] / e[0] + 1e-30) / Math.LN10;\n\t\tsx += tt; sy += yy; sxx += tt * tt; sxy += tt * yy;\n\t}\n\tvar slope = (m * sxy - sx * sy) / (m * sxx - sx * sx);\n\treturn slope < 0 ? -60 / slope : 1e9;\n}\n\nfunction fbOnePole(x, c) {                      // zero-phase one-pole low-pass\n\tvar n = x.length, y = new Array(n), s = 0, i;\n\tfor (i = 0; i < n; i++) { s += c * (x[i] - s); y[i] = s; }\n\ts = 0;\n\tfor (i = n - 1; i >= 0; i--) { s += c * (y[i] - s); y[i] = s; }\n\treturn y;\n}\n\n// ---------------------------------------------------------------- main\nfunction rebuild() {\n\tif (!loaded) return;\n\tvar ib = new Buffer(irName);\n\tvar frames = ib.framecount(), chans = Math.min(ib.channelcount(), 2);\n\tif (frames < 2) { clear(); outlet(1, \"set\", \"IR empty\"); return; }\n\toutlet(0, \"nparts\", 0);                     // mute convolver while rewriting H\n\n\tvar ch = [], c, i, key = SR + \"/\" + IRSR + \"/\" + frames;\n\tif (key !== cacheKey) {\n\t\tcache = [];\n\t\tfor (c = 0; c < chans; c++) {\n\t\t\tvar raw = ib.peek(c + 1, 0, frames);\n\t\t\tif (typeof raw === \"number\") raw = [raw];\n\t\t\tif (raw.length > MAX_S * IRSR + 8) raw = raw.slice(0, Math.ceil(MAX_S * IRSR) + 8);\n\t\t\tif (IRSR !== SR) raw = lanczosResample(raw, SR / IRSR);\n\t\t\tcache.push(raw);\n\t\t}\n\t\tif (chans === 1) cache.push(cache[0]);\n\t\tcacheKey = key;\n\t}\n\tfor (c = 0; c < 2; c++) ch.push(cache[c].slice(0));\n\tvar n = Math.min(ch[0].length, Math.floor(MAX_S * SR));\n\tvar fade = Math.floor(0.05 * SR);\n\tfor (c = 0; c < 2; c++) {\n\t\tch[c].length = n;\n\t\tif (ch[0].length >= MAX_S * SR - 1)\n\t\t\tfor (i = 0; i < fade; i++) ch[c][n - 1 - i] *= i / fade;\n\t}\n\n\t// decay / damping envelopes (prepare_ir)\n\tvar mono = new Array(n);\n\tfor (i = 0; i < n; i++) mono[i] = 0.5 * (ch[0][i] + ch[1][i]);\n\tvar rtIr = rt60(mono, SR);\n\tvar extra = Math.max(0, 6.91 * (1 / DECAY - 1 / Math.max(rtIr, 1e-3)));\n\tvar hiExtra = extra + DAMP * 6.91 / 0.6;\n\tvar cs = 1 - Math.exp(-2 * Math.PI * 2000 / SR);\n\tvar energy = 0;\n\tfor (c = 0; c < 2; c++) {\n\t\tvar lo = fbOnePole(ch[c], cs);\n\t\tfor (i = 0; i < n; i++) {\n\t\t\tvar t = i / SR;\n\t\t\tvar v = lo[i] * Math.exp(-extra * t) + (ch[c][i] - lo[i]) * Math.exp(-hiExtra * t);\n\t\t\tch[c][i] = v;\n\t\t\tenergy += v * v;\n\t\t}\n\t}\n\tvar g = 1 / (Math.sqrt(energy / 2) + 1e-12);\n\tfor (c = 0; c < 2; c++) for (i = 0; i < n; i++) ch[c][i] *= g;\n\n\t// partitions\n\tvar B = SR > 50000 ? 1024 : 512, N = 2 * B;\n\tvar K = Math.min(Math.ceil(n / B), MAX_PARTS);\n\tvar hb = new Buffer(hName);\n\thb.send(\"sizeinsamps\", K * (B + 1) * 2);\n\tvar re, im, k, out;\n\tfor (c = 0; c < 2; c++) {\n\t\tfor (k = 0; k < K; k++) {\n\t\t\tre = zeros(N); im = zeros(N);\n\t\t\tfor (i = 0; i < B; i++) {\n\t\t\t\tvar idx = k * B + i;\n\t\t\t\tre[i] = idx < n ? ch[c][idx] : 0;\n\t\t\t}\n\t\t\tfft(re, im, N, -1);\n\t\t\tout = new Array(2 * (B + 1));\n\t\t\tfor (i = 0; i <= B; i++) { out[2 * i] = re[i]; out[2 * i + 1] = im[i]; }\n\t\t\thb.poke(c + 1, k * (B + 1) * 2, out);\n\t\t}\n\t}\n\n\t// peak spectral gain of the mono IR (feedback normalisation)\n\tvar P = 1; while (P < n) P <<= 1;\n\tre = zeros(P); im = zeros(P);\n\tfor (i = 0; i < n; i++) re[i] = 0.5 * (ch[0][i] + ch[1][i]);\n\tfft(re, im, P, -1);\n\tvar pk = 0;\n\tfor (i = 0; i <= P / 2; i++) pk = Math.max(pk, Math.sqrt(re[i] * re[i] + im[i] * im[i]));\n\n\toutlet(0, \"bsize\", B);\n\toutlet(0, \"ir_peak\", pk);\n\toutlet(0, \"nparts\", K);\n\toutlet(0, \"have_ir\", 1);\n\toutlet(1, \"set\", \"IR \" + chans + \"ch \" + IRSR + \"Hz  RT60 \" + rtIr.toFixed(2) + \"s  \" +\n\t\t(n / SR).toFixed(2) + \"s  lat \" + (1000 * 2 * B / SR).toFixed(1) + \"ms\");\n}\n",
     "varname": "ech_ir_loader"
    }
   },
   {
    "box": {
     "id": "obj-13",
     "maxclass": "v8.codebox",
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
      260,
      120
     ],
     "code": "// ECHOLIVITY - IR browser / path helper.\n// [js ech_ui.js]\n// inlet:  lib <index>      library IR chosen in the IR menu (last item = \"User IR\")\n//         user <path>      file dropped on the drop zone\n//         restore <path>   user path restored from the Live Set (pattr)\n// outlet 0: messages for buffer~ ---echIR   (\"replace <path>\")\n// outlet 1: messages for the IR menu        (\"set <index>\")\n// outlet 2: status text\n// outlet 3: user path to store (pattr)\n\nautowatch = 1;\ninlets = 1;\noutlets = 4;\n\n// keep in sync with ir/catalogue.json (generated by tools/build_device.py)\nvar LIB = [\"TP_FISHER_K10_derickgtwk_STEREO_96k\", \"TP_BF_BirdVerb_FenderDeluxe_ST_44k\", \"TP_BF_BirdVerb_Supro_ST_44k\", \"TP_BF_FenderDeluxe_MONO_44k\", \"TP_BF_Supro_MONO_44k\", \"TP_MT_70sStereoSpring_01\", \"TP_MT_SilverFace_Spring_01\", \"TP_MT_Spring_Webcor\", \"SYN_DarkTank2S_C\", \"SYN_K10Spec_2S\", \"SYN_LongTank2S_A\", \"SYN_ShortTank3S_B\", \"SYN_SplashTank1S_D\"];\nvar NAMES = [\"Fisher K-10\", \"Bird-Verb Deluxe\", \"Bird-Verb Supro\", \"Fender Deluxe\", \"Supro\", \"70s Stereo Spring\", \"Silver Face Spring\", \"Spring + Webcor\", \"Synthetic Dark Tank\", \"Synthetic K-10 Spec\", \"Synthetic Long Tank\", \"Synthetic Short Tank\", \"Synthetic Splash\"];      // menu labels, same order as LIB\nvar userPath = \"\";\n\nfunction root() {\n\tvar p = this.patcher.filepath || \"\";\n\tvar i = p.lastIndexOf(\"/\");\n\tp = p.substring(0, i);               // .../device\n\ti = p.lastIndexOf(\"/\");\n\treturn p.substring(0, i);            // project root\n}\n\nfunction lib(i) {\n\ti = Math.floor(i);\n\tif (i < LIB.length) {\n\t\tvar path = root() + \"/ir/processed/\" + LIB[i] + \"__norm48k.wav\";\n\t\toutlet(0, \"replace\", path);\n\t\toutlet(2, \"set\", NAMES[i] + (LIB[i].indexOf(\"SYN_\") === 0 ? \" (synthetic IR)\" : \" (third-party IR)\"));\n\t} else if (userPath !== \"\") {\n\t\toutlet(0, \"replace\", userPath);\n\t\toutlet(2, \"set\", \"User: \" + userPath.substring(userPath.lastIndexOf(\"/\") + 1));\n\t} else {\n\t\toutlet(2, \"set\", \"Drop a WAV on the IR zone\");\n\t}\n}\n\nfunction user(p) {\n\tuserPath = String(p);\n\toutlet(3, userPath);\n\toutlet(1, \"set\", LIB.length);\n\tlib(LIB.length);\n}\n\nfunction restore(p) {\n\tif (p && String(p) !== \"\" && String(p) !== \"0\") userPath = String(p);\n}\n\nfunction anything() {\n\t// live.drop sends a bare path symbol\n\tif (messagename && messagename.indexOf(\"/\") >= 0) user(messagename);\n}\n",
     "varname": "ech_ui"
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
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "",
      "",
      ""
     ],
     "patching_rect": [
      900,
      60,
      60,
      22
     ],
     "text": "t b b b"
    }
   },
   {
    "box": {
     "id": "obj-32",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1080,
      80,
      140,
      22
     ],
     "text": "names ---echIR ---echH"
    }
   },
   {
    "box": {
     "id": "obj-33",
     "maxclass": "panel",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1500,
      148,
      60,
      40
     ],
     "presentation": 1,
     "presentation_rect": [
      0,
      0,
      826,
      169
     ],
     "background": 1,
     "ignoreclick": 1,
     "bgcolor": [
      0.0863,
      0.0745,
      0.0588,
      1.0
     ],
     "bgfillcolor_type": "color",
     "bgfillcolor_color": [
      0.0863,
      0.0745,
      0.0588,
      1.0
     ],
     "border": 0,
     "bordercolor": [
      0.0863,
      0.0745,
      0.0588,
      1.0
     ],
     "rounded": 0
    }
   },
   {
    "box": {
     "id": "obj-34",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      146,
      150,
      18
     ],
     "text": "Panel images not found: keep the fisher_*.png files next to the .amxd, or Freeze the device in Max.",
     "presentation": 1,
     "presentation_rect": [
      12,
      60,
      600,
      16
     ],
     "fontsize": 9,
     "fontname": "Arial",
     "textcolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "background": 1
    }
   },
   {
    "box": {
     "id": "obj-35",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      0,
      120,
      30
     ],
     "presentation": 1,
     "presentation_rect": [
      0,
      0,
      826,
      169
     ],
     "pic": "fisher_faceplate.png",
     "autofit": 0,
     "background": 1
    }
   },
   {
    "box": {
     "id": "obj-36",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      190,
      150,
      18
     ],
     "text": "CORE",
     "presentation": 1,
     "presentation_rect": [
      12,
      6,
      146,
      16
     ],
     "fontsize": 9,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-37",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      50,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      22.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-38",
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
      13,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Drive",
       "parameter_shortname": "Drive",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        25.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Drive",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-39",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      50,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
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
      2080,
      50,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-41",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      150,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-42",
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
     "id": "obj-43",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      80,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      72.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
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
      63,
      26,
      44,
      48
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
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
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
      1760,
      80,
      300,
      22
     ],
     "text": "expr -int(pow(max(0., min(1., ($f1 - 0.3) / 7.7)), 0.5) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-46",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      80,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-47",
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
     "id": "obj-48",
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
     "id": "obj-49",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      110,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      122.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-50",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      580,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      113,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Tone",
       "parameter_shortname": "Tone",
       "parameter_type": 0,
       "parameter_mmin": -100.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Tone",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-51",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      110,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - -100.0) / 200.0)) * 100. + 0.5) * 26"
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
      2080,
      110,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-53",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      370,
      930,
      50,
      22
     ],
     "text": "* 0.01"
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
     "id": "obj-55",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      140,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      22.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-56",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      940,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      13,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Damping",
       "parameter_shortname": "Damping",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        80.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Damping",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-57",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      140,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-58",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      140,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-59",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      480,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-60",
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
     "id": "obj-61",
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
     "id": "obj-62",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      170,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      72.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-63",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      160,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      63,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Mix",
       "parameter_shortname": "Mix",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        35.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Mix",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-64",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      170,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
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
      2080,
      170,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-66",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      590,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-67",
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
     "id": "obj-68",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      200,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      122.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
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
      113,
      88,
      44,
      48
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
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
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
      1760,
      200,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - -24.0) / 30.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-71",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      200,
      110,
      22
     ],
     "text": "prepend offset 0"
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
     "id": "obj-73",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      404,
      150,
      18
     ],
     "text": "SPRING",
     "presentation": 1,
     "presentation_rect": [
      176,
      6,
      146,
      16
     ],
     "fontsize": 9,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-74",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      230,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      186.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
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
      177,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Boing",
       "parameter_shortname": "Boing",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        40.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Boing",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
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
      1760,
      230,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-77",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      230,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-78",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      810,
      930,
      50,
      22
     ],
     "text": "* 0.01"
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
     "id": "obj-80",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      260,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      236.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-81",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      40,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      227,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Tension",
       "parameter_shortname": "Tension",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        44.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Tension",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-82",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      260,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
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
      2080,
      260,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-84",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      920,
      930,
      50,
      22
     ],
     "text": "* 0.01"
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
     "id": "obj-86",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      290,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      286.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-87",
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
      277,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Dispersion",
       "parameter_shortname": "Disperse",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        55.00000000000001
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Dispersion",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-88",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      290,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-89",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      290,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-90",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1030,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-91",
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
     "id": "obj-92",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      320,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      186.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-93",
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
      177,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Resonance",
       "parameter_shortname": "Reso",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        35.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Resonance",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-94",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      320,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-95",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      320,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-96",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1140,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-97",
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
     "id": "obj-98",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      350,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      236.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-99",
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
      227,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Movement",
       "parameter_shortname": "Motion",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        30.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Movement",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-100",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      350,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-101",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      350,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-102",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1250,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-103",
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
     "id": "obj-104",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      486,
      150,
      18
     ],
     "text": "HYBRID",
     "presentation": 1,
     "presentation_rect": [
      340,
      6,
      146,
      16
     ],
     "fontsize": 9,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-105",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      380,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      350.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-106",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      340,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      341,
      88,
      44,
      48
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
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-107",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      380,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - -24.0) / 30.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-108",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      380,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-109",
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
     "id": "obj-110",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      410,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      400.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-111",
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
      391,
      88,
      44,
      48
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
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-112",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      410,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - -24.0) / 30.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-113",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      410,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-114",
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
     "id": "obj-115",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      440,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      450.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-116",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      940,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      441,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Hybrid Blend",
       "parameter_shortname": "Blend",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        50.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Hybrid Blend",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-117",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      440,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-118",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      440,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-119",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1580,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-120",
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
     "id": "obj-121",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      260,
      150,
      18
     ],
     "text": "ENGINE",
     "presentation": 1,
     "presentation_rect": [
      341,
      26,
      80,
      14
     ],
     "fontsize": 8,
     "fontname": "Arial",
     "textcolor": [
      0.2902,
      0.2157,
      0.1294,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-122",
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
      341,
      41,
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
     },
     "bgcolor": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "activebgcolor": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "textcolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "tricolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "bordercolor": [
      0.3529,
      0.2745,
      0.1882,
      1.0
     ],
     "focusbordercolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "fontsize": 9.0
    }
   },
   {
    "box": {
     "id": "obj-123",
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
     "id": "obj-124",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      326,
      150,
      18
     ],
     "text": "DUB",
     "presentation": 1,
     "presentation_rect": [
      504,
      6,
      146,
      16
     ],
     "fontsize": 9,
     "fontname": "Arial Bold",
     "textcolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-125",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      470,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      514.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-126",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      340,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      505,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Feedback",
       "parameter_shortname": "Feedback",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Feedback",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "focusbordercolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-127",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      470,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-128",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      470,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-129",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1800,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-130",
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
     "id": "obj-131",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      500,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      564.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-132",
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
      555,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FB Tone",
       "parameter_shortname": "FB Tone",
       "parameter_type": 0,
       "parameter_mmin": -100.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "FB Tone",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "focusbordercolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-133",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      500,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - -100.0) / 200.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-134",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      500,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-135",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1910,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-136",
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
     "id": "obj-137",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      530,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      614.0,
      39.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-138",
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
      605,
      26,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FB Drive",
       "parameter_shortname": "FB Drive",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        20.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "FB Drive",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "focusbordercolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-139",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      530,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-140",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      530,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-141",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2020,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-142",
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
     "id": "obj-143",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      560,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      514.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-144",
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
      505,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FB Damping",
       "parameter_shortname": "FB Damp",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        30.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "FB Damping",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "focusbordercolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-145",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      560,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-146",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      560,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-147",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2130,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-148",
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
     "id": "obj-149",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      590,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      564.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-150",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      580,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      555,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Self-Osc",
       "parameter_shortname": "Self-Osc",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        0.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Self-Osc",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "focusbordercolor": [
      0.6039,
      0.2039,
      0.0706,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-151",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      590,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-152",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      590,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-153",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2240,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-154",
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
     "id": "obj-155",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      408,
      150,
      18
     ],
     "text": "ADVANCED",
     "presentation": 1,
     "presentation_rect": [
      668,
      6,
      146,
      16
     ],
     "fontsize": 9,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-156",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      620,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      678.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-157",
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
      669,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Pre-delay",
       "parameter_shortname": "Pre-Dly",
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
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-158",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      620,
      300,
      22
     ],
     "text": "expr -int(pow(max(0., min(1., ($f1 - 0.0) / 250.0)), 0.5) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-159",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      620,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-160",
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
     "id": "obj-161",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      650,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      728.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-162",
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
      719,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Width",
       "parameter_shortname": "Width",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 200.0,
       "parameter_initial": [
        100.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Width",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-163",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      650,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 200.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-164",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      650,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-165",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2460,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-166",
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
     "id": "obj-167",
     "maxclass": "fpic",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1700,
      680,
      26,
      26
     ],
     "presentation": 1,
     "presentation_rect": [
      778.0,
      101.0,
      26,
      26
     ],
     "pic": "fisher_knob_fs.png",
     "autofit": 0
    }
   },
   {
    "box": {
     "id": "obj-168",
     "maxclass": "live.dial",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "",
      "float"
     ],
     "patching_rect": [
      460,
      900,
      44,
      48
     ],
     "parameter_enable": 1,
     "presentation": 1,
     "presentation_rect": [
      769,
      88,
      44,
      48
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Modulation",
       "parameter_shortname": "Mod",
       "parameter_type": 0,
       "parameter_mmin": 0.0,
       "parameter_mmax": 100.0,
       "parameter_initial": [
        15.0
       ],
       "parameter_initial_enable": 1,
       "parameter_unitstyle": 5,
       "parameter_modmode": 0
      }
     },
     "varname": "Modulation",
     "showname": 1,
     "shownumber": 1,
     "fontsize": 9.0,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "triangle": 0,
     "activedialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "dialcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "activeneedlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "needlecolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "tricolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-169",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      1760,
      680,
      300,
      22
     ],
     "text": "expr -int(max(0., min(1., ($f1 - 0.0) / 100.0)) * 100. + 0.5) * 26"
    }
   },
   {
    "box": {
     "id": "obj-170",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2080,
      680,
      110,
      22
     ],
     "text": "prepend offset 0"
    }
   },
   {
    "box": {
     "id": "obj-171",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      2570,
      930,
      50,
      22
     ],
     "text": "* 0.01"
    }
   },
   {
    "box": {
     "id": "obj-172",
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
     "id": "obj-173",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      204,
      150,
      18
     ],
     "text": "IMPULSE RESPONSE",
     "presentation": 1,
     "presentation_rect": [
      669,
      22,
      144,
      14
     ],
     "fontsize": 8,
     "fontname": "Arial",
     "textcolor": [
      0.2902,
      0.2157,
      0.1294,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-174",
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
      669,
      36,
      144,
      18
     ],
     "varname": "IR",
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "IR",
       "parameter_shortname": "IR",
       "parameter_type": 2,
       "parameter_enum": [
        "Fisher K-10",
        "Bird-Verb Deluxe",
        "Bird-Verb Supro",
        "Fender Deluxe",
        "Supro",
        "70s Stereo Spring",
        "Silver Face Spring",
        "Spring + Webcor",
        "Synthetic Dark Tank",
        "Synthetic K-10 Spec",
        "Synthetic Long Tank",
        "Synthetic Short Tank",
        "Synthetic Splash",
        "User IR"
       ],
       "parameter_mmax": 13,
       "parameter_initial": [
        0
       ],
       "parameter_initial_enable": 1,
       "parameter_modmode": 0
      }
     },
     "bgcolor": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "activebgcolor": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "textcolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "tricolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "bordercolor": [
      0.3529,
      0.2745,
      0.1882,
      1.0
     ],
     "focusbordercolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "fontsize": 9.0
    }
   },
   {
    "box": {
     "id": "obj-175",
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
     "id": "obj-176",
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
      669,
      58,
      144,
      22
     ],
     "parameter_enable": 0,
     "legend": "Drop your own IR (WAV)",
     "fontsize": 8.0,
     "bgcolor": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "bordercolor": [
      0.3529,
      0.2745,
      0.1882,
      1.0
     ],
     "textcolor": [
      0.9137,
      0.8627,
      0.7686,
      1.0
     ],
     "focusbordercolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-177",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      292,
      150,
      18
     ],
     "text": "FISHER SPRING",
     "presentation": 1,
     "presentation_rect": [
      8,
      151,
      104,
      16
     ],
     "fontsize": 11,
     "fontname": "Arial Bold",
     "textcolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-178",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      314,
      150,
      18
     ],
     "text": "ECHOLIVITY",
     "presentation": 1,
     "presentation_rect": [
      116,
      153,
      66,
      14
     ],
     "fontsize": 8,
     "fontname": "Arial",
     "textcolor": [
      0.2902,
      0.2157,
      0.1294,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-179",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      600,
      380,
      300,
      18
     ],
     "text": "no IR loaded",
     "presentation": 1,
     "presentation_rect": [
      190,
      153,
      400,
      14
     ],
     "fontsize": 8.0,
     "fontname": "Arial",
     "textcolor": [
      0.2902,
      0.2157,
      0.1294,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-180",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      1300,
      358,
      150,
      18
     ],
     "text": "PRESET",
     "presentation": 1,
     "presentation_rect": [
      590,
      153,
      44,
      14
     ],
     "fontsize": 8,
     "fontname": "Arial Bold",
     "textcolor": [
      0.2902,
      0.2157,
      0.1294,
      1.0
     ],
     "fontface": 1
    }
   },
   {
    "box": {
     "id": "obj-181",
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
      636,
      151,
      184,
      17
     ],
     "items": [
      "Load",
      "a",
      "preset...",
      ",",
      "01",
      "Fisher",
      "Reference",
      ",",
      "02",
      "Vintage",
      "Splash",
      ",",
      "03",
      "Deep",
      "Dub",
      "Spring",
      ",",
      "04",
      "Metallic",
      "Resonance",
      ",",
      "05",
      "Heavy",
      "Pressure",
      ",",
      "06",
      "Dark",
      "Chamber",
      ",",
      "07",
      "Infinite",
      "Dub",
      ",",
      "08",
      "Broken",
      "Spring",
      ",",
      "09",
      "Short",
      "Percussion",
      "Spring",
      ",",
      "10",
      "Experimental",
      "Mechanical"
     ],
     "fontsize": 9.0,
     "arrow": 1,
     "bgcolor": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "bgfillcolor_type": "color",
     "bgfillcolor_color": [
      0.0627,
      0.051,
      0.0392,
      1.0
     ],
     "textcolor": [
      0.1412,
      0.0941,
      0.0471,
      1.0
     ],
     "elementcolor": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ],
     "color": [
      0.1176,
      0.0784,
      0.0392,
      1.0
     ]
    }
   },
   {
    "box": {
     "id": "obj-182",
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
     "text": "sel 1 2 3 4 5 6 7 8 9 10"
    }
   },
   {
    "box": {
     "id": "obj-183",
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
     "id": "obj-184",
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
     "text": "drive 15.0, decay 8.0, tone 0.0, damping 0.0, mix 100.0, output -2.0, boing 40.0, tension 44.0, dispersion 55.0, resonance 35.0, movement 30.0, ir_level 0.0, model_level 0.0, blend 50.0, engine_mode 0, feedback 0.0, fb_tone 0.0, fb_drive 20.0, fb_damping 30.0, self_osc 0.0, predelay 0, width 100.0, modulation 15.0, ir 0"
    }
   },
   {
    "box": {
     "id": "obj-185",
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
     "text": "drive 35.0, decay 2.2, tone 35.0, damping 15.0, mix 40.0, output -3.0, boing 80.0, tension 55.0, dispersion 70.0, resonance 30.0, movement 25.0, ir_level 0.0, model_level 0.0, blend 45.0, engine_mode 2, feedback 0.0, fb_tone 0.0, fb_drive 20.0, fb_damping 30.0, self_osc 0.0, predelay 0.0, width 100.0, modulation 15.0, ir 3"
    }
   },
   {
    "box": {
     "id": "obj-186",
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
     "text": "drive 30.0, decay 3.5, tone -25.0, damping 45.0, mix 100.0, output -6.0, boing 55.0, tension 35.0, dispersion 60.0, resonance 40.0, movement 30.0, ir_level 0.0, model_level 0.0, blend 40.0, engine_mode 2, feedback 45.0, fb_tone -20.0, fb_drive 30.0, fb_damping 40.0, self_osc 0.0, predelay 12, width 100.0, modulation 15.0, ir 0"
    }
   },
   {
    "box": {
     "id": "obj-187",
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
     "text": "drive 20.0, decay 4.5, tone 20.0, damping 10.0, mix 40.0, output 0.0, boing 30.0, tension 70.0, dispersion 90.0, resonance 95.0, movement 15.0, ir_level 0.0, model_level 0.0, blend 50.0, engine_mode 1, feedback 0.0, fb_tone 0.0, fb_drive 20.0, fb_damping 30.0, self_osc 0.0, predelay 0.0, width 100.0, modulation 10.0, ir 11"
    }
   },
   {
    "box": {
     "id": "obj-188",
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
     "text": "drive 85.0, decay 2.8, tone -10.0, damping 50.0, mix 45.0, output -4.0, boing 50.0, tension 40.0, dispersion 50.0, resonance 50.0, movement 35.0, ir_level 0.0, model_level 0.0, blend 60.0, engine_mode 4, feedback 60.0, fb_tone -30.0, fb_drive 80.0, fb_damping 35.0, self_osc 0.0, predelay 0.0, width 100.0, modulation 15.0, ir 8"
    }
   },
   {
    "box": {
     "id": "obj-189",
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
     "text": "drive 10.0, decay 3.0, tone -55.0, damping 75.0, mix 35.0, output -4.0, boing 10.0, tension 25.0, dispersion 40.0, resonance 15.0, movement 10.0, ir_level 0.0, model_level 0.0, blend 30.0, engine_mode 2, feedback 0.0, fb_tone 0.0, fb_drive 20.0, fb_damping 30.0, self_osc 0.0, predelay 25, width 130.0, modulation 25.0, ir 8"
    }
   },
   {
    "box": {
     "id": "obj-190",
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
     "text": "drive 30.0, decay 6.0, tone -10.0, damping 35.0, mix 100.0, output -6.0, boing 45.0, tension 45.0, dispersion 60.0, resonance 45.0, movement 30.0, ir_level 0.0, model_level 0.0, blend 50.0, engine_mode 2, feedback 100.0, fb_tone 0.0, fb_drive 45.0, fb_damping 50.0, self_osc 35.0, predelay 0.0, width 100.0, modulation 15.0, ir 0"
    }
   },
   {
    "box": {
     "id": "obj-191",
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
     "text": "drive 55.0, decay 2.0, tone 10.0, damping 30.0, mix 50.0, output -5.0, boing 100.0, tension 30.0, dispersion 80.0, resonance 60.0, movement 100.0, ir_level 0.0, model_level 0.0, blend 75.0, engine_mode 3, feedback 30.0, fb_tone 0.0, fb_drive 50.0, fb_damping 30.0, self_osc 0.0, predelay 0.0, width 100.0, modulation 40.0, ir 12"
    }
   },
   {
    "box": {
     "id": "obj-192",
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
     "text": "drive 15.0, decay 0.7, tone 30.0, damping 25.0, mix 30.0, output 0.0, boing 35.0, tension 85.0, dispersion 45.0, resonance 25.0, movement 15.0, ir_level 0.0, model_level 0.0, blend 35.0, engine_mode 2, feedback 0.0, fb_tone 0.0, fb_drive 20.0, fb_damping 30.0, self_osc 0.0, predelay 0.0, width 140.0, modulation 15.0, ir 5"
    }
   },
   {
    "box": {
     "id": "obj-193",
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
     "text": "drive 60.0, decay 5.0, tone 0.0, damping 20.0, mix 50.0, output -6.0, boing 70.0, tension 15.0, dispersion 100.0, resonance 80.0, movement 60.0, ir_level 0.0, model_level 0.0, blend 50.0, engine_mode 4, feedback 75.0, fb_tone 40.0, fb_drive 70.0, fb_damping 20.0, self_osc 15.0, predelay 0.0, width 160.0, modulation 80.0, ir 8"
    }
   },
   {
    "box": {
     "id": "obj-194",
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
      "obj-31",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-31",
      2
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
      "obj-32",
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
      "obj-31",
      1
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
      "obj-31",
      1
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
      "obj-38",
      0
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
      "obj-37",
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
      "obj-42",
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
      "obj-2",
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
      "obj-46",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-46",
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
      "obj-44",
      0
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
      "obj-47",
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
      "obj-12",
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
      "obj-51",
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
      "obj-49",
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
      "obj-53",
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
      "obj-56",
      0
     ],
     "destination": [
      "obj-57",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-57",
      0
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
      "obj-58",
      0
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
      "obj-56",
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
      "obj-60",
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
      "obj-4",
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
      "obj-12",
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
      "obj-64",
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
      "obj-62",
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
      "obj-66",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-66",
      0
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
      "obj-67",
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
      "obj-71",
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
      "obj-68",
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
      "obj-77",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-77",
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
      "obj-75",
      0
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
      "obj-4",
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
      "obj-82",
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
      "obj-80",
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
      "obj-84",
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
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-87",
      0
     ],
     "destination": [
      "obj-88",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-88",
      0
     ],
     "destination": [
      "obj-89",
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
      "obj-86",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-87",
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
      "obj-90",
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
      "obj-91",
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
      "obj-93",
      0
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
      "obj-92",
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
      "obj-4",
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
      "obj-98",
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
      "obj-102",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-102",
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
      "obj-4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-106",
      0
     ],
     "destination": [
      "obj-107",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-107",
      0
     ],
     "destination": [
      "obj-108",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-108",
      0
     ],
     "destination": [
      "obj-105",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-106",
      0
     ],
     "destination": [
      "obj-109",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-109",
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
      "obj-111",
      0
     ],
     "destination": [
      "obj-112",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-112",
      0
     ],
     "destination": [
      "obj-113",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-113",
      0
     ],
     "destination": [
      "obj-110",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-111",
      0
     ],
     "destination": [
      "obj-114",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-114",
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
      "obj-116",
      0
     ],
     "destination": [
      "obj-117",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-117",
      0
     ],
     "destination": [
      "obj-118",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-118",
      0
     ],
     "destination": [
      "obj-115",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-116",
      0
     ],
     "destination": [
      "obj-119",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-119",
      0
     ],
     "destination": [
      "obj-120",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-120",
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
      "obj-122",
      0
     ],
     "destination": [
      "obj-123",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-123",
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
      "obj-123",
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
      "obj-126",
      0
     ],
     "destination": [
      "obj-127",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-127",
      0
     ],
     "destination": [
      "obj-128",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-128",
      0
     ],
     "destination": [
      "obj-125",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-126",
      0
     ],
     "destination": [
      "obj-129",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-129",
      0
     ],
     "destination": [
      "obj-130",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-130",
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
      "obj-132",
      0
     ],
     "destination": [
      "obj-133",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-133",
      0
     ],
     "destination": [
      "obj-134",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-134",
      0
     ],
     "destination": [
      "obj-131",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-132",
      0
     ],
     "destination": [
      "obj-135",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-135",
      0
     ],
     "destination": [
      "obj-136",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-136",
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
      "obj-138",
      0
     ],
     "destination": [
      "obj-139",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-139",
      0
     ],
     "destination": [
      "obj-140",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-140",
      0
     ],
     "destination": [
      "obj-137",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-138",
      0
     ],
     "destination": [
      "obj-141",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-141",
      0
     ],
     "destination": [
      "obj-142",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-142",
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
      "obj-144",
      0
     ],
     "destination": [
      "obj-145",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-145",
      0
     ],
     "destination": [
      "obj-146",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-146",
      0
     ],
     "destination": [
      "obj-143",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-144",
      0
     ],
     "destination": [
      "obj-147",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-147",
      0
     ],
     "destination": [
      "obj-148",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-148",
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
      "obj-150",
      0
     ],
     "destination": [
      "obj-151",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-151",
      0
     ],
     "destination": [
      "obj-152",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-152",
      0
     ],
     "destination": [
      "obj-149",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-150",
      0
     ],
     "destination": [
      "obj-153",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-153",
      0
     ],
     "destination": [
      "obj-154",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-154",
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
      "obj-157",
      0
     ],
     "destination": [
      "obj-158",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-158",
      0
     ],
     "destination": [
      "obj-159",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-159",
      0
     ],
     "destination": [
      "obj-156",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-157",
      0
     ],
     "destination": [
      "obj-160",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-160",
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
      "obj-162",
      0
     ],
     "destination": [
      "obj-163",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-163",
      0
     ],
     "destination": [
      "obj-164",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-164",
      0
     ],
     "destination": [
      "obj-161",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-162",
      0
     ],
     "destination": [
      "obj-165",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-165",
      0
     ],
     "destination": [
      "obj-166",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-166",
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
      "obj-168",
      0
     ],
     "destination": [
      "obj-169",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-169",
      0
     ],
     "destination": [
      "obj-170",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-170",
      0
     ],
     "destination": [
      "obj-167",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-168",
      0
     ],
     "destination": [
      "obj-171",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-171",
      0
     ],
     "destination": [
      "obj-172",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-172",
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
      "obj-174",
      0
     ],
     "destination": [
      "obj-175",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-175",
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
      "obj-174",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-176",
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
      "obj-179",
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
      "obj-179",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-181",
      0
     ],
     "destination": [
      "obj-182",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
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
      "obj-183",
      1
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
      "obj-183",
      2
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
      "obj-183",
      3
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
      "obj-183",
      4
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
      "obj-183",
      5
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
      "obj-183",
      6
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
      "obj-183",
      7
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
      "obj-183",
      8
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
      "obj-183",
      9
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
      "obj-183",
      10
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
      "obj-183",
      11
     ],
     "destination": [
      "obj-106",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      12
     ],
     "destination": [
      "obj-111",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      13
     ],
     "destination": [
      "obj-116",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      14
     ],
     "destination": [
      "obj-122",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      15
     ],
     "destination": [
      "obj-126",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      16
     ],
     "destination": [
      "obj-132",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      17
     ],
     "destination": [
      "obj-138",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      18
     ],
     "destination": [
      "obj-144",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      19
     ],
     "destination": [
      "obj-150",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      20
     ],
     "destination": [
      "obj-157",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      21
     ],
     "destination": [
      "obj-162",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      22
     ],
     "destination": [
      "obj-168",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-183",
      23
     ],
     "destination": [
      "obj-174",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      0
     ],
     "destination": [
      "obj-184",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-184",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      1
     ],
     "destination": [
      "obj-185",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-185",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      2
     ],
     "destination": [
      "obj-186",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-186",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      3
     ],
     "destination": [
      "obj-187",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-187",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      4
     ],
     "destination": [
      "obj-188",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-188",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      5
     ],
     "destination": [
      "obj-189",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-189",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      6
     ],
     "destination": [
      "obj-190",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-190",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      7
     ],
     "destination": [
      "obj-191",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-191",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      8
     ],
     "destination": [
      "obj-192",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-192",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-182",
      9
     ],
     "destination": [
      "obj-193",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-193",
      0
     ],
     "destination": [
      "obj-183",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-31",
      0
     ],
     "destination": [
      "obj-194",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-194",
      0
     ],
     "destination": [
      "obj-174",
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
    "name": "fisher_faceplate.png",
    "type": "PNG",
    "implicit": 1
   },
   {
    "name": "fisher_knob_fs.png",
    "type": "PNG",
    "implicit": 1
   },
   {
    "name": "fisher_faceplate@2x.png",
    "type": "PNG",
    "implicit": 1
   },
   {
    "name": "fisher_knob_fs@2x.png",
    "type": "PNG",
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
   "obj-38": [
    "Drive",
    "Drive",
    0
   ],
   "obj-44": [
    "Decay",
    "Decay",
    0
   ],
   "obj-50": [
    "Tone",
    "Tone",
    0
   ],
   "obj-56": [
    "Damping",
    "Damping",
    0
   ],
   "obj-63": [
    "Mix",
    "Mix",
    0
   ],
   "obj-69": [
    "Output",
    "Output",
    0
   ],
   "obj-75": [
    "Boing",
    "Boing",
    0
   ],
   "obj-81": [
    "Tension",
    "Tension",
    0
   ],
   "obj-87": [
    "Dispersion",
    "Disperse",
    0
   ],
   "obj-93": [
    "Resonance",
    "Reso",
    0
   ],
   "obj-99": [
    "Movement",
    "Motion",
    0
   ],
   "obj-106": [
    "IR Level",
    "IR",
    0
   ],
   "obj-111": [
    "Model Level",
    "Model",
    0
   ],
   "obj-116": [
    "Hybrid Blend",
    "Blend",
    0
   ],
   "obj-122": [
    "Engine Mode",
    "Engine",
    0
   ],
   "obj-126": [
    "Feedback",
    "Feedback",
    0
   ],
   "obj-132": [
    "FB Tone",
    "FB Tone",
    0
   ],
   "obj-138": [
    "FB Drive",
    "FB Drive",
    0
   ],
   "obj-144": [
    "FB Damping",
    "FB Damp",
    0
   ],
   "obj-150": [
    "Self-Osc",
    "Self-Osc",
    0
   ],
   "obj-157": [
    "Pre-delay",
    "Pre-Dly",
    0
   ],
   "obj-162": [
    "Width",
    "Width",
    0
   ],
   "obj-168": [
    "Modulation",
    "Mod",
    0
   ],
   "obj-174": [
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