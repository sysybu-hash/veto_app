import sys

with open('frontend/lib/screens/landing_screen.dart', 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'VETO AI' in line:
        lines[i] = "            code == 'he' ? 'שאל את VETO AI' : code == 'ru' ? 'Спросить VETO AI' : 'Ask VETO AI',\n"

with open('frontend/lib/screens/landing_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
