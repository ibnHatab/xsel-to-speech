#!/usr/bin/env python
#coding=utf-8

## reqirements.txt
# pip3 install gradio_client pygame

import os
import sys
import pygame
from gradio_client import Client

lines = []
try:
    # Read input until EOF (Ctrl+D on Unix-like systems, Ctrl+Z on Windows)
    while True:
        line = input()
        lines.append(line)
except EOFError:
    # Concatenate all lines
    pass

text_to_speak = '\n'.join(lines)
print("User input:")
print(text_to_speak)


client = Client("http://127.0.0.1:7861")
file_path = client.predict('EN-US', text_to_speak, 1.5, 'EN', api_name="/synthesize", fn_index=0)

pygame.mixer.init()
my_sound = pygame.mixer.Sound(file_path)
my_sound.play()
pygame.time.wait(int(my_sound.get_length() * 1000))


if os.path.exists(file_path):
    os.remove(file_path)
