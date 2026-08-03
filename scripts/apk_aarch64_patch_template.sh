#!/usr/bin/env bash
set -euo pipefail

# Reversible fixed-offset AArch64 patch template for apktool projects.
# Replace the PATCHES table only after proving file offsets and bytes.

ROOT="${1:-decoded_apk}"

declare -a PATCHES=(
  # "relative/path/to/lib.so offset_hex expected_old_hex new_hex"
  # Example NOP-style return for AArch64: mov w0,#1; ret = 20008052c0035fd6
  # "lib/arm64-v8a/libtarget.so 0x1234 deadbeef 20008052c0035fd6"
)

suimi_hex_to_file() {
  local hex="$1"
  local out="$2"
  printf '%s' "$hex" | xxd -r -p > "$out"
}

suimi_read_hex() {
  local file="$1"
  local offset="$2"
  local size="$3"
  xxd -p -l "$size" -s "$offset" "$file" | tr -d '\n'
}

suimi_patch_one() {
  local rel="$1"
  local offset="$2"
  local expected="$3"
  local replacement="$4"
  local so="$ROOT/$rel"
  local bytes_file
  local size
  local current

  if [[ ! -f "$so" ]]; then
    echo "missing: $so" >&2
    return 1
  fi

  if [[ $(( ${#expected} % 2 )) -ne 0 || $(( ${#replacement} % 2 )) -ne 0 ]]; then
    echo "hex length must be even for $rel" >&2
    return 1
  fi

  if [[ ${#expected} -ne ${#replacement} ]]; then
    echo "expected and replacement byte lengths differ for $rel" >&2
    return 1
  fi

  size=$(( ${#expected} / 2 ))
  current="$(suimi_read_hex "$so" "$offset" "$size")"
  if [[ "${current,,}" != "${expected,,}" ]]; then
    echo "byte mismatch: $so @ $offset expected=$expected current=$current" >&2
    return 1
  fi

  if [[ ! -f "${so}.bak" ]]; then
    cp "$so" "${so}.bak"
  fi

  bytes_file="$(mktemp)"
  suimi_hex_to_file "$replacement" "$bytes_file"
  dd if="$bytes_file" of="$so" bs=1 seek="$((offset))" conv=notrunc status=none
  rm -f "$bytes_file"

  echo "patched: $so @ $offset"
  xxd -g 4 -l "$size" -s "$offset" "$so"
}

if [[ ${#PATCHES[@]} -eq 0 ]]; then
  echo "No patches configured. Edit PATCHES in this template first." >&2
  exit 2
fi

for patch in "${PATCHES[@]}"; do
  # shellcheck disable=SC2086
  suimi_patch_one $patch
done
