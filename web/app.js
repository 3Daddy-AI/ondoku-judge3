import { normalizeForAlignment, levenshteinAlignment, previewOps } from './alignment.js';
import { analyzeRMSAndPauses, charsPerMinute, scoreFromMetrics } from './features.js';
import { makeASR } from './asr.js';

const refs={
  refText: document.getElementById('refText'),
  refFile: document.getElementById('refFile'),
  startBtn: document.getElementById('startBtn'),
  stopBtn: document.getElementById('stopBtn'),
  status: document.getElementById('status'),
  hypText: document.getElementById('hypText'),
  result: document.getElementById('result'),
  diff: document.getElementById('diff'),
  asrMode: document.getElementById('asrMode'),
  grade: document.getElementById('grade'),
  modelUrl: document.getElementById('modelUrl'),
  loadModelBtn: document.getElementById('loadModelBtn'),
  exportJson: document.getElementById('exportJson')
};

let mediaStream=null; let meter=null; let lastStats={durationSec:0,rmsDb:0,pauses:0,maxPauseSec:0};
const asr = makeASR();

refs.refFile.addEventListener('change', async e=>{
  const f = e.target.files?.[0]; if(!f) return; const t = await f.text(); refs.refText.value=t;
});

refs.asrMode.addEventListener('change', async ()=>{
  await asr.setMode(refs.asrMode.value);
});

refs.loadModelBtn.addEventListener('click', async ()=>{
  if(refs.asrMode.value!=='vosk') { alert('WebSpeechはモデル不要'); return; }
  if(!refs.modelUrl.value) { alert('モデルURLを入力してください'); return; }
  refs.status.textContent='モデル読み込み中…';
  try{ await asr.loadVoskModel(refs.modelUrl.value); refs.status.textContent='モデル準備OK'; }
  catch(err){ console.error(err); alert('モデル読み込みエラー: '+err); refs.status.textContent=''; }
});

refs.startBtn.addEventListener('click', async ()=>{
  const ref = refs.refText.value.trim(); if(!ref){ alert('課題文を入力してください'); return; }
  refs.result.innerHTML=''; refs.diff.innerHTML=''; refs.hypText.textContent='';
  try{
    mediaStream = await navigator.mediaDevices.getUserMedia({audio:true});
  }catch(err){ alert('マイクが使えません: '+err); return; }
  meter = analyzeRMSAndPauses(mediaStream, s=>{ lastStats=s; });
  refs.status.textContent='よみあげ中…';
  refs.startBtn.disabled=true; refs.stopBtn.disabled=false;
  try{
    await asr.setMode(refs.asrMode.value);
    await asr.start(mediaStream, txt=>{ refs.hypText.textContent=txt; });
  }catch(err){ console.error(err); alert('ASR開始エラー: '+err); }
});

refs.stopBtn.addEventListener('click', async ()=>{
  refs.stopBtn.disabled=true;
  if(meter){ meter.stop(); meter=null; }
  mediaStream?.getTracks()?.forEach(t=>t.stop());
  const hyp = await asr.stop();
  finalize(hyp);
  refs.startBtn.disabled=false; refs.status.textContent='';
});

function finalize(hyp){
  const ref = refs.refText.value.trim();
  const nr = normalizeForAlignment(ref);
  const nh = normalizeForAlignment(hyp||'');
  const ali = levenshteinAlignment(nr, nh);
  const cpm = charsPerMinute(ali.refLen, lastStats.durationSec);
  const range = speedRange(refs.grade.value);
  const weights = [0.7,0.2,0.1];
  const scores = scoreFromMetricsWithConfig(ali.cer, cpm, lastStats.pauses, range, weights);
  const prev = previewOps(ali.ops);
  renderResult(ali, scores, cpm, prev);
  lastResultPayload = makePayload(ref, hyp, ali, prev, lastStats, cpm, scores, refs.grade.value);
}

function renderResult(ali, scores, cpm, preview){
  const star = (v)=> v>=90?3 : v>=75?2 : v>=60?1 : 0;
  const stars = star(scores.overallScore);
  refs.result.innerHTML = [
    badge(`🌟 x${stars}`),
    chip(`CER: ${(ali.cer).toFixed(3)} (errors=${ali.errors}/${ali.refLen})`),
    chip(`速度: ${cpm.toFixed(1)} chars/min`),
    chip(`ポーズ: ${lastStats.pauses} (最長 ${lastStats.maxPauseSec.toFixed(2)}s)`),
    chip(`音量(RMS dB): ${lastStats.rmsDb.toFixed(1)}`),
    chip(`総合: ${scores.overallScore} / 正確さ: ${scores.accuracyScore} / 速度: ${scores.speedScore} / ポーズ: ${scores.pauseScore}`)
  ].join('');
  refs.diff.innerHTML = colorize(preview);
}

function badge(text){ return `<span class="badge">${escapeHtml(text)}</span>` }
function chip(text){ return `<span class="score">${escapeHtml(text)}</span>` }

function colorize(pre){
  // [a->b] = d-rep, (+x)=d-ins, (-y)=d-del, others d-eq
  let out='';
  for(let i=0;i<pre.length;i++){
    const c=pre[i];
    if(c==='['){ const j=pre.indexOf(']',i+1); const seg=pre.slice(i,j+1); out+=`<span class="d-rep">${escapeHtml(seg)}</span>`; i=j; continue; }
    if(c==='('){ const j=pre.indexOf(')',i+1); const seg=pre.slice(i,j+1); const cls=pre[i+1]==='+'?'d-ins':'d-del'; out+=`<span class="${cls}">${escapeHtml(seg)}</span>`; i=j; continue; }
    out+=`<span class="d-eq">${escapeHtml(c)}</span>`;
  }
  return out;
}

function escapeHtml(s){ return s.replace(/[&<>"']/g, m=>({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"}[m])) }

// PWA
if('serviceWorker' in navigator){
  navigator.serviceWorker.register('./sw.js').catch(()=>{});
}

// 学年レンジと拡張スコア
function speedRange(grade){
  switch(grade){
    case 'g1': return [120,220];
    case 'g2': return [150,260];
    case 'g3': return [180,300];
    case 'g4': return [200,330];
    case 'g5': return [220,360];
    case 'g6': return [240,380];
    default: return [180,300];
  }
}
function scoreFromMetricsWithConfig(cer,cpm,pauses,range,weights){
  const s = scoreFromMetrics(cer,cpm,pauses);
  // 差し替え: rangeとweightsで再計算
  const [low,high]=range; let spd; if(cpm>=low&&cpm<=high)spd=100; else if(cpm<low)spd=Math.max(0,100-(low-cpm)*0.5); else spd=Math.max(0,100-(cpm-high)*0.5);
  const pausePenalty=Math.min(10,Math.max(0,pauses));
  const pauseScore=Math.max(0,100-pausePenalty);
  const overall=weights[0]*(1-cer)*100 + weights[1]*spd + weights[2]*pauseScore;
  return {accuracyScore:Math.round((1-cer)*1000)/10, speedScore:Math.round(spd*10)/10, pauseScore:Math.round(pauseScore*10)/10, overallScore:Math.round(overall*10)/10};
}

// JSONエクスポート
let lastResultPayload=null;
function makePayload(ref, hyp, ali, preview, stats, cpm, scores, grade){
  return {refText:ref, hypText:hyp, normRef:normalizeForAlignment(ref), normHyp:normalizeForAlignment(hyp), cer:+ali.cer.toFixed(4),
    errors:ali.errors, refLen:ali.refLen, alignmentPreview:preview, durationSec:+stats.durationSec.toFixed(3), rmsDb:+stats.rmsDb.toFixed(1),
    pauses:stats.pauses, maxPauseSec:+stats.maxPauseSec.toFixed(2), charsPerMinute:+cpm.toFixed(1), scores,
    grade, timestamp: new Date().toISOString() };
}
refs.exportJson.addEventListener('click', ()=>{
  if(!lastResultPayload){ alert('結果がありません'); return; }
  const blob = new Blob([JSON.stringify(lastResultPayload,null,2)], {type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download='ondoku_result.json'; a.click(); URL.revokeObjectURL(a.href);
});
