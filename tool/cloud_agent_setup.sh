#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the "خطوط بغداد" (khutoot-baghdad) Flutter app.
#
# Installs a pinned Flutter SDK if it is not already present, exposes the
# flutter/dart binaries on PATH, and refreshes project dependencies. Safe to run
# repeatedly: an existing SDK is reused and only `flutter pub get` re-runs.
set -euo pipefail

FLUTTER_VERSION="3.47.4"
FLUTTER_HOME="/opt/flutter"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

install_flutter() {
  echo "==> Installing Flutter ${FLUTTER_VERSION} to ${FLUTTER_HOME}"
  local tmp
  tmp="$(mktemp -d)"
  curl -fSL "${FLUTTER_URL}" -o "${tmp}/${FLUTTER_ARCHIVE}"
  ${SUDO} rm -rf "${FLUTTER_HOME}"
  ${SUDO} tar -xf "${tmp}/${FLUTTER_ARCHIVE}" -C /opt
  ${SUDO} chown -R "$(id -u):$(id -g)" "${FLUTTER_HOME}" || true
  rm -rf "${tmp}"
}

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  install_flutter
else
  echo "==> Reusing existing Flutter SDK at ${FLUTTER_HOME}"
fi

# Make flutter/dart available on the default PATH without mutating shell profiles.
${SUDO} ln -sf "${FLUTTER_HOME}/bin/flutter" /usr/local/bin/flutter
${SUDO} ln -sf "${FLUTTER_HOME}/bin/dart" /usr/local/bin/dart

# Flutter refuses to run inside a git repo it does not trust.
git config --global --add safe.directory "${FLUTTER_HOME}" || true

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter config --no-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true

# Warm the web toolchain so the first `flutter run`/`flutter build web` is fast.
flutter precache --web >/dev/null 2>&1 || true

cd "${REPO_ROOT}"
flutter pub get

echo "==> Cloud Agent setup complete: $(flutter --version | head -n 1)"
