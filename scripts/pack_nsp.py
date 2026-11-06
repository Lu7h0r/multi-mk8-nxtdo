#!/usr/bin/env python3
"""Pack a directory of NCAs (+ optional tik/cert) into an NSP (PFS0)."""
import os, struct, sys

def pack(src_dir: str, out_path: str) -> None:
    names = sorted(f for f in os.listdir(src_dir) if f.endswith(('.nca', '.tik', '.cert')))
    # cnmt first is conventional but not required; keep it first anyway.
    names.sort(key=lambda n: (not n.endswith('.cnmt.nca'), n))
    sizes = [os.path.getsize(os.path.join(src_dir, n)) for n in names]
    strtab = b''.join(n.encode() + b'\0' for n in names)
    header_len = 0x10 + 0x18 * len(names) + len(strtab)
    pad = (-header_len) % 0x20
    strtab += b'\0' * pad
    hdr = b'PFS0' + struct.pack('<III', len(names), len(strtab), 0)
    off = str_off = 0
    for n, s in zip(names, sizes):
        hdr += struct.pack('<QQII', off, s, str_off, 0)
        off += s
        str_off += len(n) + 1
    hdr += strtab
    with open(out_path, 'wb') as out:
        out.write(hdr)
        for n in names:
            with open(os.path.join(src_dir, n), 'rb') as f:
                while chunk := f.read(16 << 20):
                    out.write(chunk)
    expected = len(hdr) + sum(sizes)
    actual = os.path.getsize(out_path)
    if actual != expected:
        sys.exit(f"size mismatch: {actual} != {expected}")
    print(f"ok {out_path} {actual} bytes, {len(names)} files")

if __name__ == '__main__':
    pack(sys.argv[1], sys.argv[2])
