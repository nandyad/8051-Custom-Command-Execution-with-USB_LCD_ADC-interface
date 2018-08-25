RS BIT P2.0 				; LCD
RW BIT P2.1 				; LCD
E BIT P2.2 					; LCD
RDD BIT P2.4 				; ADC0804
WRR BIT P2.5 				; ADC0804
INTR BIT P2.6 				; ADC0804
LED BIT P2.7 				; temperature sensing indicator
ORG 00H 	; START FROM HERE
MOV TMOD,#20H 				; timer 1, mode 2 (auto reload)
MOV TH1,#0FDH 				; for 9600 baud rate
MOV SCON,350H 				; 8bit data, 1 stop bit, REN enable
SETB TR1 					; start timer
CLR P2.3 					; input port of USB switch
SETB INTR 					; interrupt pin of ADC0804 is set for taking input
MOV P1,#0FFH 				; set ADC data port to input
MOV R0,#30H					; ram address stored for data log purpose
MOV 18H,#15 				; count of data(up to 16 locations from 30H)
MOV 7FH,#6 					; value on ram location for 1sec delay
CLR LED 					; off
;.................................................. end of all initialization ................................................
MAIN_ROUTINE:	ACALL LCD_INIT 			; LCD initialization
				ACALL NAME_SHOW 		; call name showing routine MOV DPTR,#START_LCD ; point dptr reg to database
				MOV A,#01H 				; clear lcd
				ACALL LCD_CMND 			; call LCD command routine
ADDRESS0: 		CLR A					; clear any garbage value
				MOVC A,@A+DPTR 			; get each character one by one 
				JZ ADDRESS1 			; if content of dptr becomes 0 jump to address1
				ACALL LCD_DATA 			; call LCD to transfer data
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR 				; next character
				SJMP ADDRESS0 			; stay inside loop
ADDRESS1: 		JNB P2.3,ADDRESS1 		; keep monitoring P2.3 port whether high
				MOV DPTR,#START_PC 		; when P2.3 is high load message to send
ADDRESS2: 		CLR A
				MOVC A,@A+DPTR
				JZ ACKW 				; if content becomes 0 jump to acknowledgement routine
				ACALL SEND 				; call send to send data serially to the computer
				INC DPTR
				ACALL MSDELAY
				SJMP ADDRESS2 			; stay inside loop
; ................................................... acknowledgement on LCD after successful connection ...........................................................
ACKW: 			MOV DPTR,#HAND_SHAKE	; to show a status on lcd
				MOV A,#01H 				; clear lcd
				ACALL LCD_CMND
ADDRESS3: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS4 			; if content of dptr becomes 0 jump to address4
				ACALL LCD_DATA 			; call lcd data
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS3
ADDRESS4: 		NOP
				NOP
				NOP
				NOP
				MOV 7FH,#5 				; default time delay for 2 sec
MAIN_LOOP: 		CLR RI 					; ready RI bit for serial communication 
				ACALL ADC_ON 			; if no command is received go adc routine
				ACALL RECEIVE 			;if data in sbuf call receive routine
				JB SCON.4,ADDRESS5 		;check REN bit for serial communication
				ACALL CHCK_COMMAND 		; call to check received command
				SETB SCON.4 			; set REN bit again to open sbuf
ADDRESS5: 		SJMP MAIN_LOOP 			; stay in this loop forever

;************************* end of MAIN_ROUTINE ***************************
;.......................................................... subroutines ............................................................
LCD_INIT:		MOV A,#38H 				; 2lines, 5x7 matrix
				ACALL LCD_CMND 			; call lcd command
				ACALL MSDELAY 			; give lcd some time
				MOV A,#0EH 				; display on cursor on
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,#01H 				; clear lcd ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,#06 				; shift cursor right
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,#80H 				; cursor at line 1,position 1
				ACALL LCD_CMND
				RET
;............................................... end of LCD initialization ..................................................
;............................................. LCD command subroutine .................................................
LCD_CMND: 		MOV P0,A 				; move 8bit data to p0 pins
				CLR P2.0 				; RS=0
				CLR P2.1 				; RW=0 SETB P2.2 ; E=high
				ACALL MSDELAY
				CLR P2.2 				; E=low
				RET
;.................................................. LCD data subroutine .....................................................
LCD_DATA: 		MOV P0,A 				;move 8bit data to p0
				SETB P2.0 				; RS=1
				CLR P2.1 				; RW=0 SETB P2.2 ; E=high
				ACALL MSDELAY
				CLR P2.2 				; E=low
				RET
;............................................... end of LCD subroutines ..................................................
SEND: 			MOV SBUF,A 				; load data to sbuf register for serial tx
ADDRESS6: 		JNB TI,ADDRESS6 		; stay until last bit is gone
				CLR TI 					; ready for next data
				RET
;........................................ end of serial transmit subroutine .........................................
RECEIVE: 		MOV A,SBUF 				; load accumulator with received data
				CJNE A,#'>',ADDRESS11 	; compare acc. with '>' if not, jump
				MOV A,#0DH 				; else put hex value of enter key for new line
				ACALL SEND
				MOV A,#'#'	 			; to inform user that device is ready to receive command
				ACALL SEND 				; call send routine to send data CLR RI ; clear RI for next data to receive
ADDRESS7: 		JNB RI,ADDRESS7 		; stay here until next data is on sbuf
				MOV A,SBUF 				; move that data to acc.
				MOV R1,A 				; save that data on r1 register(bank 0)
				CLR RI 					; next data
ADDRESS8: 		JNB RI,ADDRESS8
				MOV A,SBUF
				MOV R2,A 				; save that data on r2 register(bank 0)
				CLR RI
ADDRESS9: 		JNB RI,ADDRESS9
				MOV A,SBUF
				MOV R3,A 				; save that data on r3 register(bank 0)
				CLR RI
ADDRESS10: 		JNB RI,ADDRESS10
				MOV A,SBUF
				MOV R4,A 				; save that data on r4 register(bank 0)
				CLR RI
				CLR SCON.4 				; turn off serial tx-rx until received command is executed
ADDRESS11: 		NOP 					; if 1st data is not '>' exit from this subroutine / return
				RET
;......................................... end of serial receive subroutine ............................................
;.......................................... command checker subroutine .............................................
CHCK_COMMAND:	CJNE R1,#'l',ADDRESS14 		; compare saved data on r1 with 'l'
				CJNE R2,#'o',BAD_COMMAND	; if command doesn't match jump
				CJNE R3,#'g',BAD_COMMAND
				CJNE R4,#0DH,BAD_COMMAND 	; check last data if it is an 'Enter'
				ACALL ACPT_COMMAND 		; if all condition is ok call
				ACALL DATA_LOG 			; send data log saved on ram location
				RET 					; command executed, return
BAD_COMMAND:	SETB SCON.4 			; turn on serial communication
				MOV DPTR,#BAD_INPUT 	; load the message
ADDRESS12: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS13 			; if content is 0 jump
				ACALL SEND
				INC DPTR
				SJMP ADDRESS12
ADDRESS13: 		CLR SCON.4 				; turn off serial communication
				RET
ADDRESS14: 		CJNE R1,#'t',BAD_COMMAND	; if not same jump to bad command
				CJNE R2,#'0',ADDRESS23
				CJNE R3,#'1',ADDRESS15
				MOV 7FH,#1				; if command 1sec load 1 for delay loop
				SJMP ADDRESS24
ADDRESS15:		CJNE R3,#'2',ADDRESS16
				MOV 7FH,#5 				; if command 2sec load 5 for delay loop
				SJMP ADDRESS24
ADDRESS16:		CJNE R3,#'3',ADDRESS17
				MOV 7FH,#12 			; if command 3sec load 12 for delay loop
				SJMP ADDRESS24
ADDRESS17: 		CJNE R3,#'4',ADDRESS18
				MOV 7FH,#20 			; if command 4sec load 20 for delay loop 
				SJMP ADDRESS24
ADDRESS18:		CJNE R3,#'5',ADDRESS19
				MOV 7FH,#26 			; if command 5sec load 26 for delay loop 
				SJMP ADDRESS24
ADDRESS19:		CJNE R3,#'6',ADDRESS20
				MOV 7FH,#33 			; if command 6sec load 33 for delay loop 
				SJMP ADDRESS24
ADDRESS20: 		CJNE R3,#'7',ADDRESS21
				MOV 7FH,#40				; if command 7sec load 40 for delay loop 
				SJMP ADDRESS24
ADDRESS21:	 	CJNE R3,#'8',ADDRESS22
				MOV 7FH,#47 			; if command 8sec load 47 for delay loop 
				SJMP ADDRESS24
ADDRESS22:		CJNE R3,#'9',BAD_COMMAND
				MOV 7FH,#54 			; if command 9sec load 54 for delay loop 
				SJMP ADDRESS24
ADDRESS23: 		CJNE R2,#'1',BAD_COMMAND
				CJNE R3,#'0',BAD_COMMAND
				MOV 7FH,#61				; if command 10sec load 61 for delay loop
ADDRESS24: 		CJNE R4,#0DH,BAD_COMMAND 
				ACALL ACPT_COMMAND
				CLR SCON.4
				MOV A,#01H				;clear lcd
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,#84H 				;cursor at line 1. position 3 
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,R1
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#':'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,R2
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,R3
				ACALL LCD_DATA
				MOV A,#' '
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'S'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'e'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'c'
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				RET
;......................................... end of check command subroutine ....................................
ACPT_COMMAND: 	SETB SCON.4
				MOV DPTR,#ACPT_COMND
ADDRESS25: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS26 			; if content becomes zero jump 
				ACALL SEND
				INC DPTR
				ACALL MSDELAY
				SJMP ADDRESS25
ADDRESS26:		NOP 					;no operation
				RET
;.......................................... end of accept command subroutine ………….....................
ADC_ON: 		JB RI,ADDRESS29 		; if there is data in sbuf immediately return
				CLR WRR 				; set write pin of adc low to high  
				NOP						
				NOP						
				SETB WRR 				; conversion inside adc is started
ADDRESS27: 		JB INTR,ADDRESS27 		; stay until adc responds by interrupt pin low CLR RDD ; clear read pin to take 8bit data
				NOP
				NOP
				MOV A,P1 				; copy adc's data to accumulator
;............................................ store data (up to 16 locations) ............................................
				MOV 7DH,A 				;save the adc o/p here temporaily
				MOV R1,#31H 			;set R1 as pointer on 31h ram location
ADDRESS28: 		MOV A,@R1 				;begin the process of upward scrolling of stored data
				MOV @R0,A 				;continue..
				INC R0 					;increment R0 pointer for next location
				INC R1 					;increment R1 pointer for next location
				DJNZ 18H, ADDRESS28 	;keep doing upto 16 locations
				MOV 18H,#15 			;reset counter
				MOV R0,#30H 			;reset the pointer for 16 locations from 30h
				MOV A,7DH 				;take the adc o/p from previously saved location
				MOV 3FH,A 				;always save new adc o/p on last(16th) location
;...................................................... end of data storing ....................................................
				JB RI,ADDRESS29 		; if there is data in sbuf,  immediately return
				ACALL CONVERT 			; otherwise call hex to ascii converter
				JB RI,ADDRESS29			;rechecking the sbuf, if data comes return immediately
				ACALL LCD_TEMP 			; when conversion is done show it on lcd
				SETB LED 				; set led bit as a signal that adc is returning
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY 			; wait
				CLR LED 				; clear led bit
				ACALL SDELAY 			; wait for required time as commanded
ADDRESS29: 		SETB RDD 				; ready adc for new data
				NOP
				RET
;.............................................. end of ADC control subroutine .........................................
CONVERT: 		SETB PSW.4 				; store data of converter at register bank 2
				CLR PSW.3
			; ............... hex to decimal ..........
				MOV B,#10
				DIV AB
				MOV R2,B
				MOV B,#10
				DIV AB
				MOV R1,B
				MOV R0,A
			; .............. decimal to ascii .........
				MOV A,R0
				ORL A,#30H
				MOV R3,A
				MOV A,R1
				ORL A,#30H
				MOV R4,A
				MOV A,R2
				ORL A,#30H
				MOV R5,A
				CLR PSW.4 				; set register bank to default location (bank 0)
				RET
;................................................. end of convert subroutine ............................................
LCD_TEMP: 		SETB PSW.4 				; to access data go to bank 2
				CLR PSW.3
				MOV A,#01H 				; clear lcd
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,#82H 				; line 1, position 1
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,#'T'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'E'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'M'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'P'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'E'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'R'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'A'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'T'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'U'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'R'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'E'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#0C5H 			; 2nd line of lcd at position 4
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV A,R3
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,R4
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,R5
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#0DFH 			;hex value of degree sign , to show on LCD
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#'C'
				ACALL LCD_DATA
				ACALL MSDELAY
				MOV A,#0CH 				; cursor off
				ACALL LCD_CMND
				CLR PSW.4 				; back to bank 0
				RET
;................................. end of LCD temperature showing subroutine ..............................
DATA_LOG: 		MOV R1,#30H 			; point r1 at 30h ram location
				MOV 7EH,#16 			; load counter on 7Eh location
ADDRESS30: 		MOV A,@R1 				; copy data to acc. from pointed ram location of r1
ADDRESS31: 		ACALL CONVERT 			; call converter routine with data stored in acc.
				SETB PSW.4 				;get access to bank 2
				CLR PSW.3
				MOV A,#0DH 				; start a new line(Enter)
				ACALL SEND
				ACALL MSDELAY
				MOV A,#'T'
				ACALL SEND
				ACALL MSDELAY
				MOV A,#':'
				ACALL SEND
				MOV A,#20H 				; hex value of space
				ACALL SEND
				ACALL MSDELAY	
				MOV A,R3 				; copy data from r3 of bank 2 to acc and send
				ACALL SEND
				MOV A,R4 				; copy data from r4 of bank 2 to acc and send
				ACALL SEND
				ACALL MSDELAY
				MOV A,R5 				; copy data from r5 of bank 2 to acc and send
				ACALL SEND
				MOV A,#'C'	
				ACALL SEND
				ACALL MSDELAY
				CLR PSW.4 				; sending done, back to bank 0
				CLR PSW.3
				INC R1 					; increment location of data stored
				DJNZ 7EH,ADDRESS30
				CLR PSW.4 				; get back to bank 0 CLR PSW.3
				CLR SCON.4 				; turn off serial tx-rx
				RET
;............................................... end of data logger subroutine. ........................................
NAME_SHOW: 		MOV DPTR,#GRETTING 		; point DPTR to database
ADDRESS32: 		CLR A 					; clear any garbage value
				MOVC A,@A+DPTR 			; get each character one by one
				JZ ADDRESS33 			; if content becomes 0 jump
				ACALL LCD_DATA 			;call lcd to transfer data 
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR 				; next character
				SJMP ADDRESS32
ADDRESS33: 		MOV A,#0C0H 			; 2nd line of lcd
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV DPTR,#NAME1
ADDRESS34: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS35
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS34
ADDRESS35: 		ACALL SDELAY
				MOV A,#0C0H
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV DPTR,#NAME2
ADDRESS36: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS37
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS36
ADDRESS37: 		ACALL SDELAY
				MOV A,#0C0H
				ACALL LCD_CMND
				ACALL MSDELAY
				MOV DPTR,#NAME3
ADDRESS38:		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS39
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS38
ADDRESS39: 		ACALL SDELAY
				MOV DPTR,#INFO
				MOV A,#01H
				ACALL LCD_CMND
ADDRESS40: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS41
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS40
ADDRESS41: 		ACALL SDELAY
				MOV DPTR,#CON
				MOV A,#01H
				ACALL LCD_CMND
ADDRESS42: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS43
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS42
ADDRESS43: 		MOV A,#0C0H
				ACALL LCD_CMND
				MOV DPTR,#CON2
ADDRESS44: 		CLR A
				MOVC A,@A+DPTR
				JZ ADDRESS45
				ACALL LCD_DATA
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				ACALL MSDELAY
				INC DPTR
				SJMP ADDRESS44
ADDRESS45: 		MOV A,#0CH
				ACALL LCD_CMND
				ACALL SDELAY
				RET
;............................................ end of name showing subroutine ........................................
;....................................................... 28 millisecond delay ..................................................
MSDELAY: 		MOV R6,#50
HERE2: 			MOV R7,#255
HERE1: 			DJNZ R7,HERE1
				DJNZ R6,HERE2
				RET
;....................................................... time delay of second .................................................
SDELAY:			MOV R5,7FH 				;any preset delay saved by command on 7F ram location
HERE3: 			MOV R6,#255
HERE4: 			MOV R7,#255
HERE5: 			DJNZ R7,HERE5
				DJNZ R6,HERE4
				DJNZ R5,HERE3
				RET
;**************************** end of all subroutines ***********************
;............................................................. message strings ....................................................
START_LCD: 		DB ">>>>> READY >>>>",0
START_PC: 		DB "DEV IS CONNECTED TO THE SYSTEM(COM4)",0
HAND_SHAKE: 	DB "WRITING DEVICE..",0
BAD_INPUT: 		DB "WRONG COMMAND!",0
ACPT_COMND: 	DB "COMMAND ACCEPTED.",0
GRETTING: 		DB " Author: ",0
NAME1: 			DB " Aditya Nandy",0
NAME2: 			DB "  @GIT ",0
NAME3: 			DB "as Demo Project.",0
INFO: 			DB " Additional Info:  ",0
CON: 			DB " Type: DF ",0
CON2: 			DB " UART <--> USB ",0
;.............................................................................................................................................
END 		; end of program


;©A Nandy