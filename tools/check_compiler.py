"""Enforce the exact MoonBit compiler build validated in CI."""
import re, subprocess
result = subprocess.run(['moonc','-v'],capture_output=True,text=True,check=True)
text = result.stdout + result.stderr
print(text.strip())
match = re.search(r'(\d+)\.(\d+)\.(\d+)', text)
assert match and tuple(map(int,match.groups())) == (0,10,22), 'moonc 0.10.22 required'
assert '+124d61d05' in text, 'moonc build 124d61d05 required'
