import argparse
import math
from pathlib import Path

import pefile


def suimi_entropy(data):
    if not data:
        return 0.0
    counts = [0] * 256
    for b in data:
        counts[b] += 1
    total = len(data)
    return -sum((c / total) * math.log2(c / total) for c in counts if c)


def suimi_main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pe")
    args = ap.parse_args()
    path = Path(args.pe)
    pe = pefile.PE(str(path), fast_load=False)
    print(f"path={path}")
    print(f"machine=0x{pe.FILE_HEADER.Machine:x} sections={pe.FILE_HEADER.NumberOfSections}")
    print(f"image_base=0x{pe.OPTIONAL_HEADER.ImageBase:x} entry_rva=0x{pe.OPTIONAL_HEADER.AddressOfEntryPoint:x}")
    for sec in pe.sections:
        name = sec.Name.rstrip(b"\0").decode(errors="replace")
        data = sec.get_data()
        print(
            f"section {name!r} va=0x{sec.VirtualAddress:x} raw=0x{sec.PointerToRawData:x} "
            f"vsize=0x{sec.Misc_VirtualSize:x} rawsize=0x{sec.SizeOfRawData:x} "
            f"entropy={suimi_entropy(data):.2f} chars=0x{sec.Characteristics:x}"
        )
    if hasattr(pe, "DIRECTORY_ENTRY_IMPORT"):
        for entry in pe.DIRECTORY_ENTRY_IMPORT:
            funcs = [imp.name.decode(errors="replace") if imp.name else f"ord_{imp.ordinal}" for imp in entry.imports[:12]]
            print(f"import {entry.dll.decode(errors='replace')}: {', '.join(funcs)}")
    if hasattr(pe, "DIRECTORY_ENTRY_EXPORT"):
        names = [sym.name.decode(errors="replace") for sym in pe.DIRECTORY_ENTRY_EXPORT.symbols if sym.name]
        print("exports: " + ", ".join(names[:80]))


if __name__ == "__main__":
    suimi_main()
