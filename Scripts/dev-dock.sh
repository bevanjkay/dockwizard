#!/bin/bash
# Snapshot and restore the developer's own Dock while working on DockWizard.
#
# Applying a preset to your live Dock is the only way to check some behaviour, and some
# tiles — a flexible spacer in particular — make the Dock look catastrophically broken while
# doing exactly what they are meant to. Take a snapshot before you experiment.
#
#   Scripts/dev-dock.sh snapshot   # capture the current Dock as the pristine copy
#   Scripts/dev-dock.sh restore    # put the pristine copy back
#   Scripts/dev-dock.sh status     # show what is stored
set -euo pipefail

PRISTINE_DIR="${HOME}/Library/Application Support/DockWizard/pristine"
PRISTINE="${PRISTINE_DIR}/dock-pristine.plist"

usage() {
    echo "usage: $(basename "$0") {snapshot|restore|status}" >&2
    exit 64
}

tile_counts() {
    /usr/bin/python3 - "$1" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as handle:
    plist = plistlib.load(handle)
print(f"{len(plist.get('persistent-apps', []))} apps, {len(plist.get('persistent-others', []))} others")
PY
}

case "${1:-}" in
    snapshot)
        mkdir -p "${PRISTINE_DIR}"
        if [[ -f "${PRISTINE}" ]]; then
            cp "${PRISTINE}" "${PRISTINE_DIR}/dock-pristine-$(date +%Y%m%d-%H%M%S).plist"
        fi
        defaults export com.apple.dock "${PRISTINE}"
        echo "Snapshotted $(tile_counts "${PRISTINE}") to ${PRISTINE}"
        ;;
    restore)
        [[ -f "${PRISTINE}" ]] || { echo "No pristine snapshot at ${PRISTINE}" >&2; exit 1; }
        defaults import com.apple.dock "${PRISTINE}"
        killall Dock || true
        echo "Restored $(tile_counts "${PRISTINE}")"
        ;;
    status)
        if [[ -f "${PRISTINE}" ]]; then
            echo "pristine: ${PRISTINE} ($(tile_counts "${PRISTINE}"))"
        else
            echo "pristine: none"
        fi
        ls -1t "${PRISTINE_DIR}"/dock-pristine-*.plist 2>/dev/null | head -5 || true
        ;;
    *)
        usage
        ;;
esac
