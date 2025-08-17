from dataclasses import dataclass
from typing import List, Tuple, Dict, Any, Optional


@dataclass
class AlignmentResult:
    ops: List[Tuple[str, str, str]]
    cer: float
    errors: int
    ref_len: int


@dataclass
class JudgeResult:
    ref_text: str
    hyp_text: str
    norm_ref: str
    norm_hyp: str
    cer: float
    alignment_ops: List[Tuple[str, str, str]]
    alignment_preview: str
    duration_sec: float
    rms_db: float
    pauses: int
    max_pause_sec: float
    chars_per_minute: float
    scores: Dict[str, Any]

