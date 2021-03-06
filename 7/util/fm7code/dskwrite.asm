IO_MMRSWITCH		EQU		$FD93
IO_MMRMAP			EQU		$FD80
IO_URARAMSWITCH		EQU		$FD0F



PROG_ENTRY			BRA		PROG_REAL_ENTRY		; &H1400
RESTORE_ENTRY		BRA		RESTORE				; &H1402

DRIVE				FCB		0					; &H1404
					FCB		0					; &H1405  Used to be ERRORRETURN
FOR77AV				FCB		0					; &H1406

RESTORE				PSHS	A,B,X,Y,U,DP

					LDA		DRIVE,PCR
					STA		RESTORE_DRIVE,PCR

					LDA		#$FD
					TFR		A,DP

					LEAX	RESTORECMD,PCR
					CLR		ERRORRETURN,PCR

					; To avoid RS232C Disk BIOS redirecting JSR $FE02
					LDA		#$FE
					STA		RELOC1+1,PCR  ; This makes JSR $0002 to JSR $FE02
RELOC1				JSR		$0002
					BEQ		RESTORE_NOERROR
					INC		ERRORRETURN,PCR
RESTORE_NOERROR		PULS	A,B,X,Y,U,DP,PC





PROG_REAL_ENTRY		PSHS	A,B,X,U

KEY_LOOP			LBSR	WAIT_FOR_RETURN_KEY
					CMPA	#$1B
					LBEQ	DSKWRITE_ABORT



					TST		FOR77AV,PCR
					BEQ		SKIP_RESET_MMR

					CLR		IO_MMRSWITCH
					LDA		#$30
					LDX		#IO_MMRMAP
RESET_MMR_LOOP		STA		,X+
					INCA
					CMPA	#$40
					BNE		RESET_MMR_LOOP
SKIP_RESET_MMR



					ORCC	#$50
					STA		IO_URARAMSWITCH

					; BSR		RESTORE

					LDY		#$1800
					LBSR	WRITEDISK_CHUNK

					LDY		#$8000
					LBSR	WRITEDISK_CHUNK


					TST		FOR77AV,PCR
					BEQ		DSKWRITE_ABORT

					LDA		#$00
WRITE_MMR_LOOP		STA		IO_URARAMSWITCH
					CLR		IO_MMRSWITCH

					LDY		#IO_MMRMAP+8
					STA		,Y+
					INCA
					STA		,Y+
					INCA
					STA		,Y+
					INCA
					STA		,Y+
					INCA

					PSHS	X,U
					LDB		#$80
					STB		IO_MMRSWITCH
					LDX		#$8000
					LDU		#$2000
PULL_FROM_MMR_LOOP	LDY		,X++
					STY		,U++
					CMPU	#$6000
					BCS		PULL_FROM_MMR_LOOP
					CLR		IO_MMRSWITCH
					PULS	X,U

					PSHS	A
					LDY		#$2000
					LBSR	WRITEDISK_CHUNK
					PULS	A

					CMPA	#$10
					BNE		WRITE_MMR_LOOP

					CLR		IO_MMRSWITCH

DSKWRITE_ABORT
					LDA		IO_URARAMSWITCH
					ANDCC	#$AF
					PULS	A,B,X,U,PC





					; X String pointer
					; D String length
PRINT_SUBCPU		PSHS	A,B,X,Y
					BSR		HALT_SUBCPU

					LDY		#0
					STY		$FC80
					LDA		#3
					STA		$FC82

					CMPB	#124
					BCS		PRINT_SUBCPU_LIMIT
					LDB		#124
PRINT_SUBCPU_LIMIT	STB		$FC83

					LDY		#$FC84
PRINT_SUBCPU_LOOP	LDA		,X+
					STA		,Y+
					DECB
					BNE		PRINT_SUBCPU_LOOP

					BSR		RELEASE_SUBCPU

					PULS	A,B,X,Y,PC



HALT_SUBCPU			LDA		$FD05
					BMI		HALT_SUBCPU
					LDA		#$80
					STA		$FD05
HALT_SUBCPU_WAIT	LDA		$FD05
					BPL		HALT_SUBCPU_WAIT
					RTS



RELEASE_SUBCPU		CLR		$FD05
					RTS





					; Input Y: Chunk address
					; Input DRIVE: Target drive
WRITEDISK_CHUNK		LDA		DRIVE,PCR
					STA		DISKWRITE_DRIVE,PCR

					LDA		,Y
					CMPA	#$FF
					BEQ		WRITEDISK_CHUNK_END
					STA		DISKWRITE_TRACK,PCR
					LEAX	TRACK_STR_PTR,PCR
					LBSR	ItoA

					LDA		1,Y
					STA		DISKWRITE_SIDE,PCR
					LEAX	SIDE_STR_PTR,PCR
					LBSR	ItoA

					LDA		2,Y
					STA		DISKWRITE_SECTOR,PCR
					LEAX	SECTOR_STR_PTR,PCR
					LBSR	ItoA

					LEAX	POSITIONMSG,PCR
					LDD		#POSITIONMSG_END-POSITIONMSG
					PSHS	Y
					LBSR	PRINT_SUBCPU
					PULS	Y

					TFR		Y,D
					ADDD	#4
					STD		DISKWRITE_DATAPTR,PCR
					PSHS	Y
					BSR		WRITE_SECTOR
					PULS	Y


					LDX		#0
					LDB		3,Y	; Size Shift
					ABX
					LDD		#128
WRITEDISK_SIZESHIFT_LOOP
					CMPX	#0
					BEQ		WRITEDISK_SIZESHIFT_END
					LSLB
					ROLA
					LEAX	-1,X
					BRA		WRITEDISK_SIZESHIFT_LOOP
WRITEDISK_SIZESHIFT_END
					LEAY	D,Y
					LEAY	4,Y
					BRA		WRITEDISK_CHUNK

WRITEDISK_CHUNK_END
					RTS




					; The BIOS specification tells it writes 256 bytes.
					; However, disassembly of the BIOS looks to be writing
					; as many bytes until FDC returns IRQ.
					; If my reading is correct, this function should be good
					; for non-standard format as well as standard format.
WRITE_SECTOR		PSHS	DP
					ORCC	#$50	; Just to make sure
					LDA		#$FD
					TFR		A,DP

					LEAX	DISKWRITE_CMD,PCR
					CLR		ERRORRETURN,PCR

					; To avoid RS232C Disk BIOS redirecting JSR $FE05
					LDA		#$FE
					STA		RELOC2+1,PCR  ; This makes JSR $0005 to JSR $FE05
RELOC2				JSR		$0005

					BEQ		WRITE_SECTOR_NOERROR
					INC		ERRORRETURN,PCR

					; If $FE05 is used directly, A register is the error code.
					LEAX	WRITEERROR_MSG_CODE,PCR
					LBSR	XtoA
					LEAX	WRITEERROR_MSG,PCR
					LDD		#WRITEERROR_MSG_END-WRITEERROR_MSG
					LBSR	PRINT_SUBCPU

WRITE_SECTOR_NOERROR
					PULS	DP,PC

DISKWRITE_CMD		FCB		9
DISKWRITE_ERR		FCB		0
DISKWRITE_DATAPTR	FDB		0
DISKWRITE_TRACK		FCB		0
DISKWRITE_SECTOR	FCB		0
DISKWRITE_SIDE		FCB		0
DISKWRITE_DRIVE		FCB		0





					; Input:  DRIVE
					; Output: A key code 0x0d or 0x1b
WAIT_FOR_RETURN_KEY
					LDA		DRIVE,PCR
					ADDA	#'0'
					STA		ENTERKEYMSG_DRIVE,PCR

					LEAX	ENTERKEYMSG,PCR
					LDD		#ENTERKEYMSG_END-ENTERKEYMSG
					LBSR	PRINT_SUBCPU
WAIT_FOR_RETURN_KEY_LOOP
					LEAX	BIOSKEYIN_OUTBUF,PCR
					STX		BIOSKEYIN_PTR,PCR
					LEAX	BIOSKEYIN,PCR
					JSR		[$FBFA]
					LDA		BIOSKEYIN_OUTBUF+1,PCR
					BEQ		WAIT_FOR_RETURN_KEY_LOOP
					LDA		BIOSKEYIN_OUTBUF,PCR
					CMPA	#$1B
					BEQ		WAIT_FOR_RETURN_KEY_RTS
					CMPA	#$0D
					BNE		WAIT_FOR_RETURN_KEY_LOOP

WAIT_FOR_RETURN_KEY_RTS
					RTS
