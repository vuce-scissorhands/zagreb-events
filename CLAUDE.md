# CLAUDE.md

## Context

This repository implements the Zagreb Events Aggregator. It is a serverless AWS system in `eu-central-1`. A monthly pipeline (`source-discovery`) finds, scores and validates web sources that publish public events in Zagreb, and maintains the source registry. A weekly pipeline (`event-ingestion`) scrapes those sources, extracts, deduplicates and geocodes events, enriches them with Claude Haiku 4.5 on Amazon Bedrock, and publishes a static dataset and website behind CloudFront. The priorities, in order, are cost (≤ USD 25 per month), internal data isolation, public website resilience and full automation.

`docs/tdd.md` is the authoritative design. If code and the TDD disagree, the TDD wins, unless the pull request updates the TDD in the same change. Requirement IDs (`FR-xx`, `NFR-xx`) come from `docs/tdd.md`. Task IDs (`T-x.y`) and "Done when" conditions come from `docs/implementation-plan.md`.

## Commands

| Command | Purpose |
|---|---|
| `make install` | Editable install with all Lambda extras and dev tools |
| `make test` | Unit tests with coverage. Network is disabled and the eval set is excluded |
| `make lint` | `ruff check` and `ruff format --check` |
| `make typecheck` | `mypy` in strict mode over `src/` and `tests/` |
| `make fixtures` | Record HTML fixtures per source (implemented in T-0.11) |
| `make eval` | Run the FR-20 evaluation set against Bedrock. Only when asked |
| `terraform -chdir=infra/<stack> plan` | Plan one stack: `bootstrap`, `data`, `pipeline` or `edge` |

Run a single test with `python -m pytest tests/unit/<file>.py::<test_name>`.
Before you report a task as done, run `make test lint typecheck` and fix every failure.

## Repository Layout

| Path | Content |
|---|---|
| `src/common/` | pydantic models (`models.py`), S3/DynamoDB/SSM clients, logging, URL normalization |
| `src/discovery/` | Monthly pipeline handlers (`seed_sources`, `safety_check`, `score_sources`, ...) |
| `src/ingestion/` | Weekly pipeline handlers (`scrape_source`, `clean_extract`, `enrich`, ...) |
| `src/authsources/` | `fetch_authenticated_source`, `refresh_credentials` |
| `src/organizer_api/` | `organizer_api` handler |
| `src/publish/` | `quality_gate`, `build_site_data`, `templates/` |
| `config/` | `taxonomy.yaml`, `seed_sources.yaml`, `event_path_patterns.yaml`, `source_scoring.yaml`, ... |
| `statemachines/` | Step Functions ASL definitions (JSON, templated) |
| `containers/` | Dockerfiles for container-image Lambdas |
| `tests/unit/`, `tests/fixtures/`, `tests/eval/` | Unit tests, recorded responses per source, labeled evaluation set |
| `frontend/` | Vite + TypeScript website |
| `infra/` | Terraform stacks `bootstrap`, `data`, `pipeline`, `edge` and shared `modules/` |
| `docs/` | `tdd.md`, `implementation-plan.md`, `adr/` |

## Conventions

- Python 3.13 with full type hints. `mypy --strict` must pass. Do not use `Any` in a public signature without a comment that explains why.
- Use the pydantic v2 models from `src/common/models.py` for registry entries and event records. Do not define parallel dicts or TypedDicts for the same data.
- One Lambda handler per module, named `handler(event, context)`. The handler parses its input into models, calls pure functions and returns. Logic lives in pure functions that can be tested without AWS.
- No network access in unit tests. Use recorded fixtures from `tests/fixtures/<source_id>/` and `moto` for AWS. `pytest-socket` enforces this.
- Datetimes are timezone-aware. Event times use `Europe/Zagreb` (TDD 3.4.2).
- Log structured JSON through `src/common` with `run_id`, `source_id` and `event_id`. Never log, return or store secrets, tokens or credentials anywhere except Parameter Store (NFR-SEC7, NFR-SEC13). Step Functions state carries parameter names only.
- Read tunable values (taxonomy, path patterns, scoring weights, thresholds) from `config/*.yaml`. Do not hardcode them.
- LLM calls use the Bedrock `Converse` API with a tool-use JSON schema, `temperature` 0 and input truncated to 6,000 characters. Read the model ID from `/events/llm/model_id`. Never hardcode it (TDD 3.2.3).
- Terraform: version ≥ 1.10, AWS provider ≥ 6.0. Use `infra/modules/lambda_function` for every function, arm64, a 14-day log retention and a dedicated least-privilege IAM role (NFR-SEC1).

## Terminology

Use the terms in TDD Section 1.4 (`docs/tdd.md`) and use them in code identifiers: `source`, `source_registry`, `candidate`, `discovery_channel`, `content_owner`, `connected_page`, `source_status`, `source_type`, `source_score`, `raw_event`, `filtered_event`, `enriched_event`, `event_id`, `dataset`, `last_known_good_dataset`. Use the enumeration values exactly as the TDD defines them, for example `probation | active | disabled | blocked`. `yield` is a Python keyword, so name the metric `yield_count`.

## Task Workflow

Follow `docs/implementation-plan.md` Section 5.2. Work on one task ID at a time and stay inside its scope. Write the failing tests against the "Done when" condition first, then the implementation. Each pull request references its task ID and TDD requirement IDs. If the implementation changes the design, update `docs/tdd.md` in the same pull request. Record non-obvious decisions as an ADR in `docs/adr/`.

## Prohibitions

- Do not run `terraform apply`, in any form (including `terraform -chdir=... apply`), and do not run `terraform destroy`. Deployment happens only through `.github/workflows/deploy.yml`.
- Do not read or print values from Parameter Store, by CLI (`aws ssm get-parameter*`) or ad-hoc scripts. Referring to parameter names in code is fine.
- Do not modify anything in `tests/eval/`.
- Do not add dependencies without listing them in the pull request description, with the `pyproject.toml` extra they belong to.
