#!/bin/bash

# title: copy_without_linebreaks
# author: Glutanimate (github.com/glutanimate)
# license: MIT license

# Reads the current selection aloud. A second selection replaces the first.
#
# Usage: xsel-to-speech.sh [paradee|rhvoice] [run|install]
#
# This file sets up the environment and prepares the selected text. The backend
# (paradee-speech.sh or rhvoice-speech.sh) provides speech_setup, speech_loop
# and speech_install. See README.md.

# Repo location. Resolves symlinks, so ~/bin/xsel-to-speech.sh -> /opt/... works.
XSEL_HOME="${XSEL_HOME:-$(dirname "$(readlink -f "$0")")}"
# Python environment of the Paradee service.
XSEL_VENV="${XSEL_VENV:-$XSEL_HOME/.venv}"
# Backend: paradee or rhvoice. The first argument overrides it.
XSEL_TTS_BACKEND="${1:-${XSEL_TTS_BACKEND:-paradee}}"
# Reading speed in percent. 100 is the backend's normal speed.
# 140 is about 250 words per minute on both backends.
XSEL_SPEED_PCT="${XSEL_SPEED_PCT:-140}"
# Stay silent in these windows. Extended regexes, matched against the focused
# window's title and against its `ps` line. Set one empty to turn that check off.
XSEL_SKIP_TITLES="${XSEL_SKIP_TITLES-Visual Studio Code|emacs}"
XSEL_SKIP_PROCESSES="${XSEL_SKIP_PROCESSES-terminator}"

action="${2:-run}"

die() {
	echo "xsel-to-speech: $*" >&2
	exit 1
}

# Sets ModifiedText to the selection, ready to speak. Fails if the focused
# window is skipped.
next_selection() {
	local SelectedText window_name
	SelectedText="$(xsel | "$XSEL_HOME/grec-tr.py")"

	window_name=$(xdotool getwindowfocus getwindowname)
	if [ -n "$XSEL_SKIP_TITLES" ] && grep -qE "$XSEL_SKIP_TITLES" <<<"$window_name"; then
		echo ">> skip $window_name"
		return 1
	fi
	if [ -n "$XSEL_SKIP_PROCESSES" ] &&
		ps -hp "$(xdotool getwindowfocus getwindowpid)" | grep -qE "$XSEL_SKIP_PROCESSES"; then
		echo ">> skip pid $window_name"
		return 1
	fi

	ModifiedText="$(echo "$SelectedText" | \
		sed 's/\.$/.|/g' | sed 's/-$//g' | sed 's/^\s*$/|/g' | tr -d '\n' | tr '|' '\n' | iconv -f utf-8 -t ascii//TRANSLIT)"

	#   - first sed command: replace end-of-line full stops with '|' delimiter and keep original periods.
	#   - second sed command: replace empty lines with same delimiter (e.g.
	#     to separate text headings from text)
	#   - subsequent tr commands: remove existing newlines; replace delimiter with
	#     newlines
	# This is less than elegant but it works.
}

[[ "$XSEL_SPEED_PCT" =~ ^[1-9][0-9]*$ ]] || die "XSEL_SPEED_PCT must be a positive whole number, not '$XSEL_SPEED_PCT'"

case "$XSEL_TTS_BACKEND" in
paradee | rhvoice) source "$XSEL_HOME/$XSEL_TTS_BACKEND-speech.sh" ;;
*) die "unknown backend '$XSEL_TTS_BACKEND'; use paradee or rhvoice" ;;
esac

case "$action" in
install) speech_install ;;
run)
	speech_setup
	echo "BEGIN $XSEL_TTS_BACKEND at $XSEL_SPEED_PCT%"
	speech_loop
	;;
*) die "unknown action '$action'; use run or install" ;;
esac
