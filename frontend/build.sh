#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Install Flutter
FLUTTER_VERSION="3.16.0" # You can change this to a specific version if needed
FLUTTER_CHANNEL="stable"

# Clone Flutter repository
if [ ! -d "./flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL --depth 1
fi

# Set Flutter path
export PATH="$PATH:$(pwd)/flutter/bin"

# Enable Flutter Web
flutter config --enable-web

# Get Flutter dependencies
flutter pub get

# Build Flutter Web app
flutter build web --release
