PYTHON ?= python
STACK ?= data
.PHONY: install test lint format typecheck check fixtures eval audit plan

install:
	$(PYTHON) -m pip install -e ".[all,dev]"
test:
	$(PYTHON) -m pytest --cov --cov-report=term-missing
lint:
	$(PYTHON) -m ruff check .
	$(PYTHON) -m ruff format --check .
format:
	$(PYTHON) -m ruff check --fix .
	$(PYTHON) -m ruff format .
typecheck:
	$(PYTHON) -m mypy
check: lint typecheck test
fixtures:
	@echo "Fixture recording is not implemented yet (T-0.11)." && exit 1
eval:
	$(PYTHON) -m pytest -m eval --force-enable-socket --no-cov tests/eval
audit:
	$(PYTHON) -m pip_audit
plan:
	terraform -chdir=infra/$(STACK) plan