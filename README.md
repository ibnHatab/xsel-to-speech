# xsel-to-speech
Parses currently selected text and removes newlines that aren't preceded by a full stop


# Install
 $ sudo add-apt-repository ppa:linvinus/rhvoice
 
 $ sudo apt-get install rhvoice rhvoice-english
 
 $ sudo apt install xsel
 
 $ sudo apt-get install libxcomposite-dev libxdamage-dev libxrender-dev
 
 $ git clone https://github.com/cdown/clipnotify.git && cd clipnotify && make

# Paradee voice (default)
 $ python3 -m venv /opt/xsel-to-speech/.venv

 $ /opt/xsel-to-speech/.venv/bin/pip install git+https://github.com/sahilmahendrakar/paradee

 Run once while online, to cache the model and the spaCy data:

 $ /opt/xsel-to-speech/.venv/bin/python -m paradee "Hello." -o /tmp/hello.wav

# Usage:
 $ /opt/xsel-to-speech/xsel-to-speech.sh
 - select text in PDF and listen to the voice
 - second select overwrite first on

# Environment
 - XSEL_TTS_CLIENT: Paradee (default), RHVoice or MeloTTS
 - XSEL_TTS_VENV: Paradee virtualenv (default: .venv next to the script)
 - PARADEE_VOICE: af_heart (default), am_puck, bf_isabella or bm_fable
 - PARADEE_SPEED: default 1.0, higher is faster
