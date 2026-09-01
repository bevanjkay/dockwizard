SCHEME = DockWizard
DERIVED = build/DerivedData
PACKAGE = Packages/DockWizardKit

.PHONY: generate build test lint format clean package cli dock-snapshot dock-restore

generate:
	xcodegen generate

build:
	xcodebuild -project DockWizard.xcodeproj -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO build | xcbeautify || xcodebuild -project DockWizard.xcodeproj -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO build

test:
	cd $(PACKAGE) && swift test

cli:
	cd $(PACKAGE) && swift build -c release --product dockwizard

lint:
	swiftformat --lint .
	swiftlint

format:
	swiftformat .

clean:
	rm -rf build dist $(PACKAGE)/.build

package:
	Scripts/package.sh

# Snapshot/restore your own Dock while developing. See Scripts/dev-dock.sh.
dock-snapshot:
	Scripts/dev-dock.sh snapshot

dock-restore:
	Scripts/dev-dock.sh restore
