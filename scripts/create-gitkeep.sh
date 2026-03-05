#!/usr/bin/env bash
# Create .gitkeep files to maintain directory structure in Git

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT"

echo "Creating .gitkeep files..."

dirs=(
    storage/mysql
    storage/mongodb
    storage/mongodb-restore
    storage/redis
    storage/logs
    storage/logs/nginx
    storage/logs/php
    storage/logs/supervisor
    storage/logs/credit-control
    projects
)

for d in "${dirs[@]}"; do
    mkdir -p "$d"
    touch "$d/.gitkeep" 2>/dev/null || true
done

echo "✓ .gitkeep files created"
