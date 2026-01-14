#!/usr/bin/env bash
set -euo pipefail

prompt_yes_no() {
  local prompt="$1"
  local resp
  read -r -p "${prompt} [y/N] " resp || true
  resp="$(printf "%s" "$resp" | tr '[:upper:]' '[:lower:]')"
  case "$resp" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

append_line_if_missing() {
  local file="$1"
  local line="$2"
  touch "$file"
  if ! grep -Fxq "$line" "$file"; then
    printf '%s\n' "$line" >> "$file"
  fi
}

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required for this setup. Install it from https://brew.sh and rerun."
    return 1
  fi
}

ensure_java() {
  if command -v java >/dev/null 2>&1; then
    return 0
  fi
  if ! prompt_yes_no "Java/JDK not found. Install JDK 17 now?"; then
    return 0
  fi
  ensure_brew
  brew install openjdk@17
  local java_home
  java_home="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  if [ -n "$java_home" ]; then
    export JAVA_HOME="$java_home"
    append_line_if_missing "$HOME/.zprofile" "export JAVA_HOME=$java_home"
    append_line_if_missing "$HOME/.zprofile" 'export PATH="$JAVA_HOME/bin:$PATH"'
  fi
}

install_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    echo "Flutter already installed."
    return 0
  fi
  echo "Flutter SDK not found. If flutter is already installed, ensure it's in your PATH."
  if ! prompt_yes_no "Would you like to install Flutter?"; then
    return 0
  fi
  ensure_brew
  brew install --cask flutter
}

find_android_tool() {
  local tool="$1"
  local root
  if command -v "$tool" >/dev/null 2>&1; then
    command -v "$tool"
    return 0
  fi
  for root in "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk"; do
    if [ -n "$root" ]; then
      if [ -x "$root/cmdline-tools/latest/bin/$tool" ]; then
        echo "$root/cmdline-tools/latest/bin/$tool"
        return 0
      fi
      if [ -x "$root/cmdline-tools/bin/$tool" ]; then
        echo "$root/cmdline-tools/bin/$tool"
        return 0
      fi
    fi
  done
  for root in /opt/homebrew/Caskroom/android-commandlinetools/* \
              /usr/local/Caskroom/android-commandlinetools/*; do
    if [ -x "$root/cmdline-tools/bin/$tool" ]; then
      echo "$root/cmdline-tools/bin/$tool"
      return 0
    fi
  done
  return 1
}

setup_android() {
  if ! prompt_yes_no "Install Android SDK + platform-tools + build-tools?"; then
    return 0
  fi
  ensure_java
  ensure_brew
  brew install --cask android-commandlinetools
  local sdk_root="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
  export ANDROID_SDK_ROOT="$sdk_root"
  export ANDROID_HOME="$sdk_root"
  append_line_if_missing "$HOME/.zprofile" "export ANDROID_SDK_ROOT=$sdk_root"
  append_line_if_missing "$HOME/.zprofile" "export ANDROID_HOME=$sdk_root"
  local sdkmanager_path
  sdkmanager_path="$(find_android_tool sdkmanager || true)"
  if [ -z "$sdkmanager_path" ]; then
    echo "sdkmanager not found. Ensure Android command line tools are installed and configured."
    return 0
  fi
  "$sdkmanager_path" --sdk_root="$sdk_root" --install \
    "platform-tools" \
    "platforms;android-34" \
    "platforms;android-36" \
    "build-tools;34.0.0" \
    "build-tools;36.0.0" \
    "build-tools;28.0.3"
  "$sdkmanager_path" --sdk_root="$sdk_root" --licenses
}

setup_avd() {
  if ! prompt_yes_no "Create a default Android emulator (AVD)?"; then
    return 0
  fi
  local sdk_root="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
  local sdkmanager_path
  local avdmanager_path
  sdkmanager_path="$(find_android_tool sdkmanager || true)"
  avdmanager_path="$(find_android_tool avdmanager || true)"
  if [ -z "$sdkmanager_path" ] || [ -z "$avdmanager_path" ]; then
    echo "Android tools not found; skipping AVD creation."
    return 0
  fi
  "$sdkmanager_path" --sdk_root="$sdk_root" --install \
    "system-images;android-34;google_apis;x86_64"
  "$avdmanager_path" create avd -n pixel_api34 \
    -k "system-images;android-34;google_apis;x86_64" \
    -d pixel_5 --device pixel_5 --sdcard 512M --force
}

enable_web() {
  if prompt_yes_no "Enable Flutter web support?"; then
    flutter config --enable-web
  fi
}

enable_android() {
  if prompt_yes_no "Enable Flutter Android support?"; then
    flutter config --enable-android
  fi
}

enable_desktop() {
  if prompt_yes_no "Enable macOS desktop (requires Xcode tools)?"; then
    flutter config --enable-macos-desktop
  fi
}


ensure_frontend_platforms() {
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local frontend="$repo_root/frontend"
  if [ ! -d "$frontend" ]; then
    return 0
  fi

  local needs_android=0
  local needs_web=0
  if [ ! -d "$frontend/android" ]; then
    needs_android=1
  fi
  if [ ! -d "$frontend/web" ]; then
    needs_web=1
  fi
  if [ $needs_android -eq 0 ] && [ $needs_web -eq 0 ]; then
    return 0
  fi

  local platforms=()
  if [ $needs_android -eq 1 ]; then
    platforms+=("android")
  fi
  if [ $needs_web -eq 1 ]; then
    platforms+=("web")
  fi
  local platform_arg
  platform_arg="$(IFS=,; echo "${platforms[*]}")"

  echo "Generating missing Flutter platforms in $frontend ($platform_arg)..."
  (cd "$frontend" && flutter create --platforms "$platform_arg" .)
}

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script targets macOS. Run scripts/flutter-setup.ps1 on other platforms."
  exit 1
fi

install_flutter
flutter --version
setup_android
setup_avd
enable_android
enable_web
enable_desktop
echo
echo "Running flutter doctor..."
flutter doctor -v
ensure_frontend_platforms
echo
echo "Restart your shell if PATH changes do not take effect."
