---
name: tao-bo-so-lieu-gia
description: Reusable master skill that orchestrates a three-gate workflow for creating a safe synthetic dataset from the structure of an SPSS, Stata or R dataset, without ever sending real records to an AI. It manages runtime parameters, stage-based folders, pending/reviewed/safe status, archives, manifests and the handoff package. Use it across different datasets and project roots when you need to extract metadata locally, generate synthetic data for developing and testing code, run privacy checks, or prepare a reproducible shareable package.
---

# Synthetic Dataset Builder

Operate as a master skill that is independent of any single project. Follow the three gates and the handoff step exactly. Treat the original data as `LOCAL_ONLY`: never open, read, upload or copy it, and never ask the user to paste real records into the AI environment.

## Master skill boundary and project configuration

Never write any runtime value into the skill folder: source paths, source file names, project root, user names, drive letters, metadata, seeds, sample sizes, missing-value codes, timestamps or the outputs of a project. Keep only instructions, placeholders, reference documents and scripts that take parameters.

When starting a new project, read `references/runtime-parameters.md` and collect at least:

- `source_software` and `source_format`;
- `source_path`, for local use only;
- `project_root`, chosen by the user;
- `synthetic_n`, confirmed by the user before Gate 3;
- `seed`, `special_missing_codes`, `small_cell_threshold`, `synthesis_mode` and `output_format` when needed.

Ask directly: **"How many rows (how many subjects) should the synthetic dataset have?"** Record the answer as `synthetic_n` only if it is a positive integer. Do not infer it from the number of rows in the original data, do not reuse a value from a previous project or conversation, and do not set a default on the user's behalf. If there is no answer yet, record `synthetic_n: pending`, remind the user before Gate 3, and do not start generating synthetic data. If another parameter that affects the code is missing, ask briefly; never ask for sample records. Store each project's configuration inside its project root and never write it back into the master skill folder.

Every path in the master documentation and scripts must be relative or a placeholder such as `<project-root>` and `<source-path>`. Utility scripts must receive the project root through a required parameter and must not guess the current working directory.

## Project folder management

After receiving `project_root` at runtime, read `references/project-layout.md` and create the standard structure beneath it before generating any output. If the project root already has content, build an inventory and a move map first; never overwrite or delete automatically.

Manage files along this flow:

```text
pending -> reviewed/safe -> handoff
              |
              +-> archive when superseded
```

Mandatory rules:

- Never place real data in the project root. `01_gate1_source/source_pointer.txt` is only a `LOCAL_ONLY` runtime file and is not part of the master skill or the shareable package.
- Every run creates a new timestamped folder; nothing is overwritten.
- Move only metadata rated `SAFE_METADATA / allow` into `02_gate2_metadata/reviewed`.
- Freshly generated synthetic files stay in `03_gate3_synthetic/data_pending`.
- Move only files rated `SYNTHETIC_SAFE / allow` into `03_gate3_synthetic/data_safe`.
- Move old runs and superseded files into `90_archive`; the archive is not part of the shareable package.
- Update `00_project_control/PROJECT_STATUS.md` after every gate.
- Find and fix hard-coded paths before moving files.
- On Windows, verify that the absolute path lies inside the project root and then use PowerShell `-LiteralPath`; never delete recursively with an unchecked path.

## Mandatory next-step recommendation

After every stage, including when the result is `PASS`, `PENDING`, `FAIL` or blocked, update `00_project_control/PROJECT_STATUS.md` and give the user a **Next-step recommendation** block containing:

- the current status and any missing conditions;
- the immediate action, a short how-to, and the sign that it is finished;
- the step that follows once the immediate action is done, so the user can see the road ahead;
- the suggested model and reasoning effort, with the conditions for raising or lowering them.

Read `references/model-effort-routing.md` before making a recommendation. Check which models are actually available at runtime; never claim that a particular model name is permanently optimal. Prefer the smallest configuration that still meets the safety and quality requirements, and raise the model or effort as complexity, privacy risk or validation requirements grow. The recommendation is operational guidance only: never change the model or incur cost on the user's behalf.

## 1. Identify the type of the original dataset

First ask one short question: **"Is the original dataset stored in SPSS, Stata or R?"**

Once you have the answer, confirm the expected format:

- SPSS: `.sav` plus `.sps` scripts.
- Stata: `.dta` plus `.do` scripts.
- R: `.rds`, `.RData` or any format readable by R, with `.R` scripts.

After the software and format are known, ask for the local path and any special missing-value codes, and always ask: **"How many rows (how many subjects) should the synthetic dataset have?"** Do not substitute the sample size of the original data or a default value for the answer. You may leave `synthetic_n: pending` while moving on to metadata extraction, but you must ask again before generating. Never ask for the real file, Data Editor screenshots, sample records, IDs or free text.

Write the non-sensitive run configuration to `01_gate1_source/project_config.yaml`, and write the source path to `source_pointer.txt` with the `LOCAL_ONLY` label. These two files belong to the running project, not to the master skill. Do not compute checksums and do not copy the source file.

**Gate 1:** move on only when the software and format are known, the synthetic sample size has been asked, and the user understands that the real file stays local. Gate 2 may proceed while `synthetic_n` is still `pending`, but Gate 3 is blocked until the user confirms a positive integer.

Issue a **Next-step recommendation** block for creating and running the metadata script and for previewing the metadata safety review.

## 2. Write the code that extracts variables and the data model

Apply `$trich-xuat-cau-truc-du-lieu-local` to create a read-only script in `02_gate2_metadata/scripts`. The script must:

1. Never overwrite the source data and never output any data row.
2. Capture variable names, non-sensitive labels, types, formats, observation counts, missing counts and proportions, and coarsened ranges.
3. For categorical variables, output only codes and pooled frequencies; by default mask any group with `n < 10`.
4. Only flag the existence of IDs, detailed dates, addresses, coordinates and free text; never output their values.
5. Describe marginal distributions, dependency relationships, derived variables, questionnaire branching, time and cluster relationships, and missing-data rules.
6. If estimation from the real data is needed, fit the model and generate the data within the same local workflow; never export rare parameters from which an individual could be inferred.
7. Record each run in `02_gate2_metadata/runs_pending/<timestamp>` with the metadata, the specification and a self-check log.

For SPSS scripts, prefer omitting the `WINDOW` option from `DATASET NAME`; if it must be specified, use `WINDOW=ASIS`. Never use `WINDOW=HIDDEN`: SPSS 27 stops the command because it accepts only `FRONT` or `ASIS`. Before handing over an `.sps` file, search for the string `WINDOW=HIDDEN`; if it is still there, treat the compatibility check as `FAIL` and fix it before the user runs the script.

Use the safest mode that is sufficient for the goal:

- `schema_only`: the default; simulate from types, domains and rules.
- `approved_aggregates`: use only aggregate figures that have been approved.
- `local_fit`: only when complex relationships genuinely need to be preserved; both model learning and data generation run locally.

Apply `$kiem-tra-an-toan-du-lieu`. When the review passes, move the entire run folder into `02_gate2_metadata/reviewed`; if a current version already exists, first move the old one to `90_archive/metadata_runs`.

**Gate 2:** do not pass metadata to an AI if it contains IDs, data rows, free-text strings, detailed dates or addresses, lists of unique values, or rare combinations that have not been pooled.

Issue a **Next-step recommendation** block for specifying and generating the synthetic data and for previewing the Gate 3 checks.

## 3. Generate and validate the synthetic dataset

Start only when `synthetic_n` is a positive integer confirmed by the user in `project_config.yaml`. If it is still `pending`, ask again: **"How many rows (how many subjects) should the synthetic dataset have?"** and stop before Gate 3. Apply `$mo-phong-du-lieu-nghien-cuu`. Store the specification in `03_gate3_synthetic/specification`, the scripts in `scripts` and the guides in `guides`. The code must:

1. Use a fixed seed and create entirely fake IDs.
2. Match the schema, coding, domains, missing data, logical constraints and the relationships needed to run a trial analysis.
3. Never copy real records; never choose `local_fit` automatically just to make the data look "realistic".
4. Create edge cases such as missing values, sparse groups and boundary values where appropriate.
5. Label files, logs and reports with `SYNTHETIC—NOT FOR SCIENTIFIC INFERENCE`.
6. Write newly generated files to `03_gate3_synthetic/data_pending` and write validation output to `03_gate3_synthetic/validation`.

If `local_fit` is used, require local checks for exact and near duplicates, unique quasi-identifier combinations, rare groups, extreme values and nearest-neighbour distance against the real data.

Apply `$kiem-tra-an-toan-du-lieu`. When every check reaches `SYNTHETIC_SAFE / allow`, move the file from `data_pending` to `data_safe`. Files that fail or are superseded go to `90_archive/synthetic_runs`.

**Gate 3:** if validation is not finished, keep the status `SYNTHETIC_PENDING` in `data_pending` and do not advise uploading the file to an AI.

Issue a **Next-step recommendation** block for fixing and re-validating or for packaging the handoff, and preview the final audit.

## 4. Package the handoff

Start only after Gate 3. Create:

- `00_project_control/RUN_ORDER.md`;
- `00_project_control/MANIFEST_LOCAL_ONLY.tsv`;
- `00_project_control/MANIFEST_SHAREABLE.tsv`;
- `04_handoff/audit/FINAL_AUDIT_REPORT.md`;
- `04_handoff/checksums/` when separate checksum files are needed;
- `04_handoff/package/`, containing only the frozen copy taken from the SHAREABLE manifest.

Never put `runs_pending`, `data_pending`, `90_archive`, real data or linkage keys into the shareable package.

Use the bundled scripts once the structure is complete:

```powershell
& '<skill-dir>\scripts\build-shareable-manifest.ps1' -ProjectRoot '<project-root>'
& '<skill-dir>\scripts\verify-package.ps1' -ProjectRoot '<project-root>'
```

Conclude that the handover is complete only when the checksums match, no legacy paths remain, validation is `PASS`, the classification is `SYNTHETIC_SAFE / ALLOW`, and no real data file is present in the project root.

After the handoff, issue a **Next-step recommendation** block covering how to rerun the work reproducibly, safe archiving and versioning, and the next suitable analysis step; always remind the user that synthetic data must not be used for scientific inference.

## Reusability check for the master skill

After editing the skill, check the entire skill folder before sharing it:

- no absolute paths, source file names, project roots or user-specific information;
- no metadata, data or outputs from a single project;
- examples use placeholders only;
- utility scripts require input parameters and do not depend on the current working directory;
- SPSS scripts do not contain `WINDOW=HIDDEN`; use `WINDOW=ASIS` or omit the `WINDOW` option;
- `agents/openai.yaml` describes general usage;
- the instructions for every gate lead to a recommendation block with the immediate action, the following step, and the model and effort per `references/model-effort-routing.md`;
- the skill passes `quick_validate.py`, and the bundled scripts have been tested with temporary fixtures that contain no real data.

## Required output

Return:

- the folder structure and the status of each gate;
- the confirmed `synthetic_n` answer, obtained before any synthetic data is generated;
- the local scripts that extract the structure and model;
- instructions for running and reviewing the metadata;
- the specification and the script that generates the synthetic data;
- the synthetic file in `data_safe` if the gate has been passed;
- the validation report and the safety classification;
- RUN_ORDER, both manifests, checksums and the audit at handoff;
- a **Next-step recommendation** block after every stage, including the immediate step, the step after that, and the suggested model and reasoning effort;
- a warning that synthetic data is only for developing and testing code and must not be used for scientific inference or for reporting research results.

If the user cannot yet run the local scripts, stop at the code and instructions; never invent metadata, parameters or results from the original data.
