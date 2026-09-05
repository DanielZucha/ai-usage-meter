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

.PHONY: test

test:
	swift test $(TEST_FLAGS) $(if $(FILTER),--filter $(FILTER),)
