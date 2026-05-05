"""One-off: parse login_screen.dart _copy maps -> ARB key list. Run from frontend/: python tool/extract_login_arb.py"""
import re
from pathlib import Path

text = Path("lib/screens/login_screen.dart").read_text(encoding="utf-8")


def parse_block(locale: str) -> dict[str, str]:
    start = text.index(f"'{locale}': {{") + len(f"'{locale}': {{")
    depth = 1
    i = start
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    block = text[start : i - 1]
    out: dict[str, str] = {}
    # multiline values: 'key': '...', possibly spanning lines
    for m in re.finditer(
        r"'([^']+)':\s*((?:'(?:\\'|[^'])*'|\"(?:\\\"|[^\"])*\"))",
        block,
        re.S,
    ):
        k, raw = m.group(1), m.group(2)
        if raw.startswith("'"):
            v = raw[1:-1].replace("\\'", "'")
        else:
            v = raw[1:-1].replace('\\"', '"')
        out[k] = v
    return out


def to_arb_key(k: str) -> str:
    parts = k.split("_")
    return "login" + "".join(p[:1].upper() + p[1:] if p else "" for p in parts)


he = parse_block("he")
en = parse_block("en")
ru = parse_block("ru")
keys = sorted(he.keys())
assert set(keys) == set(en.keys()) == set(ru.keys()), (
    set(he.keys()) ^ set(en.keys()),
    set(he.keys()) ^ set(ru.keys()),
)

for loc, name in [(en, "en"), (he, "he"), (ru, "ru")]:
    lines = []
    for k in keys:
        ak = to_arb_key(k)
        val = loc[k].replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        lines.append(f'  "{ak}": "{val}"')
    Path(f"tool/_login_arb_{name}.txt").write_text(",\n".join(lines) + "\n", encoding="utf-8")
print("keys", len(keys))
