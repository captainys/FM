					EXPORT	RS232C_RECEIVE_BUFFER_BEGIN
					EXPORT	RS232C_RECEIVE_BUFFER_SIZE
					EXPORT	RS232C_RECEIVE_BUFFER_USED
					EXPORT	RS232C_RECEIVE_ASCII





RS232C_RECEIVE_BUFFER_BEGIN	FDB			$6F00
RS232C_RECEIVE_BUFFER_SIZE	FDB			$0100
RS232C_RECEIVE_BUFFER_USED	FDB			0


					; Wait until (1) CR or LF is received, (2) Buffer filled up, or (3) Break key is pressed
RS232C_RECEIVE_ASCII
					PSHS	A,B,X,Y,U,CC

					ORCC	#$50
					STA		$FD0F

					LDU		RS232C_RECEIVE_BUFFER_BEGIN,PCR
					LDY		RS232C_RECEIVE_BUFFER_SIZE,PCR
					LDX		RS232C_IO,PCR

RS232C_RECEIVE_ASCII_LOOP
					LDA		$FD04
					ANDA	#2
					BEQ		RS232C_RECEIVE_ASCII_EXIT					; Break key?

					LDA		1,X								; 
					ANDA	#2									; 
					BEQ		RS232C_RECEIVE_ASCII_LOOP

					LDA		,X								; 
					CMPA	#13
					BEQ		RS232C_RECEIVE_ASCII_EXIT

					CMPA	#10
					BEQ		RS232C_RECEIVE_ASCII_LOOP			; Ignore 0x0A

					STA		,U+									; 
					LEAY	-1,Y
					BNE		RS232C_RECEIVE_ASCII_LOOP

RS232C_RECEIVE_ASCII_EXIT
					; BSR		RS232C_DISABLE_RECEIVE

					TFR		U,D
					SUBD	RS232C_RECEIVE_BUFFER_BEGIN,PCR
					STD		RS232C_RECEIVE_BUFFER_USED,PCR
					LDA		$FD0F
					PULS	A,B,X,Y,U,CC,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_DISABLE_RECEIVE
					PSHS	U
					LDU		RS232C_IO,PCR
					LDA		#$10			; Clear Error Flags
											; Disable Send/Receive
											; RTS off, DTR off
					STA		1,U
					PULS	U,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


					; Wait until (1) Buffer filled up, or (2) Break key is pressed
RS232C_RECEIVE_BINARY
					PSHS	A,B,X,Y,U,CC

					ORCC	#$50
					STA		$FD0F

					LDU		RS232C_RECEIVE_BUFFER_BEGIN,PCR
					LDY		RS232C_RECEIVE_BUFFER_SIZE,PCR
					LDX		RS232C_IO,PCR

RS232C_RECEIVE_BINARY_LOOP
					LDA		$FD04
					ANDA	#2
					BEQ		RS232C_RECEIVE_BINARY_EXIT			; Break key?

					LDA		1,X								; 
					ANDA	#2									; 
					BEQ		RS232C_RECEIVE_BINARY_LOOP

					LDA		,X
					STA		,U+

					LEAY	-1,Y
					BNE		RS232C_RECEIVE_BINARY_LOOP

RS232C_RECEIVE_BINARY_EXIT
					; BSR		RS232C_DISABLE_RECEIVE
					TFR		U,D
					SUBD	RS232C_RECEIVE_BUFFER_BEGIN,PCR
					STD		RS232C_RECEIVE_BUFFER_USED,PCR
					LDA		$FD0F
					PULS	A,B,X,Y,U,CC,PC
