import re
import unicodedata
from typing import Tuple

try:
    from pykakasi import kakasi as _kakasi
except Exception:  # pragma: no cover
    _kakasi = None


_JA_PUNCT = "、。・，．！？!?,.：:；;（()）［\[\]］｛{}｝…‥ー—-〜~／/\\\u3000\s"  # noqa: W605
_JA_PUNCT_RE = re.compile(f"[{_JA_PUNCT}]+")


def _hiragana_converter():
    if _kakasi is None:
        raise RuntimeError(
            "pykakasi が見つかりません。`pip install pykakasi` を実行してください。"
        )
    kks = _kakasi()
    kks.setMode("J", "H")  # Kanji -> Hiragana
    kks.setMode("K", "H")  # Katakana -> Hiragana
    kks.setMode("H", "H")  # Hiragana -> Hiragana
    kks.setMode("r", "H")  # Roman -> Hiragana (best-effort)
    return kks.getConverter()


def to_hiragana(text: str) -> str:
    conv = _hiragana_converter()
    return conv.do(text)


def normalize_for_alignment(text: str) -> str:
    """日本語テキストをアライン用に正規化（NFKC、ひらがな、句読点除去）。"""
    if not text:
        return ""
    # Unicode正規化（全角/半角のゆれを統一）
    s = unicodedata.normalize("NFKC", text)
    # ひらがな化
    s = to_hiragana(s)
    # 句読点・空白の除去（比較を文字単位で実施するため）
    s = _JA_PUNCT_RE.sub("", s)
    # 小書きの統一など（必要に応じて拡張）
    s = s.replace("ぁ", "あ").replace("ぃ", "い").replace("ぅ", "う").replace("ぇ", "え").replace("ぉ", "お")
    s = s.replace("っ", "つ").replace("ゃ", "や").replace("ゅ", "ゆ").replace("ょ", "よ")
    return s


def normalize_pair(ref_text: str, hyp_text: str) -> Tuple[str, str]:
    return normalize_for_alignment(ref_text), normalize_for_alignment(hyp_text)

