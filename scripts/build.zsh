#!/usr/bin/env zsh
# -*- mode: sh; sh-shell: zsh; sh-indentation: 4; sh-basic-offset: 4; coding: utf-8; -*-
# vim: ft=zsh:sw=4:ts=4:et
#
# Time-stamp: "Last Modified 2023-03-12 13:41:36 by Gene De Lisa, genedelisa"
#
# File: build.zsh
# Description: build m3ufrob
#
# script_version=0.1.0
#
# Gene De Lisa
# gene@rockhoppertech.com
# http://rockhoppertech.com/blog/
# License - http://unlicense.org
################################################################################
# https://google.github.io/styleguide/shellguide.html#s7-naming-conventions
################################################################################
# https://developer.apple.com/library/archive/technotes/tn2339/_index.html

typeset -r version=0.1.0

local MACHINE_ARCH=$(uname -m)

local scheme=m3ufrob
# local scheme="com.rockhoppertech.terminalColorTester"

xcodebuild -scheme ${scheme} \
	   -destination 'platform=macOS,arch=${MACHINE_ARCH}' \
	   -configuration Debug \
	   build


# to find out the schemes
# xcodebuild -list

# to find out the available destinations
#xcodebuild -showdestinations -scheme $scheme


#xcodebuild -scheme ${scheme} -destination 'platform=macOS' -configuration Debug build

#xcodebuild test -scheme ${scheme} -destination 'platform=macOS' -configuration Debug build

#xcodebuild -scheme ${scheme} -destination 'platform=macOS,arch=x86_64' -configuration Debug build

#xcodebuild -scheme ${scheme} -destination 'platform=iOS Simulator,OS=15.4,name=iPhone 13 Pro Max' -configuration Debug build
