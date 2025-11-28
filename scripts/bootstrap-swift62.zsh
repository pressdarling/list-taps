#!/usr/bin/env zsh
set -euo pipefail

require_swift="6.2"
product="list-taps"

have_swift=$(swift --version 2>/dev/null | head -n1 | awk '{print $3}')
echo "Swift: $have_swift"
if ! swift --version | grep -q "$require_swift"; then
  echo "Warning: expecting Swift $require_swift (Xcode 26.x)."
  echo "Current: $(swift --version)"
  echo "Trying to select Xcode…"
  # Adjust path to your Xcode if needed:
  sudo xcode-select -s /Applications/Xcode.app || true
  swift --version | grep -q "$require_swift" || {
    echo "Still not on Swift $require_swift. Check Xcode 26.x install."; exit 1;
  }
fi

# Accept license if needed
sudo xcodebuild -license accept >/dev/null 2>&1 || true

echo "Building $product (release)…"
swift build -c release -v

echo "Installing with SwiftPM…"
swift package experimental-install

binpath="${HOME}/.swiftpm/bin/${product}"
if [[ -x "$binpath" ]]; then
  echo "Installed: $binpath"
  echo "Example: $binpath --json | jq ."
else
  echo "Install failed; falling back to copying."
  cp -f .build/release/${product} /usr/local/bin/${product}
  echo "Installed: /usr/local/bin/${product}"
fi
