#!/bin/bash
set -e

# Create empty .env if not exists (app runs without Supabase)
touch .env

# Fix git safe directory for Vercel (runs as root)
git config --global --add safe.directory /tmp/flutter
git config --global --add safe.directory '*'

# Install Flutter
curl -s https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.1-stable.tar.xz | tar xJ -C /tmp
export PATH="/tmp/flutter/bin:$PATH"
export FLUTTER_ROOT="/tmp/flutter"

# Allow running as root on Vercel
export FLUTTER_ALLOW_ROOT=true

flutter --version
flutter pub get
flutter build web --release
