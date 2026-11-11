"""Enforce the published compiler floor; record the actual compiler in CI."""
import re, subprocess
result = subprocess.run(['moonc','-v'],capture_output=True,text=True,check=True)
text = result.stdout + result.stderr
print(text.strip())
match = re.search(r'(\d+)\.(\d+)\.(\d+)', text)
assert match and tuple(map(int,match.groups())) >= (0,10,20), 'moonc >= 0.10.20 required (contest floor: 0.10.16)'
