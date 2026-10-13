#!/usr/bin/env python3
"""Apply an IPS patch: ips_apply.py <base rom> <patch.ips> <out rom> [expected base sha1]
Refuses to patch if the base ROM's SHA1 doesn't match the expected value."""
import hashlib, sys

base, patch, out = sys.argv[1:4]
rom = bytearray(open(base, "rb").read())
if len(sys.argv) > 4:
    sha = hashlib.sha1(rom).hexdigest()
    if sha != sys.argv[4].lower():
        sys.exit(f"base ROM sha1 {sha} != expected {sys.argv[4]}")
ips = open(patch, "rb").read()
if ips[:5] != b"PATCH":
    sys.exit("not an IPS file")
i, records = 5, 0
while True:
    if ips[i:i + 3] == b"EOF":
        i += 3
        break
    off = int.from_bytes(ips[i:i + 3], "big")
    size = int.from_bytes(ips[i + 3:i + 5], "big")
    i += 5
    if size:
        data = ips[i:i + size]
        i += size
    else:  # RLE record
        n = int.from_bytes(ips[i:i + 2], "big")
        data = ips[i + 2:i + 3] * n
        i += 3
    if off + len(data) > len(rom):
        rom.extend(b"\x00" * (off + len(data) - len(rom)))
    rom[off:off + len(data)] = data
    records += 1
if len(ips) - i == 3:  # optional truncation extension
    rom = rom[:int.from_bytes(ips[i:i + 3], "big")]
open(out, "wb").write(rom)
print(f"applied {records} records; output {len(rom)} bytes, sha1 {hashlib.sha1(rom).hexdigest()}")
