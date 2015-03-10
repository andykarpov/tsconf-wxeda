#!/bin/bash

# образ W25Q32.ROM для записи в конфигурационную флешку W25Q32 с помощью программатора
# образ содержит 512кб пзу для tsconf, а также набор пзу для проекта speccy-wxeda

# 1 : 524288 zxevo.rom 
# 2 : 196608 - нули до смещения 720896 (для проекта u16_speccy)
# 3 : 32768 gs105a.rom
# 4 : 16384 hegluk_19.rom
# 5 : 16384 trdos_605e.rom
# 6 : 16384 86.rom
# 7 : 16384 82.rom
# 8 : 8192 esxmmc.rom
# 9 : 8192 test128k.rom
# 10: 3358720 - нули до полного объема флешки 4194304

cat zxevo.rom > W25Q32.ROM
dd if=/dev/zero of=zeroes.rom bs=196608 count=1
cat zeroes.rom >> W25Q32.ROM
rm zeroes.rom >> W25Q32.ROM
cat gs105a.rom >> W25Q32.ROM
cat hegluk_19.rom >> W25Q32.ROM
cat trdos_605e.rom >> W25Q32.ROM
cat 86.rom >> W25Q32.ROM
cat 82.rom >> W25Q32.ROM
cat esxmmc.rom >> W25Q32.ROM
cat test128k.rom >> W25Q32.ROM
dd if=/dev/zero of=zeroes.rom bs=3358720 count=1
cat zeroes.rom >> W25Q32.ROM
rm zeroes.rom
