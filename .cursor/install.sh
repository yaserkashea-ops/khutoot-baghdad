#!/usr/bin/env bash
# Idempotent Cloud Agent setup for the khutoot-baghdad Flutter app.
# Installs a pinned Flutter SDK, exposes it on PATH, and refreshes project
# dependencies. Safe to run repeatedly and against a warm/snapshot cache.
set -euo pipefail

FLUTTER_VERSION="3.47.3"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Ensuring system packages (git, curl, unzip, xz-utils, zip)"
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends git curl unzip xz-utils zip

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "==> Installing Flutter $FLUTTER_VERSION into $FLUTTER_HOME"
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
else
  echo "==> Flutter already present at $FLUTTER_HOME"
fi

# Flutter refuses to run from a directory it considers "dubious" ownership.
git config --global --add safe.directory "$FLUTTER_HOME" || true

# Expose flutter/dart on PATH for every agent shell and terminal without
# mutating shell profiles: /usr/local/bin is already on the default PATH.
$SUDO ln -sf "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter
$SUDO ln -sf "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart

export PATH="$FLUTTER_HOME/bin:$PATH"

echo "==> Flutter toolchain"
flutter --version

echo "==> Enabling web target and precaching web artifacts"
flutter config --enable-web --no-cli-animations >/dev/null
flutter precache --web

echo "==> Resolving project dependencies (flutter pub get)"
cd "$REPO_ROOT"
flutter pub get

echo "==> Setup complete."
