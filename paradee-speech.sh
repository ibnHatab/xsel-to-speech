# Paradee backend, sourced by xsel-to-speech.sh.
#
# The model stays loaded in paradee-tts.service, which systemd starts on the first
# connection to the socket. This script talks to the socket with socat and plays
# the audio that comes back with aplay.

PARADEE_VOICE="${PARADEE_VOICE:-af_heart}" # af_heart, am_puck, bf_isabella or bm_fable
PARADEE_SOCKET="${PARADEE_SOCKET:-$XDG_RUNTIME_DIR/paradee-tts.sock}"
# Paradee's speed is a multiplier: 140% is 1.40.
PARADEE_SPEED=$(awk -v p="$XSEL_SPEED_PCT" 'BEGIN { printf "%.2f", p / 100 }')

speech_pid=""

# Creates the venv, caches the model and enables the socket. Safe to run again.
speech_install() {
	local units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user" tmp
	command -v socat >/dev/null || die "socat not found; run: sudo apt install socat"
	[ -x "$XSEL_VENV/bin/python" ] || python3 -m venv "$XSEL_VENV" || die "cannot create $XSEL_VENV"
	"$XSEL_VENV/bin/python" -c 'import paradee' 2>/dev/null ||
		"$XSEL_VENV/bin/pip" install git+https://github.com/sahilmahendrakar/paradee || die "pip install failed"

	# The service runs with HF_HUB_OFFLINE=1, so everything must be cached now.
	tmp=$(mktemp --suffix=.wav)
	"$XSEL_VENV/bin/python" -m paradee "Hello." --voice "$PARADEE_VOICE" -o "$tmp" || die "cannot cache the model"
	rm -f "$tmp"

	mkdir -p "$units"
	sed -e "s|@XSEL_HOME@|$XSEL_HOME|g" -e "s|@XSEL_VENV@|$XSEL_VENV|g" \
		"$XSEL_HOME/systemd/paradee-tts.service.in" >"$units/paradee-tts.service"
	cp "$XSEL_HOME/systemd/paradee-tts.socket" "$units/"
	systemctl --user daemon-reload
	systemctl --user enable paradee-tts.socket
	systemctl --user stop paradee-tts.service paradee-tts.socket 2>/dev/null # so the new units apply
	systemctl --user start paradee-tts.socket
	echo "Installed. Socket: $PARADEE_SOCKET"
}

speech_setup() {
	command -v socat >/dev/null || die "socat not found; run: sudo apt install socat"
	[ -S "$PARADEE_SOCKET" ] || die "no socket at $PARADEE_SOCKET; run: $0 paradee install"
}

# Sends "$1" to the service and writes the returned WAV stream to stdout.
# At the end of its input socat closes only its sending side, which marks the end
# of the request. -t is how long it then keeps reading: socat's default of 0.5 s
# would cut off the audio.
paradee_request() {
	socat -t 86400 - "UNIX-CONNECT:$PARADEE_SOCKET" <<<"$PARADEE_SPEED $PARADEE_VOICE"$'\n'"$1"
}

# Cuts off current speech at once. Fails if nothing was playing.
speech_stop() {
	[ -n "$speech_pid" ] && kill "$speech_pid" 2>/dev/null
}

speech_loop() {
	trap speech_stop EXIT
	while clipnotify; do
		next_selection || continue
		speech_setup # a missing socket would otherwise fail silently below
		speech_stop && (paradee_request 'break' | aplay -q) && sleep 0.5
		# Process substitution makes $! the pid of aplay. Killing it ends socat, and
		# the closed connection makes the server stop generating. Both report that
		# as an error, so their stderr is dropped.
		aplay -q 2>/dev/null < <(paradee_request "$ModifiedText" 2>/dev/null) &
		speech_pid=$!
	done
}
