# Zagreb Events Aggregator

Serverless AWS system that discovers sources of public events in Zagreb, collects and enriches their events weekly, and publishes them on a static website.

- Design: [`docs/tdd.md`](docs/tdd.md)
- Plan and task list: [`docs/implementation-plan.md`](docs/implementation-plan.md)
- Working with Claude Code: [`CLAUDE.md`](CLAUDE.md)

## Getting Started

Requires Python 3.13 and GNU Make.

```sh
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
make install
make test lint typecheck
```
