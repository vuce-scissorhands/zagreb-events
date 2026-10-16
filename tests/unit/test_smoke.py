"""Smoke test: every source package imports. Replaced by real tests from T-1.1 onward."""

import importlib

import pytest

PACKAGES = ["common", "discovery", "ingestion", "authsources", "organizer_api", "publish"]


@pytest.mark.parametrize("name", PACKAGES)
def test_package_imports(name: str) -> None:
    assert importlib.import_module(name).__doc__
