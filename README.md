# xsel-to-speech
Reads the current text selection aloud. Removes newlines that aren't preceded by a full stop, so text selected in a PDF reads as sentences.

# Install
 $ sudo apt install xsel xdotool socat

 $ sudo apt-get install libxcomposite-dev libxdamage-dev libxrender-dev

 $ git clone https://github.com/cdown/clipnotify.git && cd clipnotify && make

 Put `clipnotify` on your PATH. Then install a backend:

## Paradee (default)
 $ /opt/xsel-to-speech/xsel-to-speech.sh paradee install

 This creates `.venv`, installs [Paradee](https://github.com/sahilmahendrakar/paradee), caches the model while online, and enables the systemd user socket. It is safe to run again, and needed again after moving the repo or editing the unit files.

## RHVoice
 $ sudo add-apt-repository ppa:linvinus/rhvoice

 $ sudo apt-get install rhvoice rhvoice-english

# Usage
 $ /opt/xsel-to-speech/xsel-to-speech.sh [paradee|rhvoice]

 - select text in PDF and listen to the voice
 - second select overwrite first one

# Settings
Set in the header of `xsel-to-speech.sh`, or override from the environment.

| Variable | Default | Purpose |
|---|---|---|
| `XSEL_TTS_BACKEND` | `paradee` | `paradee` or `rhvoice`. The script's first argument overrides it |
| `XSEL_SPEED_PCT` | `120` | Reading speed in percent, where 100 is the backend's normal speed |
| `XSEL_SKIP_TITLES` | `Visual Studio Code\|emacs` | Stay silent when the focused window's title matches this regex |
| `XSEL_SKIP_PROCESSES` | empty | Stay silent when the focused window's `ps` line matches this regex |
| `XSEL_HOME` | the script's real directory | Repo location |
| `XSEL_VENV` | `$XSEL_HOME/.venv` | Paradee's environment. Set it for `install` too |
| `PARADEE_VOICE` | `af_heart` | Also `am_puck`, `bf_isabella` or `bm_fable` |
| `PARADEE_SOCKET` | `$XDG_RUNTIME_DIR/paradee-tts.sock` | Service socket. Change it only together with `systemd/paradee-tts.socket` |

The percentage becomes a speed multiplier for Paradee and a `-r` rate for RHVoice, where `-r` runs from -1 to 1 with 0 as normal and the rate is `0.75 * (percent - 100) / 100`. RHVoice reaches its limit at 233%. The two backends match at 140% and are close elsewhere. Words per minute, measured on one 64-word passage:

| Percent | Paradee | RHVoice `-r` | RHVoice |
|---:|---:|---:|---:|
| 100 | 168 | 0.00 | 193 |
| 120 | 193 | 0.15 | 222 |
| 140 | 250 | 0.30 | 251 |
| 160 | 270 | 0.45 | 280 |
| 180 | 289 | 0.60 | 309 |
| 200 | 312 | 0.75 | 338 |

# How it works
`xsel-to-speech.sh` sets up the environment, cleans up the selected text and sources the backend, which provides `speech_setup`, `speech_loop` and `speech_install`.

| File | Role |
|---|---|
| `xsel-to-speech.sh` | Settings, backend selection, text cleanup, skipped windows |
| `grec-tr.py` | Spells out Greek letters and math symbols |
| `rhvoice-speech.sh` | Loop that pipes text through `RHVoice-client` |
| `paradee-speech.sh` | Loop that talks to the socket with `socat`, and the installer |
| `paradee_server.py` | Keeps the model loaded and turns text into audio |
| `systemd/` | User units for the socket and the service |

Paradee takes over a second to load, too slow to repeat for every selection, so it stays loaded in a service:

    selection -> socat -> /run/user/UID/paradee-tts.sock -> paradee_server.py
    aplay     <- socat <- WAV stream, one sentence at a time <-

systemd owns the socket and starts the service on the first connection. That first request waits about a second while the model loads, and later ones return in about 40 ms. The loaded service uses about 440 MB of memory. After 30 idle minutes it exits and frees that memory, and the socket stays ready. Change `PARADEE_IDLE_SECS` in `systemd/paradee-tts.service.in` to adjust this. Only your user can open the socket.

A request is one line with the speed and voice, then the text, so changing the speed needs no service restart. socat closes its sending side at the end of input, which tells the server the request is complete, and keeps reading the audio. An invalid request closes the connection with no data, and the reason goes to the journal. The server handles one connection at a time.

A new selection kills `aplay`, which stops the sound at once. socat then fails on its next write and exits, and the server stops generating when the connection closes.

# Troubleshooting
 $ systemctl --user status paradee-tts.socket paradee-tts.service

 $ journalctl --user -u paradee-tts.service -e

 $ printf '1.40 af_heart\nHello there.\n' | socat -t 60 - UNIX-CONNECT:$XDG_RUNTIME_DIR/paradee-tts.sock | aplay -q
