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
  const { data } = await Tesseract.recognize(imgUrl, 'jpn', { langPath: 'https://tessdata.projectnaptha.com/4.0.0', logger: m=>{ /*progress*/ } });
  refText.value = (data.text||'').trim();
  ocrStatus.textContent='よみとり かんりょう！';
});

pdfInput.addEventListener('change', async (e)=>{
  const f=e.target.files?.[0]; if(!f) return; resetOCR();
  try {
    ocrStatus.textContent='よみとり中（PDF）…';
    const array = await f.arrayBuffer();
    const pdf = await pdfjsLib.getDocument({
      data: array,
      cMapUrl: 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/cmaps/',
      cMapPacked: true,
      standardFontDataUrl: 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/standard_fonts/'
    }).promise;
    let all='';
    for(let i=1;i<=pdf.numPages;i++){
      ocrStatus.textContent = `よみとり中（PDF ページ ${i}/${pdf.numPages}）…`;
      const page = await pdf.getPage(i);
      // まずはデジタルテキスト抽出（速い）
      let pageText = '';
      try {
        const tc = await page.getTextContent();
        const items = (tc.items||[]);
        const sizes = items.map(it=>{
          const t = it.transform||[1,0,0,1,0,0];
          const a=Math.abs(t[0]), d=Math.abs(t[3]);
          return Math.max(a,d);
        });
        const med = median(sizes)||1;
        const filtered = items.filter((it)=>{
          const t = it.transform||[1,0,0,1,0,0];
          const a=Math.abs(t[0]), d=Math.abs(t[3]);
          const sz=Math.max(a,d);
          return sz >= med*0.7;
        });
        pageText = filtered.map(it=>it.str).join('');
      } catch {}

      if (pageText && pageText.trim().length >= 10 && !isGarbled(pageText)) {
        all += '\n' + pageText;
        continue;
      }
      // だめならOCRにフォールバック（重い）
      const canvas = await renderPageToCanvas(page, 1.8, 0);
      const textOCR = await tryOcrOnCanvas(canvas);
      all += '\n' + textOCR;
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

function isGarbled(text){
  const s = text.replace(/\s+/g,'');
  if(s.length < 10) return false;
  const ratio = japaneseRatio(s);
  return ratio < 0.2;
}

function japaneseRatio(s){
  let jp=0, latin=0, other=0;
  for(const ch of s){
    const code = ch.codePointAt(0);
    if(!code) continue;
    if((code>=0x3040&&code<=0x30FF) || (code>=0x4E00&&code<=0x9FFF)){ jp++; }
    else if((code>=0x0020&&code<=0x007E)){ latin++; }
    else { other++; }
  }
  return jp / Math.max(1,(jp+latin+other));
}

function median(arr){
  if(arr.length===0) return 0;
  const a=[...arr].sort((x,y)=>x-y); const m=Math.floor(a.length/2);
  return a.length%2? a[m] : (a[m-1]+a[m])/2;
}

async function renderPageToCanvas(page, scale=1.8, rotation=0){
  const viewport = page.getViewport({scale, rotation});
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  canvas.width = Math.floor(viewport.width);
  canvas.height = Math.floor(viewport.height);
  await page.render({canvasContext:ctx, viewport}).promise;
  return canvas;
}

async function tryOcrOnCanvas(canvas){
  const opts = { langPath: 'https://tessdata.projectnaptha.com/4.0.0', logger: _=>{} };
  const r1 = await Tesseract.recognize(canvas, 'jpn_vert+jpn', opts);
  const t1 = (r1.data.text||'').trim();
  const ratio1 = japaneseRatio(t1.replace(/\s+/g,''));
  const c2 = document.createElement('canvas'); c2.width = canvas.height; c2.height = canvas.width;
  const ctx2 = c2.getContext('2d'); ctx2.translate(c2.width/2, c2.height/2); ctx2.rotate(Math.PI/2); ctx2.drawImage(canvas, -canvas.width/2, -canvas.height/2);
  const r2 = await Tesseract.recognize(c2, 'jpn_vert+jpn', opts);
  const t2 = (r2.data.text||'').trim();
  const ratio2 = japaneseRatio(t2.replace(/\s+/g,''));
  return ratio2>ratio1 ? t2 : t1;
}

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
