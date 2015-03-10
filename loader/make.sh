#!/bin/sh

rm loader.bin
rm loader.hex
./sjasmplus loader.asm
./bin2hex.py --binaries=0,loader.bin

