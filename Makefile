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

.PHONY: build test bundle install uninstall run clean snippet

build:
	swift build -c release

test:
	swift test $(TEST_FLAGS) $(if $(FILTER),--filter $(FILTER),)

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
	cp "$(BUILD_DIR)/ai-usage-meter-codex-hook" "$(CODEX_HOOK_DEST).new"
	chmod 755 "$(CODEX_HOOK_DEST).new"
	mv -f "$(CODEX_HOOK_DEST).new" "$(CODEX_HOOK_DEST)"
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
	@codex_bin="$$(command -v codex 2>/dev/null || true)"; \
	if [ -z "$$codex_bin" ]; then \
		echo "Codex CLI not found on PATH; rerun 'make snippet' from a shell where codex is available."; \
		exit 0; \
	fi; \
	codex_bin="$$(realpath "$$codex_bin")"; \
	hook_dest="$$HOME/.local/bin/ai-usage-meter-codex-hook"; \
	for path in "$$hook_dest" "$$codex_bin"; do \
		case "$$path" in *\'*|*\"*|*\\*) \
			echo "Cannot render Codex hook JSON: executable paths cannot contain quotes or backslashes."; \
			exit 1;; \
		esac; \
		if printf '%s' "$$path" | LC_ALL=C grep -q '[[:cntrl:]]'; then \
			echo "Cannot render Codex hook JSON: executable paths cannot contain control characters."; \
			exit 1; \
		fi; \
	done; \
	echo "Merge this entry into the Stop array in ~/.codex/hooks.json:"; \
	echo ""; \
	echo '        {'; \
	echo '          "hooks": ['; \
	echo '            {'; \
	echo '              "type": "command",'; \
	printf '              "command": "'\''%s'\'' --codex-bin '\''%s'\''",\n' "$$hook_dest" "$$codex_bin"; \
	echo '              "async": true,'; \
	echo '              "timeout": 15'; \
	echo '            }'; \
	echo '          ]'; \
	echo '        }'; \
	echo ""; \
	echo "Add this native Codex footer configuration to ~/.codex/config.toml:"; \
	echo ""; \
	echo '[tui]'; \
	echo 'status_line = ["model-with-reasoning", "context-remaining"]'; \
	echo ""

uninstall:
	-osascript -e 'tell application "AI Usage Meter" to quit' >/dev/null 2>&1
	rm -rf "$(APP_DEST)"
	rm -f "$(HOOK_DEST)" "$(CODEX_HOOK_DEST)"
	@echo "Removed the app and both hooks. Remove their Claude/Codex configuration entries by hand."
	@echo "Snapshot left in place: $(SNAPSHOT)"

run: build
	"$(BUILD_DIR)/AIUsageMeter"

clean:
	rm -rf "$(DIST)" .build
