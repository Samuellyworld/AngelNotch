#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

swift format lint app/Package.swift
swift format lint --recursive app/sources
find app/sources/angelnotch -name '*.swift' -print0 \
  | sort -z \
  | xargs -0 swiftc -frontend -parse

echo "AngelNotch Swift lint passed."
