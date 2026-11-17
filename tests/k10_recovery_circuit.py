"""Nodal AC analysis of the Fisher K-10 recovery amplifier (V2a/V2b, 12AX7), from the
Sams Photofact (Folder 12, Set 562) and Fisher manual schematics. Compares the stage with
and without its global feedback (R15 680k || C14 12pF to V2a cathode) against the
long-term spectrum of the K-10 IR. Run: python tests/k10_recovery_circuit.py"""
import numpy as np
mu, ra = 100.0, 62.5e3; gm = mu/ra
f = np.array([63,125,250,500,1000,2000,3000,4000,6000,8000,12000,16000.])
meas = np.array([-25.8,-10.2,-3.9,-0.9,0,-3.1,-5.3,-6.7,-13.6,-20.9,np.nan,np.nan])
def solve(fb=True, RL=200e3):
    out=[]
    for fr in f:
        w=2j*np.pi*fr
        N=['P1','K1','A','B','G2','P2','O']; ix={n:i for i,n in enumerate(N)}
        Y=np.zeros((7,7),complex); I=np.zeros(7,complex)
        def adm(a,b,y):
            if a: Y[ix[a],ix[a]]+=y
            if b: Y[ix[b],ix[b]]+=y
            if a and b: Y[ix[a],ix[b]]-=y; Y[ix[b],ix[a]]-=y
        adm('P1',None,1/330e3); adm('K1',None,1/2700)
        adm('P1','A',w*470e-12); adm('A',None,1/2.2e6)
        adm('A','B',1/100e3); adm('B',None,w*270e-12)
        adm('B','G2',1/100e3); adm('G2',None,w*(270e-12+1.6e-12))
        adm('G2','P2',w*1.7e-12)                       # V2b Miller (Cgp)
        adm('P2',None,1/270e3); adm('P2','O',w*2.7e-9); adm('O',None,1/RL)
        if fb: adm('O','K1',1/680e3+w*12e-12)
        # V2a VCCS P1->K1: i = gm(vin - vK1) + (vP1-vK1)/ra ; vin = 1
        adm('P1','K1',1/ra)
        Y[ix['P1'],ix['K1']]-=gm; Y[ix['K1'],ix['K1']]+=gm
        I[ix['P1']]-=gm; I[ix['K1']]+=gm
        # V2b VCCS P2->gnd: i = gm vG2 + vP2/ra
        adm('P2',None,1/ra); Y[ix['P2'],ix['G2']]+=gm
        v=np.linalg.solve(Y,I); out.append(v[ix['O']])
    return np.array(out)
def rel(h): d=20*np.log10(np.abs(h)); return d-d[list(f).index(1000)]
cl, ol = solve(True), solve(False)
print("mid gain closed %.1f dB, open %.1f dB -> feedback %.1f dB"%(20*np.log10(abs(cl[4])),20*np.log10(abs(ol[4])),20*np.log10(abs(ol[4])/abs(cl[4]))))
s=2j*np.pi*f
feed=(s/(s+2*np.pi*297))*(s/(s+2*np.pi*56))
model=feed*(s/(s+2*np.pi*150))/((1+s/(2*np.pi*2252))*(1+s/(2*np.pi*15400)))
print("Hz        "+" ".join("%6d"%x for x in f))
print("measured  "+" ".join("%6.1f"%x for x in meas))
print("old model "+" ".join("%6.1f"%x for x in rel(model)))
print("feed+OL   "+" ".join("%6.1f"%x for x in rel(feed*ol)))
print("feed+CL   "+" ".join("%6.1f"%x for x in rel(feed*cl)))
print("CL alone  "+" ".join("%6.1f"%x for x in rel(cl)))
m=~np.isnan(meas)
for name,h in [("old model",model),("feed+OL",feed*ol),("feed+CL",feed*cl)]:
    e=rel(h)[m]-meas[m]; lo=f[m]<=4000
    print(f"{name}: rms err <=4k {np.sqrt(np.mean(e[lo]**2)):.1f} dB, all {np.sqrt(np.mean(e**2)):.1f} dB")
for RL in (100e3,500e3): print('RL',RL, " ".join("%6.1f"%x for x in rel(solve(True,RL))))
