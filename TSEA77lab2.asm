	.equ			N = 3
	.def			DELAY_REGISTER = r18	
	sbi				DDRB,4					
		
INITIATE_Z:
	ldi				ZH,HIGH(MESSAGE*2)		
    ldi				ZL,LOW(MESSAGE*2)

MORSE:
	lpm				r16,Z					
	cpi				r16,$20					; Kollar om bokstaven vi laddar in är ett mellanrum
	breq			SPACE					
	cpi				r16,$00					
	breq			STOP					
	call			LOOKUP					  

SEND:
	lsl				r16						; i SEND ligger fokuset på att använda C- och Z-flaggan för att ta reda på hur det ska låta
	breq			NEXT_CHAR				; Efter vi läst in den sista 1:an vet vi att r16 kommer vara tomt och vi alltså är klara med det den karaktären
	brcc			DOT						; Om carry flaggan inte är set så hoppar vi till DOT annars fortsätter programmet.

DASH:
	call			BEEP					; Då vi vill pipa en gång för DOT och tre gånger för DASH kan vi enkelt anropa BEEP som piper i en tidsenhet
	call			BEEP					;

DOT:
	call			BEEP
	cbi				PORTB,4					; Stänger av högtalaren
	ldi				DELAY_REGISTER,N		; Efter varje bit så ska det vara en tidsenhet tystnad till nästa bit. 
	call			DELAY					; 
	jmp				SEND					;		

NEXT_CHAR:
	adiw			ZL,1					; För nästa bokstav vi ska läsa in behöver vi addera 1 till våran Z-pekare så att den pekar på nästa tecken i MESSAGE
	ldi				DELAY_REGISTER,2*N		; Ladda mitt DELAY-REGISTER med 2*N. Anledning till varför det är 2*N och ej 3*N är för att vi redan delayar ett N i BIT_DELAY.
	call			DELAY					
	jmp				MORSE					; Nu har vi hoppat och delayat vilket gör att vi är redo för att jobba med nästa bokstav i MESSAGE 
		
LOOKUP:
	push			ZH						; Först pushar vi ZH och ZL ner på stacken för att vi vill minnas vart de pekar
	push			ZL						; samt fortfarande kunna hämta värden från våran BTAB
	ldi				ZH,HIGH(BTAB*2)			; Efter vi har pushat och därmed sparat vart i MESSAGE vi pekar så laddar vi in
	ldi				ZL,LOW(BTAB*2)			; Så att pekaren på BTAB så att vi kan hämta den korresponderande bokstavens morse "värde" 
	subi			r16,$41					; Då alfabetet börjar på 41 i ASCII och går uppåt kan vi veta vilken "plats" en bokstav har i alfabetet genom att subtrahera 41. Ex D = 44. 44-41 = 3.
	add				ZL,r16					; D har tredje platsen (index börjar på 0). Då adderar vi 3 till Z-pekaren så att den pekar på D i BTAB.
	lpm				r16,Z					; Laddar in rätt bokstav (i morse) från BTAB.
	pop				ZL						; Hämta tillbaka värdena från stacken så att den Z-pekaren på rätt plats i MESSAGE
	pop				ZH						; Detta gör även att vi slipper riktigt hålla koll på vart i vårt meddelande vi är.
	ret										;					


BEEP:
	ldi				DELAY_REGISTER,N		; Då vi alltid vill pipa i en tidsenhet så laddar vi in N i vårt DELAY_REGISTER.
	sbi				PORTB,4					; sätter på högtalaren.
	call			DELAY					;
	ret										;								

SPACE:
	ldi				DELAY_REGISTER,5*N		; Som jag skrev uppe i NEXT_CHAR så laddar vi bara in 5 tidsenheter istället för 7 då vi redan har 2 tidsenheter av DELAY efter varje bokstav.
	call			DELAY					; 
	jmp				NEXT_CHAR				; 

DELAY:
	adiw			r24,1					; DELAY har först en standard delay i och med "adiw r24,1 men i och med att vi även har "dec DELAY_REGISTER" kan vi få DELAY att likna en metod
	brne			DELAY					; som i exempelvis Java då den tar in "argument". I detta fall är "argumentet" 
	dec				DELAY_REGISTER			; 
	brne			DELAY					; 
	ret										; 

STOP:
	jmp				STOP					; 

MESSAGE:
	.db				"ADA HY   ADA HY   ADA HY",$00

BTAB:
    .db				$60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8