# Runtime parameters for each project

The master skill stores no concrete values. Collect or confirm the following parameters at the start of every project.

| Parameter | Required | Rule |
|---|---:|---|
| `source_software` | Yes | `spss`, `stata` or `r` |
| `source_format` | Yes | A format that matches the source software |
| `source_path` | Yes | Local path; classified as `LOCAL_ONLY` |
| `project_root` | Yes | Destination folder chosen by the user; must not be inside the skill folder |
| `synthetic_n` | Required before Gate 3 | Ask the user directly for the desired number of synthetic rows/subjects; accept only a positive integer, never infer it or set a default |
| `seed` | When generating data | A fixed integer; the skill may choose a default, which must be recorded in the project configuration |
| `special_missing_codes` | No | Empty by default; never infer from a previous project |
| `small_cell_threshold` | No | Warning default is `10`, unless project policy says otherwise |
| `synthesis_mode` | No | `schema_only` by default; `approved_aggregates` or `local_fit` require that their conditions are met |
| `output_format` | When generating data | Chosen to suit the project's tools and testing needs |

## Project configuration template

Create the following template only in `<project-root>/01_gate1_source/project_config.yaml`; never fill in real values in the master skill.

```yaml
source_software: "<spss|stata|r>"
source_format: "<format>"
synthetic_n: "<positive-integer-or-pending>"
seed: "<integer>"
special_missing_codes: []
small_cell_threshold: 10
synthesis_mode: "schema_only"
output_format: "<format>"
```

When `synthetic_n` has not been answered, record `pending` in the project configuration, repeat the question before Gate 3, and do not generate synthetic data. Record `source_path` separately in `<project-root>/01_gate1_source/source_pointer.txt` with the `LOCAL_ONLY` label. Never put this path in the shareable manifest, shared logs, AI reports or the handoff package.
