import argparse
import shutil
from pathlib import Path


def suimi_parse_hex(text):
    return bytes.fromhex(text.replace(" ", "").replace("\\x", ""))


def suimi_main():
    ap = argparse.ArgumentParser(description="Reversible file-offset byte patch template.")
    ap.add_argument("file")
    ap.add_argument("--offset", required=True, help="file offset, decimal or 0x...")
    ap.add_argument("--expect", required=True, help="expected original bytes, hex")
    ap.add_argument("--patch", required=True, help="new bytes, hex")
    args = ap.parse_args()

    path = Path(args.file)
    offset = int(args.offset, 0)
    expect = suimi_parse_hex(args.expect)
    patch = suimi_parse_hex(args.patch)
    if len(expect) != len(patch):
        raise SystemExit("expect and patch must have same length")

    backup = path.with_suffix(path.suffix + ".bak")
    if not backup.exists():
        shutil.copy2(path, backup)

    data = bytearray(path.read_bytes())
    got = bytes(data[offset : offset + len(expect)])
    if got != expect:
        raise SystemExit(f"original bytes mismatch at 0x{offset:x}: got={got.hex()} expect={expect.hex()}")
    data[offset : offset + len(patch)] = patch
    path.write_bytes(data)
    print(f"patched {path} offset=0x{offset:x} {expect.hex()} -> {patch.hex()} backup={backup}")


if __name__ == "__main__":
    suimi_main()
