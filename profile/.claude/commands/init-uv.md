---
description: Initialize a uv-based Python project in the current directory (writes files; optionally syncs if --deps is provided)
argument-hint: [--deps <pkg1,pkg2,...>]
---

Initialize a uv-based Python project in the current working directory.

Arguments: $ARGUMENTS

## Parse
- Optional flag: `--deps <pkg1,pkg2,...>` — comma-separated list of runtime dependencies to add (e.g. `--deps httpx,pydantic,typer`). Whitespace around items is trimmed; empty items are ignored. Each item may be a bare package name or include a version spec (e.g. `httpx>=0.28`).

## Derive
- `project_name` = basename of the current working directory, lowercased. Spaces → hyphens.
- `package_name` = `project_name` with hyphens replaced by underscores (Python module names can't contain `-`).
- Example: cwd = `datadog-agent-pydanticai` → `project_name = datadog-agent-pydanticai`, `package_name = datadog_agent_pydanticai`.
- `deps` = parsed list from `--deps` (may be empty).

Show the user the derived plan (`project_name`, `package_name`, `deps`, and whether `uv sync` will run) before writing.

## Pre-checks — abort on failure with a clear reason
1. If `pyproject.toml` already exists in the cwd, abort.
2. If `src/<package_name>/` already exists, abort.
3. If `deps` is non-empty, verify `uv` is on PATH (`command -v uv`); abort if missing.

## Execute — stop on first failure, do not auto-clean.
1. Write `pyproject.toml` from the template below, substituting `{{PROJECT_NAME}}` and `{{PACKAGE_NAME}}`. Leave the `dependencies` list empty here — `uv add` will populate it.
2. Create `src/<package_name>/__init__.py` (empty).
3. Create `tests/__init__.py` (empty).
4. Write `.python-version` containing `3.13`.
5. If `README.md` does not exist, write `# <project_name>\n`.
6. Ensure `.gitignore` contains the Python entries below — create the file if missing, otherwise append only the lines that are not already present.
7. **If `deps` is non-empty**: run `uv add <dep1> <dep2> ...` (single invocation, space-separated). This creates `.venv/`, resolves+locks, and writes the deps into `pyproject.toml` with their resolved minimum bounds. No separate `uv sync` is needed afterward.
8. **If `deps` is empty**: do NOT run `uv sync`, `uv lock`, or `uv venv`. Remind the user to run `uv sync` after they fill in dependencies.

On success, list the files written and report whether the venv was created.

## pyproject.toml template

```toml
[project]
name = "{{PROJECT_NAME}}"
version = "0.1.0"
description = "TODO: short description"
readme = "README.md"
authors = [
    { name = "TODO: Your Name", email = "TODO: you@example.com" }
]
requires-python = ">=3.13"
dependencies = [
    # TODO: add runtime dependencies
]

[project.scripts]
# TODO: add CLI entry points, e.g.
# {{PROJECT_NAME}} = "{{PACKAGE_NAME}}.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/{{PACKAGE_NAME}}"]

[tool.hatch.build.targets.sdist]
include = ["src/{{PACKAGE_NAME}}", "README.md", "pyproject.toml"]

[dependency-groups]
dev = [
    "pytest>=9.0.2",
    "pytest-asyncio>=1.3.0",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[tool.uv]
# Ignore any package version released within the last 7 days during dependency
# resolution. Avoids pulling in just-published releases that may be unstable,
# yanked shortly after, or not yet vetted by the ecosystem. Requires uv >= 0.9
# (ISO 8601 duration support); older uv versions need an absolute timestamp.
exclude-newer = "7 days"
```

## .gitignore entries (Python)

```
__pycache__/
*.py[cod]
*$py.class
.venv/
venv/
dist/
build/
*.egg-info/
.pytest_cache/
.ruff_cache/
.mypy_cache/
.coverage
htmlcov/
```
