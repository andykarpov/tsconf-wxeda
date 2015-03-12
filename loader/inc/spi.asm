; -----------------------------------------------------------------------------
; SPI autoloader
; -----------------------------------------------------------------------------

SPI_LOADER

	ld a,%00000000			; %00000001 (bit2=0, bit1=0, bit0=0)
	ld bc,system_port
	out (c),a

	ld hl,str_flash
	call print_str

	call spi_start
	ld d,%00000011	; command = read
	call spi_w

	ld d,#00	; address = #000000 (смещение адреса относительно начала в W25q32)
	call spi_w
	ld d,#00
	call spi_w
	ld d,#00
	call spi_w

	ld bc,#13af	;
	in a,(c)
	ld (page3init),a

	xor a
spi_loader3
	ld bc,#13af
	out (c),a
	ld hl,#c000
	ld e,a
spi_loader2
	call spi_r
	ld (hl),a
	inc hl
	ld a,l
	or h
	jr nz,spi_loader2
	ld a,e
	call print_hex
	ld a,26
	ld (pr_param),a
	ld a,e
	inc a
	cp 32
	jr c,spi_loader3
	call spi_end

	ld a,(page3init)
	ld bc,#13af
	out (c),a
	
	xor a
	out (#fe),a

	ld hl,str_done		;завершено
	call print_str
	
spi_loader4
	
	ld a,%00000100		; bit2 = 0:Loader ON, 1:Loader OFF; bit1 = 0:SRAM<->CPU0, 1:SRAM<->GS; bit0 = 0:M25P16, 1:enc424j600
	ld bc,system_port
	out (c),a

	ld sp,#ffff
	jp #0000		; запуск системы

; -----------------------------------------------------------------------------	
; SPI 
; -----------------------------------------------------------------------------
; Ports:

; #02: Data Buffer (write/read)
;	bit 7-0	= Stores SPI read/write data

; #03: Command/Status Register (write)
;	bit 7-1	= Reserved
;	bit 0	= 1:END   	(Deselect device after transfer/or immediately if START = '0')
; #03: Command/Status Register (read):
; 	bit 7	= 1:BUSY	(Currently transmitting data)
;	bit 6	= 0:INT ENC424J600
;	bit 5-0	= Reserved

spi_end
	ld a,%00000001		; config = end
	out (#03),a
	ret
spi_start
	xor a
	out (#03),a
	ret
spi_w
	in a,(#03)
	rlca
	jr c,spi_w
	ld a,d
	out (#02),a
	ret
spi_r
	ld d,#ff
	call spi_w
spi_r1	
	in a,(#03)
	rlca
	jr c,spi_r1
	in a,(#02)
	ret