BUILD_DIR=docs

# Use uv if available
UV ?= $(shell command -v uv 2> /dev/null)

PIP := $(if $(UV),$(UV) pip,pip)
PYTHON := $(if $(shell test -d .venv && echo yes),.venv/bin/python,python)

.PHONY: setup serve build

.venv:
ifeq ($(UV),)
	$(PYTHON) -m venv .venv
else 
	uv venv
endif

setup: .venv
	$(PIP) install -r requirements.txt

serve:
	$(PYTHON) -m mkdocs serve --livereload

build:
	$(PYTHON) -m mkdocs build --site-dir $(BUILD_DIR)

