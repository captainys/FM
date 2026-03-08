; DS:0000h				Target Location
; DX					Target Length in number of 16-byte pages
; CX					Pattern Length
; ES:DI					Source Pattern
; ES:BX					Write Pattern
APPLY_PATCH				PROC

						CALL	FIND_SOURCE_PATTERN
						JC		SHORT APPLY_PATCH_EXIT

						PUSH	DS
						PUSH	ES
						POP		DS
						POP		ES

						MOV		DI,SI  ; DS:SI becomes destination ES:DI
						MOV		SI,BX  ; ES:BX becomes source DS:SI

						REP		MOVSB

APPLY_PATCH_EXIT:

						RET

APPLY_PATCH				ENDP





; DS:0000h				Target Location
; DX					Target Length in number of 16-byte pages
; CX					Pattern Length
; ES:DI					Source Pattern
;
; Output:
;   CF=0  DS:SI Pattern location
;   CF=1  Pattern not found
FIND_SOURCE_PATTERN		PROC

FIND_PATTERN_OUTSIDE_LOOP:
						XOR		SI,SI
FIND_PATTERN_INSIDE_LOOP:
						PUSH	CX
						PUSH	SI
						PUSH	DI
						REPE	CMPSB
						POP		DI
						POP		SI
						POP		CX
						JE		SHORT FIND_PATTERN_FOUND

						INC		SI
						CMP		SI,16
						JNE		FIND_PATTERN_INSIDE_LOOP

						MOV		AX,DS
						INC		AX
						MOV		DS,AX

						DEC		DX
						JNE		FIND_PATTERN_OUTSIDE_LOOP

						STC
						RET

FIND_PATTERN_FOUND:
						CLC
						RET

FIND_SOURCE_PATTERN		ENDP





; CX					Pattern Length
; CS:DI					Source Pattern
; CS:BX					Write Pattern
PATCH_IOSYS				PROC
						; DS:0000h				Target Location
						; DX					Target Length in number of 16-byte pages
						; CX					Pattern Length
						; ES:DI					Source Pattern
						; ES:BX					Write Pattern
						MOV		AX,0040H
						MOV		DS,AX			; Target 0040:0000
						MOV		DX,2000H		; 16 times 2000h = 128KB target size
						PUSH	CS
						POP		ES
						CALL	APPLY_PATCH
						RET
PATCH_IOSYS				ENDP



; 75h JNE -> EBh JMP
IO_SYS_ICM_BUG			DB		0BAh,08Ah,004h,0ECh,0A8h,006h,075h,044h,060h,0BBh,000h,0C0h
IO_SYS_ICM_NOBUG		DB		0BAh,08Ah,004h,0ECh,0A8h,006h,0EBh,044h,060h,0BBh,000h,0C0h

; UX's ROM IO.SYS had a similar bug.
IO_SYS_ICM_BUG_UX		DB		0BAh,08Ah,004h,0ECh,024h,006h,00Ah,0C0h,075h,027h
IO_SYS_ICM_NOBUG_UX		DB		0BAh,08Ah,004h,0ECh,024h,006h,00Ah,0C0h,0EBh,027h






; Force boot-time console to use 31KHz mode.
CRTC_31K:				DW	0060H,02C0H,0000H,0000H,031FH,0000H,0004H,0000H
						DW	0419H,008AH,030AH,008AH,030AH,0046H,0406H,0046H
						DW	0406H,0000H,008AH,0000H,0050H,0000H,008AH,0000H
						DW	0080H,0058H,0001H,0000H,801FH,0002H,0000H,0192H
CRTC_24K:				DW	0040H,0320H,0000H,0000H,035FH,0000H,0010H,0000H
						DW	036FH,009CH,031CH,009CH,031CH,0040H,0360H,0040H
						DW	0360H,0000H,009CH,0000H,0050H,0000H,009CH,0000H
						DW	0080H,004AH,0001H,0000H,001FH,0003H,0000H,0150H




; IO.SYS of Towns OS V2.1L20 is bugged and it crashes if an IC memory card is inserted.
; It needs to bypass IC Memory-Card check on INT 93H AX=0240H, otherwise it won't
; read from OS-ROM.  It tries to load from IC Memory Card.  (Was it intentional?)
; To make it start TownsO OS V2.1L20, IO.SYS can be patched before loading MSDOS.SYS,
; and restored after MSDOS.SYS is loaded.
; Turned out V1.1L30 as well.  Then probably V2.1L10, too.
PATCH_V21L20			PROC
						PUSH	DS
						PUSH	ES
						PUSHA
						MOV		CX,12
						MOV		DI,OFFSET IO_SYS_ICM_BUG
						MOV		BX,OFFSET IO_SYS_ICM_NOBUG
						CALL	PATCH_IOSYS

						MOV		CX,10
						MOV		DI,OFFSET IO_SYS_ICM_BUG_UX
						MOV		BX,OFFSET IO_SYS_ICM_NOBUG_UX
						CALL	PATCH_IOSYS

						MOV		CX,64
						MOV		DI,OFFSET CRTC_24K
						MOV		BX,OFFSET CRTC_31K
						CALL	PATCH_IOSYS
						POPA
						POP		ES
						POP		DS
						RET

PATCH_V21L20			ENDP

UNPATCH_V21L20			PROC
						PUSH	DS
						PUSH	ES
						PUSHA
						MOV		CX,12
						MOV		DI,OFFSET IO_SYS_ICM_NOBUG
						MOV		BX,OFFSET IO_SYS_ICM_BUG
						CALL	PATCH_IOSYS
						POPA
						POP		ES
						POP		DS
						RET
UNPATCH_V21L20			ENDP





; To disable the original CD-ROM BIOS.
;From:
;	3C16                      CMP     AL,16H
;	7F04                      JG      000018AF
;	3CFB                      CMP     AL,FBH
;	7D1C                      JGE     000018CB  <- V1.1 7D 0F
;	2C50                      SUB     AL,50H
;	BF                        MOV     DI,xxxxH
DISABLE_ORG_CDBIOS_FROM	DB		03CH,016H,07FH,004H,03CH,0FBH,07DH,01CH,02CH,050H,0BFH
DISABLE_ORG_CDBIOS_FROM_END:

DISABLE_ORG_CDBIOS_1_1_FROM	DB		03CH,016H,07FH,004H,03CH,0FBH,07DH,00FH,02CH,050H,0BFH
DISABLE_ORG_CDBIOS_1_1_FROM_END:

;To:
;	B90100                    MOV     CX,1
;	B480                      MOV     AH,80H
;	894E06                    MOV     [BP+06H],CX
;	886603                    MOV     [BP+03H],AH
;	804E0001                  OR      BYTE PTR [BP],01H
;	CB                        RETF
DISABLE_ORG_CDBIOS_TO	DB		0B9H,001H,000H,0B4H,080H,089H,04EH,006H,088H,066H,003H,080H,04EH,000H,001H,0CBH
DISABLE_ORG_CDBIOS_TO_END:



; Disable CD-ROM Caps Check.
;	0EFE:0000070B BAC004                    MOV     DX,04C0H
;	0EFE:0000070E EC                        IN      AL,DX
;	0EFE:0000070F A801                      TEST    AL,01H
;	0EFE:00000711 750B                      JNE     0000071E
;	0EFE:00000713 51                        PUSH    CX
;	0EFE:00000714 B91E00                    MOV     CX,001EH
;	0EFE:00000717 CDFD                      INT     FDH (Wait CX*10us)
;	0EFE:00000719 59                        POP     CX
;	0EFE:0000071A E2EF                      LOOP    0000070B  ->  33C9 XOR     CX,CX
DISABLE_CDROM_CAPS_CHECK	DB	0BAh,0C0h,004h,0ECh,0A8h,001h,075h,00Bh,051h,0B9h,01Eh,000h,0CDh,0FDh,059h,0E2h,0EFh
DISABLE_CDROM_CAPS_CHECK_END:


; The original IO.SYS uses INT 93H before the Rescue IPL can install YSSCSICD.SYS
; This blocks the boot process if the internal CD drive is removed.
; Also IO.SYS waits long time to check CD-ROM device capabilities.
; This function fixes these two problems when the internal CD drive is missing.
PATCH_DISABLE_INTERNAL_CDBIOS	PROC
						; Disable original CD-ROM BIOS.
						MOV		AX,0050H
						MOV		DS,AX			; Target 0040:0000
						MOV		DX,2000H		; 16 times 2000h = 128KB target size
						MOV		CX,OFFSET DISABLE_ORG_CDBIOS_FROM_END-OFFSET DISABLE_ORG_CDBIOS_FROM
						PUSH	CS
						POP		ES
						MOV		DI,OFFSET DISABLE_ORG_CDBIOS_FROM
						CALL	FIND_SOURCE_PATTERN
						JNC		CDBIOS_ENTRY_FOUND

						MOV		AX,0050H
						MOV		DS,AX			; Target 0040:0000
						MOV		DX,2000H		; 16 times 2000h = 128KB target size
						MOV		CX,OFFSET DISABLE_ORG_CDBIOS_1_1_FROM_END-OFFSET DISABLE_ORG_CDBIOS_1_1_FROM
						PUSH	CS
						POP		ES
						MOV		DI,OFFSET DISABLE_ORG_CDBIOS_1_1_FROM
						CALL	FIND_SOURCE_PATTERN
						JC		CDBIOS_ENTRY_NOT_FOUND

CDBIOS_ENTRY_FOUND:
						;DS:SI is the source pattern location in FBIOS.
						PUSH	DS
						POP		ES
						MOV		DI,SI

						MOV		CX,OFFSET DISABLE_ORG_CDBIOS_TO_END-OFFSET DISABLE_ORG_CDBIOS_TO
						MOV		SI,OFFSET DISABLE_ORG_CDBIOS_TO
						PUSH	CS
						POP		DS
						REP		MOVSB
CDBIOS_ENTRY_NOT_FOUND:



						MOV		AX,0050H
						MOV		DS,AX			; Target 0040:0000
						MOV		DX,2000H		; 16 times 2000h = 128KB target size
						MOV		CX,OFFSET DISABLE_CDROM_CAPS_CHECK_END-OFFSET DISABLE_CDROM_CAPS_CHECK
						PUSH	CS
						POP		ES
						MOV		DI,OFFSET DISABLE_CDROM_CAPS_CHECK
						CALL	FIND_SOURCE_PATTERN
						JC		CDROM_CAPS_CHECK_NOT_FOUND

						MOV		WORD PTR DS:[SI+OFFSET DISABLE_CDROM_CAPS_CHECK_END-OFFSET DISABLE_CDROM_CAPS_CHECK-2],0C933H

CDROM_CAPS_CHECK_NOT_FOUND:


						RET

PATCH_DISABLE_INTERNAL_CDBIOS	ENDP
