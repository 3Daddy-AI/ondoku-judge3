import argparse
import json
from typing import Optional

from . import normalization as nz
from .alignment import levenshtein_alignment, summarize_alignment
from .asr_vosk import transcribe_wav
from .features import analyze_audio, compute_speed_chars_per_minute, score_from_metrics
from .schemas import JudgeResult


def _read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()


def main():
    ap = argparse.ArgumentParser(description="音読判定ミニプロトタイプ（Vosk日本語モデル使用）")
    ap.add_argument("--text-file", required=True, help="課題本文のテキストファイル（UTF-8）")
    ap.add_argument("--audio-file", required=True, help="音読音声（WAV）")
    ap.add_argument("--vosk-model-dir", required=True, help="Vosk日本語モデルのディレクトリ")
    ap.add_argument("--json", help="結果を書き出すJSONパス")
    args = ap.parse_args()

    ref_text = _read_text(args.text_file)
    asr = transcribe_wav(args.audio_file, args.vosk_model_dir)
    hyp_text = asr.get("text", "")

    norm_ref, norm_hyp = nz.normalize_pair(ref_text, hyp_text)
    ali = levenshtein_alignment(norm_ref, norm_hyp)
    ali_preview = summarize_alignment(ali["ops"])  # type: ignore

    audio_stats = analyze_audio(args.audio_file)
    cpm = compute_speed_chars_per_minute(ali["ref_len"], audio_stats.duration_sec)
    scores = score_from_metrics(ali["cer"], cpm, audio_stats.pauses)

    result = JudgeResult(
        ref_text=ref_text,
        hyp_text=hyp_text,
        norm_ref=norm_ref,
        norm_hyp=norm_hyp,
        cer=float(round(ali["cer"], 4)),
        alignment_ops=ali["ops"],
        alignment_preview=ali_preview,
        duration_sec=round(audio_stats.duration_sec, 3),
        rms_db=round(audio_stats.rms_db, 1),
        pauses=audio_stats.pauses,
        max_pause_sec=round(audio_stats.max_pause_sec, 2),
        chars_per_minute=round(cpm, 1),
        scores=scores,
    )

    # 出力（人間向け）
    print("=== 音読判定 結果 ===")
    print(f"ASR文字列: {hyp_text}")
    print(f"正規化参照: {norm_ref}")
    print(f"正規化認識: {norm_hyp}")
    print(f"CER: {result.cer}  (errors={ali['errors']}/{ali['ref_len']})")
    print(f"差分: {result.alignment_preview}")
    print(f"時間: {result.duration_sec}s  速度: {result.chars_per_minute} chars/min")
    print(f"ポーズ回数: {result.pauses}  最長: {result.max_pause_sec}s  音量(RMS dB): {result.rms_db}")
    print(
        f"Scores -> overall: {scores['overall_score']} | accuracy: {scores['accuracy_score']} | "
        f"speed: {scores['speed_score']} | pause: {scores['pause_score']}"
    )

    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(result.__dict__, f, ensure_ascii=False, indent=2)
        print(f"JSONを書き出しました: {args.json}")


if __name__ == "__main__":
    main()

