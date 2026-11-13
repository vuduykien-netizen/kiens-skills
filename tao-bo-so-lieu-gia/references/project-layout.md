# Stage-based folder structure

All paths below are relative to the `<project-root>` chosen at runtime. Never write a concrete project root into the master skill.

```text
project-root/
├── 00_project_control/
│   ├── PROJECT_STATUS.md
│   ├── RUN_ORDER.md
│   ├── MANIFEST_LOCAL_ONLY.tsv
│   └── MANIFEST_SHAREABLE.tsv
├── 01_gate1_source/
│   ├── source_pointer.txt
│   ├── project_config.yaml
│   └── decisions/
├── 02_gate2_metadata/
│   ├── scripts/
│   ├── runs_pending/
│   ├── reviewed/
│   └── guides/
├── 03_gate3_synthetic/
│   ├── specification/
│   ├── scripts/
│   ├── data_pending/
│   ├── data_safe/
│   ├── validation/
│   └── guides/
├── 04_handoff/
│   ├── audit/
│   ├── package/
│   └── checksums/
└── 90_archive/
    ├── metadata_runs/
    ├── synthetic_runs/
    └── replaced_files/
```

## Status and sharing permission

| Location | Status | Shareable |
|---|---|---|
| Real data outside the project root | `LOCAL_ONLY` | No |
| `02_gate2_metadata/runs_pending` | not yet reviewed | No |
| `02_gate2_metadata/reviewed` | `SAFE_METADATA / ALLOW` | Yes |
| `03_gate3_synthetic/data_pending` | `SYNTHETIC_PENDING` | No |
| `03_gate3_synthetic/data_safe` | `SYNTHETIC_SAFE / ALLOW` | Yes |
| `90_archive` | local audit | No |

## Versioning rules

- Name runs `run_YYYYMMDD_HHMMSS`.
- Never overwrite a run folder.
- Keep only one current version in `reviewed` and one current set in `data_safe`.
- Before replacing the current version, move the old one to the archive with its original name and log.
- Record the seed in the synthetic file name or in the specification.

## Manifest

`MANIFEST_SHAREABLE.tsv` contains:

```text
path    size_bytes    sha256    classification    status
```

Do not list the manifest in itself. Do not put `source_pointer.txt`, pending items, the archive or real data in the SHAREABLE manifest.

`MANIFEST_LOCAL_ONLY.tsv` records only runtime paths and the reason for keeping them local; never read the real data to compute a checksum. Do not copy this manifest into the master skill folder.

## Status and next-step recommendation

After every stage, append this block to the end of `00_project_control/PROJECT_STATUS.md`:

```text
NEXT-STEP RECOMMENDATION
- Current status:
- Immediate action:
- How to do it and the sign it is finished:
- Following step:
- Suggested model / reasoning effort:
- Conditions for raising or lowering the configuration:
```

Record model recommendations only in the project control documents; never put model names into synthetic data, metadata, checksums or the safety classification criteria.
