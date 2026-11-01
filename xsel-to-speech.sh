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
# - select text in PDF and listen to the voice
# - second select overwrite first on
echo "BEGIN"

# MeloTTS is a high-quality multi-lingual text-to-speech library by MyShell.ai.
## tts_client="MeloTTS"
# RHVoice is a free and open-source multilingual speech synthesizer.
# Paradee is an 8M-parameter model distilled from Kokoro. Runs on CPU from a local .venv.
tts_client="${XSEL_TTS_CLIENT:-Paradee}"

# Repo location. Resolves symlinks, so ~/bin/xsel-to-speech.sh -> /opt/... works.
XSEL_HOME="${XSEL_HOME:-$(dirname "$(readlink -f "$0")")}"

if [ "$tts_client" = "Paradee" ]; then
	export VIRTUAL_ENV="${XSEL_TTS_VENV:-$XSEL_HOME/.venv}"
	export PATH="$VIRTUAL_ENV/bin:$PATH"
	export PARADEE_VOICE="${PARADEE_VOICE:-af_heart}"
	# A speed multiplier, unlike RHVoice's -r: 1.4 matches `RHVoice-client -r 0.3` (about 250 wpm).
	export PARADEE_SPEED="${PARADEE_SPEED:-1.4}"
	# The model is cached at install time; don't call the HF Hub on every selection.
	export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}"
	paradee_client="$XSEL_HOME/paradee_client.py"
fi

if [ "$tts_client" = "MeloTTS" ]; then
	conda activate melo
fi

while clipnotify; do
	SelectedText="$(xsel | "$XSEL_HOME/grec-tr.py")"
	#SelectedText="$(xsel)"

	# echo "DBG >> $SelectedText"
	window_name=$(xdotool getwindowfocus  getwindowname)
#	echo "DBG >> $window_name"
#	ps -hp $(xdotool getwindowfocus getwindowpid) 
	
	if (xdotool getwindowfocus  getwindowname | grep -e 'Visual Studio Code\|emacs') ; then
		echo ">> skip $window_name"
		continue
	fi

	if (ps -hp $(xdotool getwindowfocus getwindowpid) | egrep 'terminator') ; then
		echo ">> skip pid $window_name"
		continue
	fi

	ModifiedText="$(echo "$SelectedText" | \
    					 sed 's/\.$/.|/g' | sed 's/-$//g' | sed 's/^\s*$/|/g' | tr -d '\n' | tr '|' '\n' |  iconv -f utf-8 -t ascii//TRANSLIT)"

	#   - first sed command: replace end-of-line full stops with '|' delimiter and keep original periods.
	#   - second sed command: replace empty lines with same delimiter (e.g.
	#     to separate text headings from text)
	#   - subsequent tr commands: remove existing newlines; replace delimiter with
	#     newlines
	# This is less than elegant but it works.
	if [ "$tts_client" = "RHVoice" ]; then
		killall -q RHVoice-client  && sleep 1.5 && (echo 'break' | RHVoice-client -s  SLT -r 0.4 -v -0.1| aplay -q) && sleep 0.5
		echo "$ModifiedText" | RHVoice-client -s  SLT -r 0.3 -v -0.1| aplay -q &
	elif [ "$tts_client" = "Paradee" ]; then
		pkill -f "^python $paradee_client" && sleep 1.5 && (echo 'break' | "$paradee_client" | aplay -q) && sleep 0.5
		echo "$ModifiedText" | "$paradee_client" | aplay -q &
	elif [ "$tts_client" = "MeloTTS" ]; then
		pkill -9 -f melo_client.py && sleep 1.5 && (echo 'break' | melo_client.py ) && sleep 0.5
		echo "$ModifiedText" | melo_client.py &
	fi
done
