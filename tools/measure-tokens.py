# measure-tokens.py -- real-token calibration for the SpecEverything skill library (deepening Phase 4).
# Measures with tiktoken cl100k_base (industry reference BPE; the consuming model's tokenizer may differ,
# so this is calibration data alongside the estimate formula, not a replacement gate -- the runtime gate
# in skill-audit.ps1 keeps the CJK+ascii/4 estimate precisely because it is dependency-free).
#
# Layers measured:
#   body  = full SKILL.md text        -> trigger cost (paid once, when the skill fires)
#   desc  = frontmatter description   -> registration-layer constant (paid on every turn of every session)
# Usage: python tools/measure-tokens.py [repo_root]
import pathlib
import re
import sys

import tiktoken

root = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parent.parent
enc = tiktoken.get_encoding("cl100k_base")

skill_files = sorted(root.glob("skills/**/SKILL.md")) + sorted(root.glob("mudules/**/SKILL.md"))
DESC = re.compile(r'^description:\s*"(.*?)"\s*$', re.MULTILINE | re.DOTALL)

rows = []
reg = 0
body_total = 0
est_total = 0
for f in skill_files:
    text = f.read_text(encoding="utf-8")
    body = len(enc.encode(text))
    m = DESC.search(text)
    desc = len(enc.encode(m.group(1))) if m else 0
    reg += desc
    cjk = sum(1 for ch in text if "\u4e00" <= ch <= "\u9fff")
    ascii_pr = sum(1 for ch in text if "!" <= ch <= "~")
    est = cjk + ascii_pr // 4
    body_total += body
    est_total += est
    rows.append((f.parent.name, body, est, desc))

rows.sort(key=lambda r: -r[1])
print("| skill | body (real) | body (est) | desc (real) |")
print("|---|---|---|---|")
for name, body, est, desc in rows:
    print(f"| {name} | {body} | {est} | {desc} |")
print(f"| **TOTAL ({len(rows)} SKILL.md)** | **{body_total}** | **{est_total}** | **{reg}** |")
print()
print(f"registration-layer constant (sum of descriptions, paid every turn): {reg} tokens")
print(f"estimate formula error: {body_total} real vs {est_total} est -> ratio {body_total / est_total:.3f}")
