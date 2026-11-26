"""Enforce the exact MoonBit toolchain used by CI and documented releases."""
import re
import subprocess

EXPECTED = {
    "moonc": ("moonc", "-v", r"v0\.10\.22\+124d61d05"),
    "moon": ("moon", "version", r"moon 0\.1\.20261119\b"),
    "moonrun": ("moonrun", "--version", r"moonrun 0\.1\.20261119\b"),
}

for name, (executable, argument, pattern) in EXPECTED.items():
    result = subprocess.run(
        [executable, argument], capture_output=True, text=True, check=True
    )
    output = (result.stdout + result.stderr).strip()
    print(output)
    if re.search(pattern, output) is None:
        raise SystemExit(f"{name} does not match the required toolchain: {pattern}")
