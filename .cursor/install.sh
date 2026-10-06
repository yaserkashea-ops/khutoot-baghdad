#!/usr/bin/env bash
# Idempotent Cloud Agent setup for the "خطوط بغداد" (masarat) Flutter web app.
# Installs the Flutter SDK if missing, exposes flutter/dart on the default PATH,
# and refreshes project dependencies. Safe to run repeatedly.
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

# 1) Install the Flutter SDK if it is not already present.
#    The stable channel satisfies pubspec.lock (Flutter >=3.44.0, Dart >=3.13.0).
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "==> Installing Flutter ($FLUTTER_CHANNEL) into $FLUTTER_HOME"
  git clone --depth 1 -b "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# 2) Make flutter/dart resolvable from any shell or terminal without touching
#    shell profiles. Falls back silently if /usr/local/bin is not writable.
if command -v sudo >/dev/null 2>&1 && [ -d /usr/local/bin ]; then
  sudo ln -sf "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter || true
  sudo ln -sf "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart || true
fi

# 3) Non-interactive configuration and web enablement (idempotent).
flutter --disable-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true

# 4) Resolve project dependencies against the committed pubspec.lock.
flutter pub get

# 5) Warm the web engine artifacts so the first `flutter run`/`build` is fast.
flutter precache --web >/dev/null 2>&1 || true

echo "==> Flutter ready: $(flutter --version | head -1)"
