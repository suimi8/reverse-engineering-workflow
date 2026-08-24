---
name: competition-zip-archive
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for ZIP and PKZIP archive challenges, legacy ZipCrypto identification, known-plaintext recovery with bkcrack, key-based decryption, and reproducible extraction. Use when the user asks to solve an encrypted ZIP challenge, inspect ZipCrypto metadata, recover keys from a known file prefix, or unlock an archive without starting with password brute force. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi ZIP归档比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition ZIP Archive

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is active and has established sandbox assumptions, evidence priorities, and the analysis project root. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the decisive path is an encrypted ZIP/PKZIP archive rather than an upload parser or a generic crypto blob. Prefer the legacy ZipCrypto known-plaintext path when the challenge gives a predictable file, format header, template, or other recoverable plaintext. Do not begin with blind password brute force.

Reply in Simplified Chinese unless the user explicitly requests English. Keep commands and tool output in their original form.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Preserve the original archive, compute a hash, and work on a copy under the analysis project's `work/<case>/` directory.
2. Confirm the actual archive format and list entries before attempting a password attack.
3. Determine whether the entry uses legacy ZipCrypto. `bkcrack` does not recover WinZip AES or other modern encryption.
4. Build an exact known-plaintext candidate. The attack needs at least 12 known plaintext bytes, including at least 8 contiguous bytes.
5. Recover the internal keys with `bkcrack`, then create an unencrypted copy and extract it.
6. Preserve the command, entry names, known-plaintext source, recovered keys, output hash, and final flag as evidence.

## Tool Setup

Use the normal tool index and bootstrap path before guessing an executable location:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/bootstrap-reverse.ps1 -Capability bkcrack
```

On Kali, use the equivalent capability command:

```bash
bash kali/scripts/bootstrap-reverse.sh bkcrack
```


## Workflow

### 1. Establish Archive Truth

Keep the original immutable and record:

```bash
sha256sum challenge.zip
file challenge.zip
bkcrack -L challenge.zip
```

On Windows, use `Get-FileHash` in place of `sha256sum`. `bkcrack -L` shows entry names, compression methods, and encryption status. Do not infer the encryption type from the `.zip` extension alone.

Check the entry that will provide the known plaintext. A useful candidate is a stored or otherwise predictable file such as a PNG, PDF, text template, or challenge-generated configuration. A local ZIP header (`PK\x03\x04`) is metadata for the archive entry, not plaintext inside the encrypted member, so it is not by itself a useful known-plaintext sample.

### 2. Recover Keys With Known Plaintext

When the ciphertext entry is `flag.txt` and a matching plaintext entry is available in `known.zip`:

```bash
bkcrack -C challenge.zip -c flag.txt -P known.zip -p flag.txt
```

For raw ciphertext and plaintext files:

```bash
bkcrack -c cipherfile -p plainfile
```

The plaintext must match the bytes represented in the encrypted entry. If the entry was deflated, an uncompressed copy of the file is not automatically the right input; use a matching ZIP fixture or the exact compressed bytes.

If the known bytes begin at an offset, add `-o <offset>`. If only 8-11 bytes are contiguous, combine them with other known bytes using sparse hints:

```bash
bkcrack -c cipherfile -p plainfile -x 25 4b4f -x 30 21
```

The successful run yields three internal ZipCrypto keys. Record them exactly as printed; they are not the original password.

### 3. Unlock And Validate

Use the recovered keys to make a new archive, leaving the source untouched:

```bash
bkcrack -C challenge.zip -k K0 K1 K2 -D unlocked.zip
7z t unlocked.zip
7z x unlocked.zip -ounpacked
```

Replace `K0 K1 K2` with the hexadecimal values printed by `bkcrack`. Validate the output with the archive test command and a hash or exact flag comparison. If only one raw member is needed, `-d` can write its deciphered bytes; deflated raw data may need the `inflate.py` helper shipped with bkcrack.

### 4. Re-route When Preconditions Fail

- WinZip AES or another modern encryption mode: stop this path and identify the challenge-specific primitive.
- No reliable known plaintext: inspect filenames, metadata, compression choices, challenge source, and other entries before considering password recovery.
- Known plaintext shorter than the requirement: locate more contiguous bytes or use evidence-backed sparse offsets.
- The problem is an application upload/parser chain: hand off to `$competition-file-parser-chain`.
- The problem is a generic ciphertext or custom cipher after archive extraction: hand off to `$competition-crypto-mobile`.

## Evidence To Preserve

- Original and working-copy paths plus SHA-256 hashes
- `bkcrack -L` output and the selected encrypted member
- Exact plaintext fixture, compression method, offsets, and sparse byte hints
- Key recovery command and the three recovered internal keys
- `unlocked.zip` validation output, extraction path, and final artifact hash

Read `references/zip-archive.md` for the decision table and evidence checklist.