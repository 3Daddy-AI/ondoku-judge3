import { normalizeForAlignment, levenshteinAlignment, previewOps } from './alignment.js';
import { charsPerMinute, scoreFromMetrics } from './features.js';

const el = (id)=>document.getElementById(id);
const btnText=el('btnText'), btnPhoto=el('btnPhoto'), btnPDF=el('btnPDF');
const refText=el('refText'), photoInput=el('photoInput'), pdfInput=el('pdfInput');
const ocrStatus=el('ocrStatus'), status=el('status');
const btnRec=el('btnRec'), btnAgain=el('btnAgain');
const speechWarn=el('speechWarn');
const stars=el('stars'), summary=el('summary'), diff=el('diff');

let sr=null; let startT=0; let hyp='';

// pdf.js のワーカーを設定（未設定だとPDFが読めません）
try {
  if (window.pdfjsLib) {
    // バージョンは kids.html のCDNに合わせる
    window.pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';
  }
} catch (e) {
  // no-op
}

// 1) 入力
btnText.addEventListener('click', ()=>{ refText.focus(); });
btnPhoto.addEventListener('click', ()=> photoInput.click());
btnPDF.addEventListener('click', ()=> pdfInput.click());

photoInput.addEventListener('change', async (e)=>{
  const f=e.target.files?.[0]; if(!f) return; resetOCR();
  ocrStatus.textContent='よみとり中（しゃしん）…';
  const imgUrl=URL.createObjectURL(f);
  const { data } = await Tesseract.recognize(imgUrl, 'jpn', { logger: m=>{ /*progress*/ } });
  refText.value = (data.text||'').trim();
  ocrStatus.textContent='よみとり かんりょう！';
});

pdfInput.addEventListener('change', async (e)=>{
  const f=e.target.files?.[0]; if(!f) return; resetOCR();
  try {
    ocrStatus.textContent='よみとり中（PDF）…';
    const array = await f.arrayBuffer();
    const pdf = await pdfjsLib.getDocument({data:array}).promise;
    let all='';
    for(let i=1;i<=pdf.numPages;i++){
      ocrStatus.textContent = `よみとり中（PDF ページ ${i}/${pdf.numPages}）…`;
      const page = await pdf.getPage(i);
      // まずはデジタルテキスト抽出（速い）
      let pageText = '';
      try {
        const tc = await page.getTextContent();
        pageText = (tc.items||[]).map(it=>it.str).join('');
      } catch {}

      if (pageText && pageText.trim().length >= 10) {
        all += '\n' + pageText;
        continue;
      }
      // だめならOCRにフォールバック（重い）
      const viewport = page.getViewport({scale: 1.5});
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      canvas.width = Math.floor(viewport.width);
      canvas.height = Math.floor(viewport.height);
      await page.render({canvasContext:ctx, viewport}).promise;
      const { data } = await Tesseract.recognize(canvas, 'jpn', { logger: m=>{ /* progress */ } });
      all += '\n' + (data.text||'');
    }
    const text = all.trim();
    if (!text) {
      ocrStatus.textContent = 'PDFの よみとりに しっぱいしました。しゃしん で ためすか、べつのPDFで ためしてね。';
    } else {
      refText.value = text;
      ocrStatus.textContent='よみとり かんりょう！';
    }
  } catch (err) {
    console.error(err);
    ocrStatus.textContent = 'PDFを よみこめませんでした（ばーじょん/ほご など）。べつの ほうほうを ためしてね。';
  }
});

function resetOCR(){ ocrStatus.textContent=''; }

// 2) 録音（Web Speech API）
const SR = window.SpeechRecognition||window.webkitSpeechRecognition;
if(!SR){ speechWarn.hidden=false; btnRec.disabled=true; }
else {
  speechWarn.hidden=true;
  sr = new SR(); sr.lang='ja-JP'; sr.continuous=true; sr.interimResults=true;
  sr.onresult = (e)=>{
    let s=''; for(let i=e.resultIndex;i<e.results.length;i++){ s+=e.results[i][0].transcript; }
    hyp=s; status.textContent='いまの ききとり: ' + s;
  };
  sr.onerror = (e)=>{ status.textContent='ききとり で しょうがい: '+e.error };
}

btnRec.addEventListener('click', ()=>{
  if(!sr) return;
  if(btnRec.dataset.state!=='rec'){
    // start
    hyp=''; status.textContent='よみあげてね…';
    startT=performance.now(); sr.start();
    btnRec.textContent='■ とめる'; btnRec.dataset.state='rec'; btnAgain.hidden=true;
    stars.textContent=''; summary.textContent=''; diff.textContent='';
  } else {
    // stop
    sr.stop();
    const dur=(performance.now()-startT)/1000;
    finalize(dur);
    btnRec.textContent='▶ よみはじめる'; btnRec.dataset.state=''; btnAgain.hidden=false;
  }
});

btnAgain.addEventListener('click', ()=>{
  stars.textContent=''; summary.textContent=''; diff.textContent=''; status.textContent=''; btnAgain.hidden=true;
});

function finalize(durationSec){
  const ref = refText.value.trim(); if(!ref){ summary.textContent='ぶんしょうを いれてね'; return; }
  const nr = normalizeForAlignment(ref); const nh = normalizeForAlignment(hyp||'');
  const ali = levenshteinAlignment(nr, nh);
  const cpm = charsPerMinute(ali.refLen, durationSec);
  const scores = scoreFromMetrics(ali.cer, cpm, 0);
  const prev = previewOps(ali.ops);
  const star = (v)=> v>=90?3 : v>=75?2 : v>=60?1 : 0; const s=star(scores.overallScore);
  stars.textContent = '🌟'.repeat(s) || '🌟0';
  summary.textContent = `すこあ ${scores.overallScore} / せいかくさ ${scores.accuracyScore} / はやさ ${scores.speedScore}`;
  diff.innerHTML = colorize(prev);
}

function colorize(pre){
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

if('serviceWorker' in navigator){ navigator.serviceWorker.register('./sw.js').catch(()=>{}); }
