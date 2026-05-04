#!/usr/bin/env bash
# stacks/python.sh — Python quality/coverage/dependency tools
# Runs INSIDE container after base.sh
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "Installing Python stack..."

# uv — fast package installer, resolver, and project manager (installed as ubuntu)
su - ubuntu -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# Quality tools (linting+formatting, type checking, security, coverage)
# installed via uv tool — each gets an isolated venv, executables on ubuntu's PATH
su - ubuntu -c 'for pkg in ruff ty bandit coverage; do uv tool install "$pkg"; done'

echo "Python stack complete"
