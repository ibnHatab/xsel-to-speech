# xsel-to-speech
Reads the current text selection aloud. A new selection replaces the one being read.

 $ /opt/xsel-to-speech/xsel-to-speech.sh [paradee|rhvoice]

# Install
 $ sudo apt install xsel xdotool socat

 $ sudo apt-get install libxcomposite-dev libxdamage-dev libxrender-dev

 $ git clone https://github.com/cdown/clipnotify.git && cd clipnotify && make

Put `clipnotify` on your PATH, then install a backend.

**Paradee** (default) needs systemd and goes online once to fetch the model:

 $ /opt/xsel-to-speech/xsel-to-speech.sh paradee install

Run this again after moving the repo or editing `systemd/`.

**RHVoice:**

 $ sudo add-apt-repository ppa:linvinus/rhvoice

 $ sudo apt-get install rhvoice rhvoice-english

# Settings
Set these in the header of `xsel-to-speech.sh` or in the environment.

| Variable | Default | Purpose |
|---|---|---|
| `XSEL_TTS_BACKEND` | `paradee` | `paradee` or `rhvoice`. The first argument overrides it |
| `XSEL_SPEED_PCT` | `130` | Reading speed, where 100 is the backend's normal speed. The backends match at 140 |
| `XSEL_SKIP_TITLES` | `Visual Studio Code\|emacs` | Stay silent if the focused window's title matches this regex |
| `XSEL_SKIP_PROCESSES` | empty | Stay silent if the focused window's `ps` line matches this regex |
| `XSEL_HOME` | the script's real directory | Repo location |
| `XSEL_VENV` | `$XSEL_HOME/.venv` | Paradee's environment. Set it for `install` too |
| `PARADEE_VOICE` | `af_heart` | Also `am_puck`, `bf_isabella` or `bm_fable` |

# How it works
`xsel-to-speech.sh` holds the settings and cleans up the selected text with `grec-tr.py`. It then sources `paradee-speech.sh` or `rhvoice-speech.sh`, which runs the loop.

For Paradee, the model stays loaded in `paradee_server.py`. systemd starts it on the first connection to `$XDG_RUNTIME_DIR/paradee-tts.sock`, so the first selection waits about a second. It exits after 30 idle minutes, freeing about 440 MB.

The script talks to the socket with `socat`. Each request is one line with the speed and voice, then the text, and the reply is a WAV stream for `aplay`:

 $ printf '1.30 af_heart\nHello there.\n' | socat -t 60 - UNIX-CONNECT:$XDG_RUNTIME_DIR/paradee-tts.sock | aplay -q

# Troubleshooting
 $ systemctl --user status paradee-tts.socket paradee-tts.service

 $ journalctl --user -u paradee-tts.service -e
