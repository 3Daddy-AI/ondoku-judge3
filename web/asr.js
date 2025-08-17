// ASR 抽象: Vosk(WASM) or Web Speech API

export function makeASR(){
  let mode = 'vosk';
  let vosk = null; // {worker, recognizer}
  let webspeech = null; // SpeechRecognition
  let streamHandler = null;
  let hypText = '';

  async function setMode(m){ mode=m; }

  async function loadVoskModel(url){
    // 注意: 実際のAPIはvosk-browserのバージョンに依存します。CDN経由例で雛形を示します。
    // 推奨: https://github.com/alphacep/vosk-browser を参照し、モデルURLを指定
    if(vosk) return;
    const mod = await import('https://cdn.jsdelivr.net/npm/vosk-browser@0.0.1/dist/vosk.js');
    // 便宜上の雛形（実際は initialize/Modelパス指定が必要）
    vosk = { lib: mod };
    // 具体実装はモデル/バージョンに合わせて書き換えてください
  }

  async function start(stream, onPartial){
    hypText='';
    if(mode==='webspeech'){
      const SR = window.SpeechRecognition||window.webkitSpeechRecognition; if(!SR) throw new Error('WebSpeech未対応');
      webspeech = new SR(); webspeech.lang='ja-JP'; webspeech.continuous=true; webspeech.interimResults=true;
      webspeech.onresult = e=>{ let s=''; for(let i=e.resultIndex;i<e.results.length;i++){ s+=e.results[i][0].transcript; } hypText=s; onPartial(hypText); };
      webspeech.start();
      return;
    }
    // Voskモード（雛形: 実モデルによって記述差）
    // ここではUI上で「モデル読み込み済み」であることを前提にしています。
    // 実運用では vosk-browser の createModel / createRecognizer / attach to AudioWorklet を実装してください。
    console.warn('Voskモードは雛形です。vosk-browserのドキュメントに合わせて実装してください。');
  }

  async function stop(){
    if(mode==='webspeech' && webspeech){ webspeech.stop(); }
    return hypText;
  }

  return { setMode, loadVoskModel, start, stop };
}

