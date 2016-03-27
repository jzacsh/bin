#!/usr/bin/env bash
#
# Trustworthy translator from object at a cursor position to object's package
# name, then scrape from that trustworthy output to get the "pkg" name
#
# Overview: note this tries to simply ask golang's `oracle` (an golang
# spec-compliant, AST walker) about positions in a file.
#
#   $ oracle -format plain -pos="your/file/path:#342" definition
#   $GOPATH/src/github.com/stretchr/testify/assert/assertions.go:261:6: defined here as func github.com/stretchr/testify/assert.Equal(t github.com/stretchr/testify/assert.TestingT, expected interface{}, actual interface{}, msgAndArgs ...interface{}) bool
#
#   Note the initial file path emitted is exactly where the symbol is defined
#   (its "package") and simply running:
#   $ godoc $(dirname $GOPATH/src/.../assertions.go)
#   Gives the desired result
set -e

declare -r file="$1"; [ -n "$file" ]
declare -r offset="$2"; [ -n "$offset" ]
declare -r pos="$(printf '%s:#%s' "$file" "$offset")"
declare -r pkgSrc="$(
  oracle -format plain -pos="$pos" definition |
    \cut -f 1 -d ' ' |
    \sed -e 's|:[0-9]*\:[0-9]*\:$||'
)"

declare -r pkg="$(dirname "$pkgSrc")" 
# NOTE: `godoc "$pkg"` works perfectly at this point

echo "$pkg" | sed -e "s|^${GOPATH}src\/||"
