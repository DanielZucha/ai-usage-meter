# The Command Line Tools' SwiftPM does not wire in swift-testing on its own:
# it passes the framework directory with -I instead of -F and adds no rpath.
# When Xcode's toolchain is selected the directory is absent and no flags
# are added.
CLT_DEV := /Library/Developer/CommandLineTools/Library/Developer
ifneq ($(wildcard $(CLT_DEV)/Frameworks/Testing.framework),)
TEST_FLAGS := -Xswiftc -F -Xswiftc $(CLT_DEV)/Frameworks \
	-Xlinker -rpath -Xlinker $(CLT_DEV)/Frameworks \
	-Xlinker -rpath -Xlinker $(CLT_DEV)/usr/lib
endif
FILTER ?=

APP_NAME   = AI Usage Meter
BUILD_DIR  = .build/release
DIST       = dist
APP        = $(DIST)/$(APP_NAME).app
APP_DEST   = $(HOME)/Applications/$(APP_NAME).app
HOOK_DEST  = $(HOME)/.local/bin/ai-usage-meter-hook
CODEX_HOOK_DEST = $(HOME)/.local/bin/ai-usage-meter-codex-hook
SNAPSHOT   = $(HOME)/Library/Application Support/ai-usage-meter
export CODEX_HOOK_DEST SNAPSHOT

.PHONY: build test bundle install uninstall run clean snippet

build:
	swift build -c release

test:
	swift test $(TEST_FLAGS) $(if $(FILTER),--filter $(FILTER),)
	sh Tests/SnippetTests.sh

bundle: build
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS"
	cp "$(BUILD_DIR)/AIUsageMeter" "$(APP)/Contents/MacOS/AIUsageMeter"
	cp packaging/Info.plist "$(APP)/Contents/Info.plist"
	plutil -lint "$(APP)/Contents/Info.plist"
	codesign --force --sign - "$(APP)"

install: bundle
	mkdir -p "$(HOME)/.local/bin" "$(HOME)/Applications"
	cp "$(BUILD_DIR)/ai-usage-meter-hook" "$(HOOK_DEST).new"
	chmod 755 "$(HOOK_DEST).new"
	mv -f "$(HOOK_DEST).new" "$(HOOK_DEST)"
	sh packaging/install-codex-launcher.sh
	-osascript -e 'tell application "AI Usage Meter" to quit' >/dev/null 2>&1
	@for i in 1 2 3 4 5 6; do pgrep -x "AIUsageMeter" >/dev/null 2>&1 || break; sleep 0.5; done
	rm -rf "$(APP_DEST).new"
	cp -R "$(APP)" "$(APP_DEST).new"
	rm -rf "$(APP_DEST)"
	mv "$(APP_DEST).new" "$(APP_DEST)"
	open "$(APP_DEST)"
	@$(MAKE) --no-print-directory snippet

snippet:
	@echo ""
	@echo "Add this to ~/.claude/settings.json (the installer never edits it):"
	@echo ""
	@echo '  "statusLine": {'
	@echo '    "type": "command",'
	@echo '    "command": "$(HOOK_DEST)"'
	@echo '  }'
	@echo ""
	@echo "Codex usage refreshes automatically in the app every 30 seconds."
	@echo "Add this native Codex footer configuration to ~/.codex/config.toml:"
	@echo '[tui]'
	@echo 'status_line = ["model-with-reasoning", "context-remaining"]'

uninstall:
	-osascript -e 'tell application "AI Usage Meter" to quit' >/dev/null 2>&1
	rm -rf "$(APP_DEST)"
	rm -f "$(HOOK_DEST)" "$$CODEX_HOOK_DEST" "$$SNAPSHOT/codex-launcher"
	@echo "Removed the app, launcher configuration, and hook executables. Remove old configuration entries by hand."
	@echo "Snapshot left in place: $(SNAPSHOT)"

run: build
	"$(BUILD_DIR)/AIUsageMeter"

clean:
	rm -rf "$(DIST)" .build
