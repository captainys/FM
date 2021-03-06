					ORG		$1400

					; TRANSFER $2000-$5FFF to Specified Physical Address


IO_MMRSWITCH		EQU		$FD93
IO_MMRMAP			EQU		$FD80
IO_URARAMSWITCH		EQU		$FD0F


PROG_ENTRY			BRA		REAL_ENTRY

PHYS_ADDR			FCB		0		; $1402

REAL_ENTRY			PSHS	A,B,X,Y,U,CC
					ORCC	#$50

					CLR		IO_MMRSWITCH
					LDY		#IO_MMRMAP
					LDA		#$30
MMR_RESET_LOOP1		STA		,Y+
					INCA
					CMPA	#$40
					BNE		MMR_RESET_LOOP1

					STA		IO_URARAMSWITCH

					LDA		PHYS_ADDR,PCR
					STA		IO_MMRMAP+8
					INCA
					STA		IO_MMRMAP+9
					INCA
					STA		IO_MMRMAP+10
					INCA
					STA		IO_MMRMAP+11

					LDA		#$80
					STA		IO_MMRSWITCH

					LDX		#$2000
					LDU		#$8000
TRANSFER_LOOP		LDD		,X++
					STD		,U++
					CMPX	#$6000
					BCS		TRANSFER_LOOP

					CLR		IO_MMRSWITCH
					LDA		IO_URARAMSWITCH

					LDY		#IO_MMRMAP
					LDA		#$30
MMR_RESET_LOOP2		STA		,Y+
					INCA
					CMPA	#$40
					BNE		MMR_RESET_LOOP2

					PULS	A,B,X,Y,U,CC,PC
