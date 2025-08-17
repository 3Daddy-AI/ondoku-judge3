export function analyzeRMSAndPauses(stream, onStats){
  const ctx = new (window.AudioContext||window.webkitAudioContext)({ sampleRate: 16000 });
  const src = ctx.createMediaStreamSource(stream);
  const proc = ctx.createScriptProcessor(1024, 1, 1);
  let samples = 0; let sumsq = 0;
  let pauses=0, maxPause=0, curPause=0;
  const sr = ctx.sampleRate; const frame= Math.round(0.02*sr); const hop=Math.round(0.01*sr);
  let buf = new Float32Array(0);
  src.connect(proc); proc.connect(ctx.destination);
  const start = performance.now();
  proc.onaudioprocess = e => {
    const x = e.inputBuffer.getChannelData(0);
    // accumulate stats
    for(let i=0;i<x.length;i++){ const v=x[i]; sumsq+=v*v; samples++; }
    // slide for pauses
    const merged = new Float32Array(buf.length + x.length);
    merged.set(buf,0); merged.set(x,buf.length); buf=merged;
    while(buf.length>=frame){
      const seg=buf.subarray(0,frame);
      let s=0; for(let i=0;i<frame;i++) s+=seg[i]*seg[i];
      const energy = Math.sqrt(s/frame);
      if(energy < 0.01){ curPause++; } else { if(curPause*hop/sr>=0.5) pauses++; if(curPause>maxPause) maxPause=curPause; curPause=0; }
      buf = buf.subarray(hop);
    }
    const dur = (performance.now()-start)/1000;
    const rms = 20*Math.log10(Math.max(1e-12, Math.sqrt(sumsq/Math.max(1,samples))));
    onStats({durationSec: dur, rmsDb: rms, pauses, maxPauseSec: maxPause*hop/sr});
  };
  return { stop(){ proc.disconnect(); src.disconnect(); ctx.close(); } };
}

export function charsPerMinute(refLen, durationSec){
  if(!durationSec) return 0; return 60*refLen/durationSec;
}

export function scoreFromMetrics(cer,cpm,pauses){
  const acc=Math.max(0,Math.min(100,(1-cer)*100));
  const low=200, high=350; let spd;
  if(cpm>=low && cpm<=high) spd=100; else if(cpm<low) spd=Math.max(0,100-(low-cpm)*0.5); else spd=Math.max(0,100-(cpm-high)*0.5);
  const pausePenalty=Math.min(10,Math.max(0,pauses));
  const pauseScore=Math.max(0,100-pausePenalty);
  const overall=0.7*acc+0.2*spd+0.1*pauseScore;
  return {accuracyScore:round1(acc),speedScore:round1(spd),pauseScore:round1(pauseScore),overallScore:round1(overall)};
}

function round1(x){return Math.round(x*10)/10}

