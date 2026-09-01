#!/usr/bin/env bash
# Runs the preferences integration tests against a throwaway domain.
#
# These never touch com.apple.dock. They prove that the Dock's nested array-of-dictionaries
# structure survives a real CFPreferences round trip, which the in-memory fake cannot show.
set -euo pipefail

cd "$(dirname "$0")/.."
DOMAINS=("me.bevankay.dockwizard.test.state" "me.bevankay.dockwizard.test.settings")

cleanup() {
    for domain in "${DOMAINS[@]}"; do
        defaults delete "$domain" >/dev/null 2>&1 || true
    done
}
trap cleanup EXIT

cd Packages/DockWizardKit
DOCKWIZARD_INTEGRATION=1 swift test --filter PreferencesIntegrationTests
