#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Syncing Prisma with Neon Production..."
npx prisma db push

echo "System ready for Vercel."
