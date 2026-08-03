# PE Patching

## Patch Order

1. Prove behavior in runtime.
2. Locate exact branch/function/bytes.
3. Create backup.
4. Patch the smallest byte range.
5. Recalculate checksum only if the loader/app requires it.
6. Verify fresh start and target workflow.
7. Document offset/RVA/original bytes/new bytes/reason.

## Common Patch Types

- conditional branch flip: `JZ` <-> `JNZ`, short/near jump care.
- force return value: `xor eax,eax; ret`, `mov eax,1; ret` where calling convention permits.
- NOP a call only after confirming side effects are not needed.
- redirect string/config path only if buffer size and encoding are safe.

## PE Offset Discipline

Always distinguish:

- file offset
- RVA
- VA = image base + RVA
- live rebased address

For ASLR, runtime VA differs between launches. Use module base + RVA.

## Rollback

Every persistent patch must include:

- `.bak` original copy.
- original byte sequence.
- validation command or manual steps.
- rollback instruction.

If the target has self-integrity checks, patching bytes may cause more crashes than runtime hooks.
