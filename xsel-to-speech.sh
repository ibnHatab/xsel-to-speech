#!/bin/bash

# title: copy_without_linebreaks
# author: Glutanimate (github.com/glutanimate)
# license: MIT license

# Parses currently selected text and removes
# newlines that aren't preceded by a full stop

# Install
# $ sudo add-apt-repository ppa:linvinus/rhvoice
# $ sudo apt-get install rhvoice rhvoice-english
# $ sudo apt install xsel
# $ git clone https://github.com/cdown/clipnotify.git && cd clipnotify && make
#
# Usage:
# $ while clipnotify; do ~/bin/xsel-to-speech.sh; done
# - select text in PDF and leasten to the voice
# - second select overwrite first on

SelectedText="$(xsel)"

ModifiedText="$(echo "$SelectedText" | \
    sed 's/\.$/.|/g' | sed 's/-$//g' | sed 's/^\s*$/|/g' | tr '\n' ' ' | tr '|' '\n' | iconv -f utf-8 -t ascii//TRANSLIT)"

#   - first sed command: replace end-of-line full stops with '|' delimiter and keep original periods.
#   - second sed command: replace empty lines with same delimiter (e.g.
#     to separate text headings from text)
#   - subsequent tr commands: remove existing newlines; replace delimiter with
#     newlines
# This is less than elegant but it works.
killall RHVoice-client && sleep 2

echo "$ModifiedText" | RHVoice-client -s  SLT -r 0.5 -v -0.1| aplay &
