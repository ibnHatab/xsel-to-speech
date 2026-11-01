# RHVoice backend, sourced by xsel-to-speech.sh.

speech_install() {
	echo "Install RHVoice with apt:"
	echo "  sudo apt-get install rhvoice rhvoice-english"
}

speech_setup() {
	command -v RHVoice-client >/dev/null || die "RHVoice-client not found; run: $0 rhvoice install"
	# Percent to RHVoice's -1..1 rate, where 0 is normal. Scaled so 140% gives 0.3,
	# which matches Paradee at 1.4 (about 250 words per minute).
	rhvoice_rate=$(awk -v p="$XSEL_SPEED_PCT" 'BEGIN { r = 0.75 * (p - 100) / 100; if (r > 1) r = 1; printf "%.2f", r }')
}

rhvoice_say() {
	RHVoice-client -s SLT -r "$rhvoice_rate" -v -0.1 | aplay -q
}

speech_loop() {
	while clipnotify; do
		next_selection || continue
		killall -q RHVoice-client && sleep 1.5 && (echo 'break' | rhvoice_say) && sleep 0.5
		echo "$ModifiedText" | rhvoice_say &
	done
}
