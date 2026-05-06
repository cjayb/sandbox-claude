---
name: python-conventions
description: Apply Python conventions (uv, ruff, ty, pytest, type hints, async I/O, pre-commit checklist). Triggers on `.py`/`.pyi`/`.ipynb` files, Python config files (`pyproject.toml`, `setup.py`, `requirements*.txt`, `uv.lock`, `poetry.lock`, `Pipfile`, `.python-version`, `conftest.py`), Python syntax in conversation, or mentions of pip, uv, poetry, ruff, mypy, ty, pytest, or any Python library.
---

# Python Conventions

## Tools

| Tool | Purpose |
|------|---------|
| `uv` | Package/project manager, Python versions |
| `ruff` | Linter & formatter |
| `ty` | Type checker (Astral, 10-100x faster than mypy) |
| `pytest` | Testing |

The `python` stack golden image already has `uv`, `ruff`, and `ty` installed. Use `uv add --dev pytest` if a project doesn't have it yet.

## Linter settings

- enforce line length 88 (break up long strings)
- no line-ending whitespace

## Before commit

All must pass:

- [ ] `ruff format .` — no files reformatted
- [ ] `ruff check .` — no errors
- [ ] `ty check .` — no errors
- [ ] `pytest -m unit` — unit tests passed
- [ ] No obvious comments (code should be self-documenting)
- [ ] No section divider comments (`# ====...`)
- [ ] Comments explain *why*, not *what*

## Style

```python
async def fetch_users(user_ids: list[int]) -> list[User]:
    """Fetch users by their IDs."""
    async with httpx.AsyncClient() as client:
        tasks = [client.get(f"/users/{id}") for id in user_ids]
        responses = await asyncio.gather(*tasks)
        return [User(**r.json()) for r in responses]
```

- Type annotations: always, Python 3.12+ (`list[T]`, `X | None`)
- Docstrings: brief, public APIs only
- Async for I/O

## Quick reference

| Format | Lint | Type Check | Test |
|--------|------|------------|------|
| `ruff format .` | `ruff check --fix .` | `ty check .` | `pytest -m unit` |
