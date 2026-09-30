#!/usr/bin/env bash
# Run from the clone; the symlink keeps using this checkout after git pull.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
SKIP_DEPS=0
for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    -h|--help)
      echo "Usage: install.sh [target_bin_dir] [--skip-deps]"
      exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

command -v bun >/dev/null 2>&1 || { echo "Install Bun first: https://bun.sh" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "The launcher requires python3." >&2; exit 1; }
if [[ "$SKIP_DEPS" -eq 0 ]]; then
  (cd "$REPO_DIR" && bun install --frozen-lockfile)
fi
mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/video-titles"
ln -sf "$REPO_DIR/video-titles" "$TARGET_DIR/video-titles"
echo "Installed $TARGET_DIR/video-titles -> $REPO_DIR/video-titles"
echo "Add $TARGET_DIR to PATH if needed. Keep this clone in place."
