# xsel-to-speech
Parses currently selected text and removes newlines that aren't preceded by a full stop


# Install
 $ sudo add-apt-repository ppa:linvinus/rhvoice
 
 $ sudo apt-get install rhvoice rhvoice-english
 
 $ sudo apt install xsel
 
 $ git clone https://github.com/cdown/clipnotify.git && cd clipnotify && make

# Usage:
 $ while clipnotify; do ~/bin/xsel-to-speech.sh; done
 - select text in PDF and listen to the voice
 - second select overwrite first on
