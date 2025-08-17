from typing import List, Tuple, Dict, Any


Op = Tuple[str, str, str]  # (op, ref_char or '', hyp_char or '')


def levenshtein_alignment(ref: str, hyp: str) -> Dict[str, Any]:
    """文字単位のレーベンシュタイン距離に基づくアラインメントとCERを返す。

    Returns:
        {
          'ops': List[Op],
          'cer': float,
          'errors': int,
          'ref_len': int,
        }
    """
    n, m = len(ref), len(hyp)
    # dp[i][j] = cost to convert ref[:i] -> hyp[:j]
    dp = [[0] * (m + 1) for _ in range(n + 1)]
    bt = [[(0, 0)] * (m + 1) for _ in range(n + 1)]  # backtrace

    for i in range(1, n + 1):
        dp[i][0] = i
        bt[i][0] = (i - 1, 0)
    for j in range(1, m + 1):
        dp[0][j] = j
        bt[0][j] = (0, j - 1)

    for i in range(1, n + 1):
        rc = ref[i - 1]
        for j in range(1, m + 1):
            hc = hyp[j - 1]
            cost_sub = 0 if rc == hc else 1
            # operations: del, ins, sub/keep
            del_cost = dp[i - 1][j] + 1
            ins_cost = dp[i][j - 1] + 1
            sub_cost = dp[i - 1][j - 1] + cost_sub
            best = min(del_cost, ins_cost, sub_cost)
            dp[i][j] = best
            if best == sub_cost:
                bt[i][j] = (i - 1, j - 1)
            elif best == del_cost:
                bt[i][j] = (i - 1, j)
            else:
                bt[i][j] = (i, j - 1)

    # backtrace to ops
    ops: List[Op] = []
    i, j = n, m
    while not (i == 0 and j == 0):
        pi, pj = bt[i][j]
        if pi == i - 1 and pj == j - 1:
            # sub or keep
            rc = ref[i - 1]
            hc = hyp[j - 1]
            if rc == hc:
                ops.append(("=", rc, hc))
            else:
                ops.append(("~", rc, hc))
        elif pi == i - 1 and pj == j:
            # deletion (ref has extra)
            ops.append(("-", ref[i - 1], ""))
        else:
            # insertion (hyp has extra)
            ops.append(("+", "", hyp[j - 1]))
        i, j = pi, pj

    ops.reverse()
    errors = sum(1 for op, _, _ in ops if op in {"~", "+", "-"})
    cer = errors / max(1, n)
    return {"ops": ops, "cer": cer, "errors": errors, "ref_len": n}


def summarize_alignment(ops: List[Op]) -> str:
    """簡易ハイライト文字列（= 正解 / ~ 置換 / - 欠落 / + 余分）。"""
    out = []
    for op, r, h in ops:
        if op == "=":
            out.append(r)
        elif op == "~":
            out.append(f"[{r}->{h}]")
        elif op == "+":
            out.append(f"(+{h})")
        else:  # '-'
            out.append(f"(-{r})")
    return "".join(out)

