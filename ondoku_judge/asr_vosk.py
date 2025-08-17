from typing import Optional, Dict, Any
import json
import numpy as np
import soundfile as sf


def _ensure_vosk():
    try:
        import vosk  # noqa: F401
    except Exception as e:  # pragma: no cover
        raise RuntimeError(
            "Vosk が見つかりません。`pip install vosk` と日本語モデルの配置が必要です。"
        ) from e


def _load_audio_mono16k(wav_path: str) -> np.ndarray:
    x, sr = sf.read(wav_path, dtype="float32")
    if x.ndim == 2:
        x = x.mean(axis=1)
    # 簡易リサンプリング（16kHzへ）
    target_sr = 16000
    if sr != target_sr:
        # 線形補間の簡易版（高音質はresampyやscipy推奨）
        t_src = np.arange(len(x)) / sr
        t_dst = np.arange(int(len(x) * target_sr / sr)) / target_sr
        x = np.interp(t_dst, t_src, x).astype(np.float32)
    return x


def transcribe_wav(wav_path: str, vosk_model_dir: str) -> Dict[str, Any]:
    """Voskで音声を認識し、仮名ふくむ文字列を返す（句読点はVosk依存）。"""
    _ensure_vosk()
    from vosk import Model, KaldiRecognizer

    x = _load_audio_mono16k(wav_path)
    model = Model(vosk_model_dir)
    rec = KaldiRecognizer(model, 16000)
    rec.SetWords(True)

    # 0.5秒チャンクで処理
    chunk = 8000
    for i in range(0, len(x), chunk):
        buf = (x[i : i + chunk] * 32767).astype(np.int16).tobytes()
        rec.AcceptWaveform(buf)

    final = json.loads(rec.FinalResult())
    text = final.get("text", "")
    return {"text": text, "raw": final}

