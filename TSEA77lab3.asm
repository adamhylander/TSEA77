	.dseg
TIME:
	.byte	6

LINE:
	.byte	8
	.cseg

	.equ			LCD_CLR = $01
	.equ			E_MODE = $06
	.equ			DISP_ON = $0F
	.equ			FN_SET = $28
	.equ			RET_HOME = $02
	.equ			E = 1
	.equ			SECOND_TICKS = 62500 - 1 

	.def			COLON_REGISTER = r22
	ldi				COLON_REGISTER,$3A

	jmp				START
	
	.org			OC1Aaddr
	jmp				INTERRUPT

START:
	ldi				r16,HIGH (RAMEND)
	out				SPH,r16
	ldi				r16,LOW(RAMEND)
	out				SPL,r16
	call			LCD_PORT_INIT
	call			BACKLIGHT_ON
	call			LCD_INIT
	call			RESET_TIME
;	call			TESTING_MIDNIGHT
	call			TIMER1_INIT
	call			DELAY
	sei

MAIN:
	jmp				MAIN

TESTING_MIDNIGHT:						; Används bara för att visa att klockan funkar som den ska vid midnatt
	ldi				ZH,HIGH(TIME)		; Om man verkligen vill göra så att den funkar 100% korrekt så kan man
	ldi				ZL,LOW(TIME)		; kommentera bort call INIT_TIME_FORMAT och call LINE_PRINT i CLEAR
	ldi				r21,2				; Dem är bara där så att vi printar 00:00:00 vid en vanlig körning
	st				Z,r21
	adiw			Z,1
	ldi				r21,3
	st				Z,r21
	adiw			Z,1
	ldi				r21,5
	st				Z,r21
	adiw			Z,1
	ldi				r21,9
	st				Z,r21
	adiw			Z,1
	ldi				r21,5
	st				Z,r21
	adiw			Z,1
	ldi				r21,0
	st				Z,r21
	adiw			Z,1
	ret

RESET_TIME:
	ldi				ZH,HIGH(TIME)
	ldi				ZL,LOW(TIME)
	ldi				r21,6
	ldi				r20,$00

CLEAR:
	st				Z,r20
	adiw			Z,1
	dec				r21
	brne			CLEAR
	clr				r20
	st				Z,r20
	call			INIT_TIME_FORMAT
	call			LINE_PRINT
	ret

TIMER1_INIT:
	ldi				r16,(1<<WGM12)|(1<<CS12)
	sts				TCCR1B,r16
	ldi				r16,HIGH(SECOND_TICKS)
	sts				OCR1AH,r16
	ldi				r16,LOW(SECOND_TICKS)
	sts				OCR1AL,r16
	ldi				r16,(1<<OCIE1A)
	sts				TIMSK1,r16
	ret

INTERRUPT:
	push			r16
	in				r16,SREG
	call			TIME_TICK
	call			INIT_TIME_FORMAT
	call			LINE_PRINT
	out				SREG,r16
	pop				r16
	reti

LCD_PORT_INIT:
	ldi				r16,$FF
	out				DDRB,r16
	out				DDRD,r16
	ret

BACKLIGHT_ON:
	sbi				PORTB,2
	call			DELAY
	ret

BACKLIGHT_OFF:
	cbi				PORTB,2
	call			DELAY
	ret

LCD_INIT:
	ldi				r16,$30
	call			LCD_WRITE4
	call			LCD_WRITE4
	call			LCD_WRITE4
	ldi				r16,$20
	call			LCD_WRITE4

	ldi				r16,FN_SET
	call			LCD_COMMAND

	ldi				r16,DISP_ON
	call			LCD_COMMAND

	ldi				r16,LCD_CLR
	call			LCD_COMMAND

	ldi				r16,E_MODE
	call			LCD_COMMAND
	ret

TIME_TICK:
	push			r16
	ldi				XH,HIGH(TIME)
	ldi				XL,LOW(TIME)
	adiw			X,5

LOW_SEC:
	ld				r16,X
	cpi				r16,9
	breq			HIGH_SEC
	inc				r16
	st				X,r16
	jmp				END_COUNT

HIGH_SEC:
	call			SET_NULL
	ld				r16,X
	cpi				r16,5
	breq			LOW_MIN
	inc				r16
	st				X,r16
	jmp				END_COUNT

LOW_MIN:
	call			SET_NULL
	ld				r16,X
	cpi				r16,9
	breq			HIGH_MIN
	inc				r16
	st				X,r16
	jmp				END_COUNT				

HIGH_MIN:
	call			SET_NULL
	ld				r16,X
	cpi				r16,5
	breq			LOW_HOUR
	inc				r16
	st				X,r16
	jmp				END_COUNT

LOW_HOUR:
	call			SET_NULL
	ld				r16,X
	cpi				r16,9
	breq			HIGH_HOUR
	inc				r16
	st				X,r16
	sbiw			X,1
	ld				r17,X
	cpi				r17,2
	brne			END_COUNT
	cpi				r16,4
	breq			MIDNIGHT
	jmp				END_COUNT

HIGH_HOUR:
	call			SET_NULL
	ld				r16,X
	inc				r16
	st				X,r16
	jmp				END_COUNT

MIDNIGHT:
	call			RESET_TIME
	jmp				END_COUNT

SET_NULL:
	clr				r16
	st				X,r16
	sbiw			X,1
	ret

END_COUNT:
	pop				r16
	ret

INIT_TIME_FORMAT:
	push			XH
	push			XL
	push			YH
	push			YL
	ldi				XH,HIGH(TIME)
	ldi				XL,LOW(TIME)
	ldi				YH,HIGH(LINE)
	ldi				YL,LOW(LINE)
	clr				r23

TIME_FORMAT:
	inc				r23
	cpi				r23,3
	breq			PRINT_COLON
	cpi				r23,6
	breq			PRINT_COLON
	ld				r16,X
	ori				r16,0x30
	st				y,r16
	adiw			X,1
	adiw			Y,1
	cpi				r23,8
	brne			TIME_FORMAT
	clr				r23
	pop				YL
	pop				YH
	pop				XL
	pop				XH
	ret

PRINT_COLON:
	st				Y,COLON_REGISTER
	adiw			Y,1
	jmp				TIME_FORMAT

LINE_PRINT:
	call			LCD_HOME
	ldi				ZH,HIGH(LINE)
	ldi				ZL,LOW(LINE)
	ldi				r18,8
	call			LCD_PRINT
	ret

LCD_PRINT:
	ld				r16,Z
	call			LCD_ASCII
	adiw			Z,1
	dec				r18
	brne			LCD_PRINT
	ret

LCD_HOME:
	ldi				r16,RET_HOME
	call			LCD_COMMAND
	ret

LCD_ERASE:
	ldi				r16,LCD_CLR
	call			LCD_COMMAND
	ret

LCD_WRITE4:
	sbi				PORTB,E
	out				PORTD,r16
	cbi				PORTB,E
	call			DELAY
	ret

LCD_WRITE8:
	call			LCD_WRITE4
	swap			r16
	call			LCD_WRITE4
	swap			r16
	ret

LCD_ASCII:
	sbi				PORTB,0
	call			LCD_WRITE8
	ret

LCD_COMMAND:
	cbi				PORTB,0
	call			LCD_WRITE8
	ret

DELAY:
	adiw			r24,1
	brne			DELAY
	ret