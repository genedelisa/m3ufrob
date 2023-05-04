# Makefile
#
# see https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html
# Gene De Lisa
# 5/4/23
# Copyright © 2023 Rockhopper Technologies, Inc. All rights reserved.
# 2023
#

SHELL 			= /bin/sh
PROG			= m3ufrob
SRC			= Sources/**/*.swift
VERSION 		= 0.1.0
PREFIX 			= /usr/local
INSTALL_DIR		= $(PREFIX)/bin/$(PROG)
INSTALLED_PROG		= $(INSTALL_DIR)/$(PROG)
BUILD_PATH 		= .build/release/$(PROG)
SWIFT			= xcrun --sdk macosx swift
# you can see which swift with this:
# xcrun --show-sdk-path --sdk macosx

path := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
cwd  := $(shell pwd)
brew_prefix := $(shell brew --prefix)

PREF_PLIST 		= com.rockhoppertech.$(PROG).plist
PREF_DIR 		= /Library/Preferences/Logging/Subsystems/
ZSH_COMPLETION_DIR      = $(brew_prefix)/share/zsh/site-functions
#ZSH_COMPLETION_DIR      = /usr/local/share/zsh/site-functions
# doesn't work here
# ZSH_COMPLETION_FILE     = "${cwd}/_${PROG}"

RELEASE_BUILD           = ./.build/arm64-apple-macosx/release
ARCHIVE                 =$(PROG).tar.gz
#RELEASE_BUILD=./.build/apple/Products/Release


default: build-debug

#build-release: SWIFT_FLAGS = --configuration release --disable-sandbox -Xswiftc -warnings-as-errors --arch arm64 --arch x86_64
build-release: SWIFT_FLAGS = --configuration release --disable-sandbox
build-release: PREFIX = /usr/local
build-release: $(PROG)

build-debug: SWIFT_FLAGS = --configuration debug -Xswiftc "-D" -Xswiftc "DEBUG"
build-debug: PREFIX := "$(CURDIR)"
build-debug: $(PROG)

$(PROG): $(SRC)
	$(SWIFT) build $(SWIFT_FLAGS)


.PHONY: package
package: build-release
	$(RELEASE_BUILD)/$(PROG) --generate-completion-script zsh > _${PROG}
	tar -pvczf $(ARCHIVE) _${PROG} -C $(RELEASE_BUILD) $(PROG)
	tar -zxvf $(ARCHIVE)
	@shasum -a 256 $(ARCHIVE)
	@shasum -a 256 $(PROG)
	#rm $(PROG) _${PROG}

.PHONY: zsh-generate-completion
zsh-generate-completion: build-release
	$(RELEASE_BUILD)/$(PROG) --generate-completion-script zsh > _${PROG}

.PHONY: zsh-install-completion
zsh-install-completion: build-release
ifneq (,$(wildcard ${ZSH_COMPLETION_DIR/}_${PROG} ))
	@printf "${ZSH_COMPLETION_DIR}/_${PROG} exists\n"
	@rm -i ${ZSH_COMPLETION_DIR}/_${PROG}
endif
	$(RELEASE_BUILD)/$(PROG) --generate-completion-script zsh > _${PROG}
	@printf "Generated zsh completions\n"
	sudo cp -f "${cwd}/_${PROG}" ${ZSH_COMPLETION_DIR}
	@printf "Copied _${PROG} completion to ${ZSH_COMPLETION_DIR}\n"

.PHONY: zsh-install-completion-link
zsh-install-completion-link: build-release
ifneq (,$(wildcard ${ZSH_COMPLETION_DIR/}_${PROG} ))
	@printf "${ZSH_COMPLETION_DIR}/_${PROG} exists\n"
	@rm -i ${ZSH_COMPLETION_DIR}/_${PROG}
endif
	$(RELEASE_BUILD)/$(PROG) --generate-completion-script zsh > _${PROG}
	@printf "Generated zsh completions\n"
	sudo ln -fs "${cwd}/_${PROG}" ${ZSH_COMPLETION_DIR}
	@printf "Created link in ${ZSH_COMPLETION_DIR}\n"


.PHONY: lintfix
lintfix:					## fix the problems discovered by swiftlint
	swiftlint --fix --format
#	swiftlint --fix --format --quiet

.PHONY: lint
lint:						## lint your sources
	swiftlint lint --quiet --strict

.PHONY: dockertest
dockertest:					## run the test target in docker
	docker build -f Dockerfile -t linuxtest .
	docker run linuxtest

.PHONY: runexe
runexe: 					## directly run the program
	.build/debug/$(PROG) -h

# e.g. make run ARGS=--verbose file
.PHONY: run
run: $(PROG)					## swift run the program. e.g. make run ARGS=--verbose file
	$(SWIFT) run -- $(PROG) $(ARGS)

.PHONY: runexe
runexe: 					## directly run the program
	.build/debug/$(PROG) -h


# The Swift Package Index recommends that before submitting your package that this emits valid JSON.
# https://github.com/SwiftPackageIndex/PackageList
.PHONY: dump-package
dump-package:					## Dump this package as JSON.
	swift package dump-package

.PHONY: update
update:						## update the packages
	$(SWIFT) package update

.PHONY: test
test:						## run the tests
	$(SWIFT) test

.PHONY: install
install: release				## install the program to INSTALL_DIR
	install -d "$(PREFIX)/bin"
	install -m 755 --directory $(PREF_DIR)
	install -C -m 755 $(BUILD_PATH) $(INSTALL_DIR)
	sudo install -C -m 755 $(PREF_PLIST) $(PREF_DIR)

.PHONY: install-prefs
install-prefs: 					## install the logging preference plist
	@printf "Copying ${PREF_PLIST} to $(PREF_DIR)\n"
	sudo cp $(PREF_PLIST) $(PREF_DIR)

.PHONY: uninstall
uninstall:					## uninstall the program from INSTALL_PATH
	rm -f $(INSTALLED_PROG)
	rm -f $(PREF_DIR)$(PREF_PLIST)


release: build-release				## build the release version
debug: build-debug				## build the debug version


.PHONY: clean
clean:						## clean package
	$(SWIFT) package clean

.PHONY: docs
docs:						## Generate docs via docc
	xcrun swift package generate-documentation
	xcrun swift package --disable-sandbox preview-documentation --target m3ufrob &
	sleep 2
	open -a Safari http://localhost:8000/documentation/m3ufrob

.PHONY: killdocs
killdocs:						## Kill the docc server
	pkill docc


.PHONY: jazzydocs
jazzydocs:						## Generate docs via Jazzy
	jazzy

# foreground Colors
fg_black 	:= $(shell tput -Txterm setaf 0)
fg_red 		:= $(shell tput -Txterm setaf 1)
fg_green 	:= $(shell tput -Txterm setaf 2)
fg_yellow 	:= $(shell tput -Txterm setaf 3)
fg_blue 	:= $(shell tput -Txterm setaf 4)
fg_magenta 	:= $(shell tput -Txterm setaf 5)
fg_cyan 	:= $(shell tput -Txterm setaf 6)
fg_white 	:= $(shell tput -Txterm setaf 7)
fg_default 	:= $(shell tput -Txterm setaf 9)

# background Colors
bg_black 	:= $(shell tput -Txterm setab 0)
bg_red 		:= $(shell tput -Txterm setab 1)
bg_green 	:= $(shell tput -Txterm setab 2)
bg_yellow 	:= $(shell tput -Txterm setab 3)
bg_blue 	:= $(shell tput -Txterm setab 4)
bg_magenta 	:= $(shell tput -Txterm setab 5)
bg_cyan 	:= $(shell tput -Txterm setab 6)
bg_white 	:= $(shell tput -Txterm setab 7)
bg_default 	:= $(shell tput -Txterm setab 9)

RESET		:= $(shell tput -Txterm sgr0)
bold		:= $(shell tput -Txterm bold)

# modified from https://gist.github.com/prwhite/8168133
# reads targets with help text that starts with two #s

.PHONY: help
help:			## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "${bg_blue}${bold}${fg_yellow}%-30s %s\n" "target" "help" ; \
	printf "%-30s %s${RESET}\n" "------" "----" ; \
    for help_line in $${help_lines[@]}; do \
        IFS=$$':' ; \
        help_split=($$help_line) ; \
        help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
        help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
        printf "${fg_cyan}%-30s %s${RESET}" $$help_command ; \
        printf "${fg_magenta}%s${RESET}\n" $$help_info; \
    done
