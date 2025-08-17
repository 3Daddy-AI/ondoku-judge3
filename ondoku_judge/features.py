from dataclasses import dataclass
from typing import Dict, Any
import numpy as np
import soundfile as sf


@dataclass
class AudioStats:
    duration_sec: float
    rms_db: float
    pauses: int
    max_pause_sec: float


def _rms_db(x: np.ndarray) -> float:
    eps = 1e-12
    rms = float(np.sqrt(np.mean(np.square(x) + eps)))
    return 20.0 * np.log10(max(rms, eps))


def _count_pauses(x: np.ndarray, sr: int, th: float = 0.01, min_pause: float = 0.5) -> (int, float):
    """しきい値th未満の無音区間を数える。min_pause秒以上をポーズ扱い。"""
    frame = int(0.02 * sr)  # 20ms
    hop = int(0.01 * sr)    # 10ms
    if len(x) < frame:
        return 0, 0.0
    energies = []
    for i in range(0, len(x) - frame + 1, hop):
        seg = x[i : i + frame]
        energies.append(np.sqrt(np.mean(seg * seg)))
    energies = np.asarray(energies)
    mask = energies < th
    # 連続trueの長さを秒に換算
    if not mask.any():
        return 0, 0.0
    pauses = 0
    maxlen = 0
    cur = 0
    for v in mask:
        if v:
            cur += 1
            maxlen = max(maxlen, cur)
        else:
            if cur > 0:
                dur = cur * hop / sr
                if dur >= min_pause:
                    pauses += 1
            cur = 0
    if cur > 0:
        dur = cur * hop / sr
        if dur >= min_pause:
            pauses += 1
        maxlen = max(maxlen, cur)
    max_pause = maxlen * hop / sr
    return pauses, max_pause


def analyze_audio(wav_path: str) -> AudioStats:
    x, sr = sf.read(wav_path, dtype="float32")
    if x.ndim == 2:
        x = x.mean(axis=1)
    duration = len(x) / sr if sr > 0 else 0.0
    rms = _rms_db(x)
    pauses, max_pause = _count_pauses(x, sr)
    return AudioStats(duration_sec=duration, rms_db=rms, pauses=pauses, max_pause_sec=max_pause)


def compute_speed_chars_per_minute(ref_len_chars: int, duration_sec: float) -> float:
    if duration_sec <= 0:
        return 0.0
    return 60.0 * ref_len_chars / duration_sec


def score_from_metrics(cer: float, cpm: float, pauses: int) -> Dict[str, Any]:
    # 正確さスコア
    acc = max(0.0, min(100.0, (1.0 - cer) * 100.0))
    # 速度スコア（200–350字/分を満点帯とし、外側は線形減点）
    low, high = 200.0, 350.0
    if cpm >= low and cpm <= high:
        spd = 100.0
    elif cpm < low:
        spd = max(0.0, 100.0 - (low - cpm) * 0.5)
    else:  # cpm > high
        spd = max(0.0, 100.0 - (cpm - high) * 0.5)
    # ポーズ（1回につき-1点、上限-10）
    pause_penalty = min(10.0, float(max(0, pauses)))
    pause_score = max(0.0, 100.0 - pause_penalty)
    # 総合（重み付け）
    overall = 0.7 * acc + 0.2 * spd + 0.1 * pause_score
    return {
        "accuracy_score": round(acc, 1),
        "speed_score": round(spd, 1),
        "pause_score": round(pause_score, 1),
        "overall_score": round(overall, 1),
    }

