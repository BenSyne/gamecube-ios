# Contributing to the iPhone/iPad build

Thanks for helping make the iOS build easier to reproduce and safer to use.
The upstream project guidance in [`Contributing.md`](../Contributing.md) still
applies; this page adds the public-source and validation rules for this branch.

## Never include private or copyrighted material

Do not open an issue, commit, or upload containing:

- commercial game images, firmware, keys, BIOS/IPL dumps, or copyrighted cover
  art;
- Apple credentials, certificates, private keys, provisioning profiles,
  developer-team IDs, Apple IDs, device identifiers, or device pairing files;
- user saves, crash logs with private paths, or generated build products.

Use the pinned open-source Wii-donut fixture for reproducible emulator tests.
Describe testing with commercial software only by title and observed behavior;
never attach the software itself.

## Set up and validate

```sh
Tools/iOS/readiness.sh
Tools/iOS/bootstrap.sh --mode check --install
Tools/iOS/bootstrap.sh --mode simulator --install
Tools/iOS/audit_public_release.sh
```

The simulator smoke test must pass its import, Metal render, touch, pause,
save/load, stop, JIT-gate, and performance-warning checks. For device-specific
changes, also complete the relevant rows in
[`iOS_TEST_MATRIX.md`](iOS_TEST_MATRIX.md).

## Pull requests

- Explain what changed, why, and the exact checks run.
- Name device models and OS versions, but never include UDIDs or team IDs.
- Keep `AGENTS.md` and `CLAUDE.md` byte-identical.
- Preserve GPL-2.0-or-later and third-party notices.
- Separate verified results from assumptions and compatibility limitations.
