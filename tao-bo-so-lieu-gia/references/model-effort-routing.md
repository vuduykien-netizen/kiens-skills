# Model and reasoning-effort routing

Base every recommendation on the models that are actually available at runtime. If the model names differ from the table below, map them by role: `efficient`, `balanced` or `frontier`. When current information is uncertain, use `$openai-docs` to check before naming a model.

## Principles

- Start with the smallest configuration that can meet the completion criteria.
- Use `low` for routine, unambiguous tasks where speed matters.
- Use `medium` as the balanced default for writing scripts and multi-step work.
- Raise to `high` or `xhigh` only when complexity, privacy risk or real-world validation shows a benefit.
- Recommend `max` only for the hardest cases where quality is the priority and there are clear evaluation criteria; compare it with `xhigh` first.
- Recommend Pro mode only for hard, high-value audits where the expected quality gain justifies the latency and cost; never for routine work.

## Preferred mapping when GPT-5.6 is available

| Role | Model | Baseline effort | Use for |
|---|---|---|---|
| `efficient` | `gpt-5.6-luna` | `low` | Collecting parameters, updating status, simple run instructions |
| `balanced` | `gpt-5.6-terra` | `medium` | Writing standard scripts, `schema_only` generation, manifests and routine checks |
| `frontier` | `gpt-5.6-sol` | `high` | Privacy work, complex debugging, multi-variable constraints and the final audit |

## Defaults by stage

| Stage | Default recommendation | Raise the configuration when |
|---|---|---|
| Gate 1 — identify source and configuration | `efficient / low` | The source, scope or privacy boundary is ambiguous: `balanced / medium` |
| Gate 2 — write the metadata script | `balanced / medium` | Multi-version syntax, a complex schema or a hard-to-reproduce error: `frontier / high` |
| Gate 2 — metadata safety review | `frontier / high` | Small population or rare disease, many quasi-identifiers, or `local_fit`: `frontier / xhigh` |
| Gate 3 — generate `schema_only` | `balanced / medium` | Many branches, clusters, time structure or derived variables: `frontier / high` |
| Gate 3 — privacy validation | `frontier / high` | `local_fit`, near-duplicates or rare combinations that are hard to assess: `frontier / xhigh` |
| Handoff — manifest and checksums | `balanced / medium` | Auditing many files or inconsistent errors: `frontier / high` |
| High-quality final audit | `frontier / high` | Consider `xhigh`, `max` or Pro mode only when the evaluation criteria and the added value are clear |

## Reply template after every stage

```text
Next-step recommendation
- Current status: <PASS|PENDING|FAIL and why>
- Immediate action: <one concrete action>
- How to do it and the sign it is finished: <short instructions + stopping condition>
- Following step: <a preview of the next step>
- Suggested model / effort: <role; available model name; effort>
- Adjustment conditions: <when to raise or lower the configuration>
```
