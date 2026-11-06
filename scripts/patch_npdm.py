#!/usr/bin/env python3
"""Rewrite the title ID in a main.npdm (ACI0 program ID + ACID allowed range).

hacBrewPack --titleid only patches ACI0; the ACID range must match too or the
loader rejects the program on consoles without loader signature patches.
"""
import struct
import sys


def patch(path: str, tid: int) -> None:
    data = bytearray(open(path, "rb").read())
    if data[:4] != b"META":
        sys.exit(f"{path}: not an NPDM (missing META magic)")
    aci_off, _aci_sz, acid_off, _acid_sz = struct.unpack_from("<IIII", data, 0x70)
    if data[aci_off:aci_off + 4] != b"ACI0":
        sys.exit("ACI0 section not found")
    if data[acid_off + 0x200:acid_off + 0x204] != b"ACID":
        sys.exit("ACID section not found")
    struct.pack_into("<QQ", data, acid_off + 0x210, tid, tid)
    struct.pack_into("<Q", data, aci_off + 0x10, tid)
    open(path, "wb").write(data)
    print(f"npdm patched: ACI0 and ACID range -> {tid:016x}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: patch_npdm.py <main.npdm> <title_id_hex>")
    patch(sys.argv[1], int(sys.argv[2], 16))
