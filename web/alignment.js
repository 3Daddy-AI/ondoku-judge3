export function normalizeForAlignment(s){
  if(!s) return '';
  s = s.normalize('NFKC');
  // 句読点・空白を除去
  const punct = /[、。・，．！？!?,.：:；;（）()\[\]｛｝…‥ー—\-〜~／\/\\\s]/g;
  s = s.replace(punct,'');
  // 小書きの統一（簡易）
  s = s.replace(/[ぁ]/g,'あ').replace(/[ぃ]/g,'い').replace(/[ぅ]/g,'う').replace(/[ぇ]/g,'え').replace(/[ぉ]/g,'お')
       .replace(/[っ]/g,'つ').replace(/[ゃ]/g,'や').replace(/[ゅ]/g,'ゆ').replace(/[ょ]/g,'よ');
  return s;
}

export function levenshteinAlignment(ref,hyp){
  const r=[...ref], h=[...hyp];
  const n=r.length, m=h.length;
  const dp=Array.from({length:n+1},()=>Array(m+1).fill(0));
  const bt=Array.from({length:n+1},()=>Array(m+1).fill([0,0]));
  for(let i=1;i<=n;i++){dp[i][0]=i;bt[i][0]=[i-1,0];}
  for(let j=1;j<=m;j++){dp[0][j]=j;bt[0][j]=[0,j-1];}
  for(let i=1;i<=n;i++){
    for(let j=1;j<=m;j++){
      const cost = r[i-1]===h[j-1]?0:1;
      const del=dp[i-1][j]+1, ins=dp[i][j-1]+1, sub=dp[i-1][j-1]+cost;
      const best=Math.min(del,ins,sub); dp[i][j]=best;
      bt[i][j] = best===sub?[i-1,j-1] : best===del?[i-1,j] : [i,j-1];
    }
  }
  const ops=[]; let i=n,j=m;
  while(!(i===0&&j===0)){
    const [pi,pj]=bt[i][j];
    if(pi===i-1 && pj===j-1){
      const rc=r[i-1], hc=h[j-1];
      ops.push(rc===hc?['=',rc,hc]:['~',rc,hc]);
    }else if(pi===i-1&&pj===j){
      ops.push(['-',r[i-1],'']);
    }else{
      ops.push(['+','',h[j-1]]);
    }
    i=pi;j=pj;
  }
  ops.reverse();
  const errors=ops.reduce((a,[op])=>a+(op==='~'||op==='+'||op==='-'?1:0),0);
  const cer = n?errors/n:0;
  return {ops,cer,errors,refLen:n};
}

export function previewOps(ops){
  return ops.map(([op,r,h])=>{
    if(op==='=') return r;
    if(op==='~') return `[${r}->${h}]`;
    if(op==='+') return `(+${h})`;
    return `(-${r})`;
  }).join('');
}

