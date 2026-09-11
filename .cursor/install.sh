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
# These packages ship in the default base image, so apt is only needed on
# leaner bases. Skip it entirely when everything is already present: that keeps
# setup fast and avoids a flaky/unreachable apt mirror blocking Flutter setup.
need_apt=0
for tool in git curl unzip xz; do
  command -v "$tool" >/dev/null 2>&1 || need_apt=1
done
if [ "$need_apt" = "1" ]; then
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y -o Acquire::Retries=2 \
    || echo "warn: apt-get update reported errors; continuing"
  $SUDO apt-get install -y --no-install-recommends git curl unzip xz-utils zip \
    || echo "warn: apt-get install reported errors; continuing"
else
  echo "System packages already present; skipping apt."
fi

missing=""
for tool in git curl unzip xz; do
  command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
done
if [ -n "$missing" ]; then
  echo "error: required tools missing and could not be installed:$missing" >&2
  exit 1
fi

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "==> Installing Flutter $FLUTTER_VERSION into $FLUTTER_HOME"
  archive_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  echo "    downloading $archive_url"
  curl -fSL --retry 3 --retry-delay 5 -o "$tmp_dir/flutter.tar.xz" "$archive_url"
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  # The official archive extracts to a top-level "flutter/" directory.
  tar -xf "$tmp_dir/flutter.tar.xz" -C "$(dirname "$FLUTTER_HOME")"
  rm -rf "$tmp_dir"
  trap - EXIT
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
