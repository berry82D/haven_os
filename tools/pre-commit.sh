#!/bin/sh
changed=$(git diff --cached --name-only)
if echo "$changed" | grep -Eq '^(lib/|android/|assets/|\.github/|pubspec\.yaml$)' && ! echo "$changed" | grep -q '^DEV_LOG.md$'; then
  echo "BLOCKED: app/build files changed but DEV_LOG.md is not staged (Law 16). Add the log entry first."
  exit 1
fi
exit 0