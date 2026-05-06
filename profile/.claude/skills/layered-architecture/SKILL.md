---
name: layered-architecture
description: Apply layered architecture principles (one-direction dependencies, leaf modules as foundation, group by reason to change, low-sitting config, ports/adapters, role-based naming) when designing modules, refactoring imports, structuring a new project or feature, or resolving circular-import issues.
---

# Layered Architecture

## 1. Dependencies flow one direction

If A → B → C, then C can import B and A, but A cannot import C. This single rule eliminates circular imports entirely.

## 2. Leaf modules are your foundation

Modules with zero internal imports are the most stable. Put shared types, constants, and pure data structures here. Everything else builds on top.

## 3. Group by reason to change

- Data shapes change when contracts change
- Clients change when external APIs change
- Business logic changes when requirements change
- Interfaces change when consumers change

Same reason to change = same module.

## 4. Configuration sits low

Config should be readable by all layers but depend on nothing. When config imports business logic, you've inverted the hierarchy.

## 5. Ports and adapters emerge naturally

- **Core**: types, business logic (pure, no I/O)
- **Adapters**: clients (outbound), servers (inbound)
- **Entry points**: CLI, main functions

The core doesn't know how it's called or what it calls.

## 6. Comments signal missing structure

Section dividers and "what" comments often mean the file is doing too much. Clear module boundaries make code self-documenting.

## 7. Name layers by role, not technology

`services/` not `openai/`. `client.py` not `http.py`. Roles are stable; technologies change.
