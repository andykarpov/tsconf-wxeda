; -----------------------------------------------------------------------------
; LOADER(FAT32) 
; -----------------------------------------------------------------------------
;-----CONST-----
TOTAL_PAGE     	EQU   31         ; 31(512kB ROM)
;================== LOADER EXEC CODE ==========================================
		JP  StartProgFat32
		;- Name of ROMs files-----------------
FES1     	DB #10 ;flag (#00 - file, #10 - dir)
		DB "ROMS"	          ;DIR name
		DB 0
		;------
FES2     	DB #00 ;flag (#00 - file, #10 - dir)
		DB "ZXEVO.ROM"    ;file name //"TEST128.ROM"
		DB 0
		;-------------------------------------
;=======================================================================
StartProgFat32
		ld a,%00000001			; %00000001 (bit2=0, bit1=0, bit0=1)
		ld bc,system_port
		out (c),a

		ld hl,str_sd
		call print_str

		;DI               ; DISABLE INT                   (PAGE2)
		LD SP,PWA        ; STACK_ADDR = BUFZZ+#4000;    0xC000-x 
		LD BC,SYC,A,DEFREQ:OUT(C), A ;SET DEFREQ:%00000010-14MHz
		; перед испоьзованием STACK - преназначаем номер страницы
		;=======================================================
		CALL SWAP_PAGES

;=============== SD_LOADER========================================
SD_LOADER	
		;step_1	======== INIT SD CARD ========
		;-------		
		LD A, #00 	;STREAM: SD_INIT, HDD
		CALL FAT_DRV
		JR NZ,ERR_INIT	;INIT - FAILED
		;step_2 ======= find DIR entry =======	
		LD HL,FES1
		LD A, #01 	;find DIR entry
		CALL FAT_DRV
		JR NZ,ERR_DIR	;dir not found
		;-------------------------------------
		LD A, #02       ;SET CURR DIR - ACTIVE
		CALL FAT_DRV
		;step_3 ======= find File entry ====
		LD HL,FES2
		LD A, #01 	;find File entry
		CALL FAT_DRV
		JR NZ,ERR_FILE	;file not  found
		;step_4 ======= download data =======
		LD A, #0     	;#0 - start page 
		CALL FAT32_LOADER ; 
		;----------------------
		JP RESET_LOADER
;========================================================================================
FAT32_LOADER
		;----------- Open 1st Page = ROM ========================================
 		 ;LD A, #0     	;download in page #0
		 LD (block_16kB_cnt), A ; RESTORE block_16kB_cnt 
		 ;CALL COM_TX
 		 ;-------------------------------
		 LD C, A	;page Number
		 LD DE,#0000  	;offset in PAGE: 
  		 LD B, 32     	;1 block-512Byte/32bloks-16kB
		 LD A, #3     	;code 3: LOAD512(TSFAT.ASM) c
		 CALL FAT_DRV 	;return CDE - Address 
;-------------------------------------------------------------------------------------		
LOAD_16kb
;-------------------------------------------------------------------------------------	
		;------------------------- II ----------------------------------------
		;----------- Open 2snd Page = ROM 
		 LD A,(block_16kB_cnt)	 ; загружаем €чейку счетчика страниц в A
		 INC A			 ; block_16kB_cnt+1  увеличиваем значение на 1 
		 LD (block_16kB_cnt), A	 ; сохран€ем новое значение 
		 ;CALL COM_TX
		 ;-----------
		 LD C, A	         ;page 
		 LD DE,#0000             ;offset in Win3: 
		 LD B,32	         ;1 block-512Byte // 32- 16kB
		 ;-load data from opened file-------
		 LD A, #3       	 ;LOAD512(TSFAT.ASM) 
		 CALL FAT_DRV            ; читаем вторые 16kB
		 JR NZ,EXIT_FAT32_LOADER ;EOF -EXIT
		 ;-----------CHECK CNT--------------------------------------------
		 LD A,(block_16kB_cnt)	; загружаем €чейку счетчика страниц в A
		 SUB TOTAL_PAGE       	; провер€ем это был последний блок или нет
		 JR NZ,LOAD_16kb      	; если да то выход, если нет то возврат на 
					; LOAD_16kb
		;=================================================================
		;---------------
		; JP VS_INIT
		; JP RESET_LOADER
EXIT_FAT32_LOADER
		RET;

SWAP_PAGES
		;---PAGE3
		LD B,PW3/256 : IN A,(C)      ;READ PAGE3 //PW3:#13AF
		LD (PGR3),A                  ;(PGR3) <- SAVE orig PAGE3
		;---PAGE2
		LD B,PW2/256 : IN A,(C)      ;READ PAGE2 //PW2:#12AF 
		LD E,PG0: OUT (C),E          ;SET PAGE2=0xF7
		LD (PGR),A                   ;(PGR) <- SAVE orig PAGE2		
		RET		

RESTORE_PAGES
		;---ESTORE PAGE3
		LD BC,PW3,A,(PGR3):OUT (C),A
		;---ESTORE PAGE2
		LD BC,PW2,A,(PGR) :OUT (C),A
		RET	

;------------------------------------------------------------------------------		
ERR
		 CALL RESTORE_PAGES
		 ld hl,str_absent		;ошибка
		 call print_str
		 JP SPI_LOADER
ERR_INIT		 
		 CALL RESTORE_PAGES
		 ld hl,str_init_f		;ошибка инициализации
		 call print_str
		 JP SPI_LOADER
ERR_DIR
		 CALL RESTORE_PAGES
		 ld hl,str_dir_f		;ошибка чтени€ директории
		 call print_str
		 JP SPI_LOADER
ERR_FILE
		 CALL RESTORE_PAGES
		 ld hl,str_file_f		;ошибка чтени€ файла
		 call print_str
		 JP SPI_LOADER
ERR_READ
		 CALL RESTORE_PAGES
		 ld hl,str_err_f		;ошибка чтени€
		 call print_str
		 JP SPI_LOADER
;==============================================================================		


;----------------RESTART-------------------------------------------------------
RESET_LOADER
		CALL RESTORE_PAGES

		 ld hl,str_done		;завершено
		 call print_str		 

		;--------------------------------------------------
		LD A,%00000100	; Bit2 = 0:Loader ON, 1:Loader OFF;
		LD BC,system_port 
		OUT (C),A       ; RESET LOADER
		LD SP,#FFFF
		JP #0000	; RESTART SYSTEM 
		;// только после перехода на адрес 0x0000, LOADER OFF !!!!!!!!!		
;================================ DRIVER ======================================	
		;========TS-Labs==================================
		INCLUDE "inc/tsfat/TSFAT.ASM" ;
;---------------BANK2----------------------
PGR3 		EQU   STRMED+1   ; 
block_16kB_cnt  EQU   STRMED+2   ; 

