	.equ			N = 3
	.def			DELAY_REGISTER = r18	
	sbi				DDRB,4					
		
INITIATE_Z:
	ldi				ZH,HIGH(MESSAGE*2)		
    ldi				ZL,LOW(MESSAGE*2)

MORSE:
	lpm				r16,Z					
	cpi				r16,$20					; Kollar om bokstaven vi laddar in �r ett mellanrum
	breq			SPACE					
	cpi				r16,$00					
	breq			STOP					
	call			LOOKUP					  

SEND:
	lsl				r16						; i SEND ligger fokuset p� att anv�nda C- och Z-flaggan f�r att ta reda p� hur det ska l�ta
	breq			NEXT_CHAR				; Efter vi l�st in den sista 1:an vet vi att r16 kommer vara tomt och vi allts� �r klara med det den karakt�ren
	brcc			DOT						; Om carry flaggan inte �r set s� hoppar vi till DOT annars forts�tter programmet.

DASH:
	call			BEEP					; D� vi vill pipa en g�ng f�r DOT och tre g�nger f�r DASH kan vi enkelt anropa BEEP som piper i en tidsenhet
	call			BEEP					;

DOT:
	call			BEEP
	cbi				PORTB,4					; St�nger av h�gtalaren
	ldi				DELAY_REGISTER,N		; Efter varje bit s� ska det vara en tidsenhet tystnad till n�sta bit. 
	call			DELAY					; 
	jmp				SEND					;		

NEXT_CHAR:
	adiw			ZL,1					; F�r n�sta bokstav vi ska l�sa in beh�ver vi addera 1 till v�ran Z-pekare s� att den pekar p� n�sta tecken i MESSAGE
	ldi				DELAY_REGISTER,2*N		; Ladda mitt DELAY-REGISTER med 2*N. Anledning till varf�r det �r 2*N och ej 3*N �r f�r att vi redan delayar ett N i BIT_DELAY.
	call			DELAY					
	jmp				MORSE					; Nu har vi hoppat och delayat vilket g�r att vi �r redo f�r att jobba med n�sta bokstav i MESSAGE 
		
LOOKUP:
	push			ZH						; F�rst pushar vi ZH och ZL ner p� stacken f�r att vi vill minnas vart de pekar
	push			ZL						; samt fortfarande kunna h�mta v�rden fr�n v�ran BTAB
	ldi				ZH,HIGH(BTAB*2)			; Efter vi har pushat och d�rmed sparat vart i MESSAGE vi pekar s� laddar vi in
	ldi				ZL,LOW(BTAB*2)			; S� att pekaren p� BTAB s� att vi kan h�mta den korresponderande bokstavens morse "v�rde" 
	subi			r16,$41					; D� alfabetet b�rjar p� 41 i ASCII och g�r upp�t kan vi veta vilken "plats" en bokstav har i alfabetet genom att subtrahera 41. Ex D = 44. 44-41 = 3.
	add				ZL,r16					; D har tredje platsen (index b�rjar p� 0). D� adderar vi 3 till Z-pekaren s� att den pekar p� D i BTAB.
	lpm				r16,Z					; Laddar in r�tt bokstav (i morse) fr�n BTAB.
	pop				ZL						; H�mta tillbaka v�rdena fr�n stacken s� att den Z-pekaren p� r�tt plats i MESSAGE
	pop				ZH						; Detta g�r �ven att vi slipper riktigt h�lla koll p� vart i v�rt meddelande vi �r.
	ret										;					


BEEP:
	ldi				DELAY_REGISTER,N		; D� vi alltid vill pipa i en tidsenhet s� laddar vi in N i v�rt DELAY_REGISTER.
	sbi				PORTB,4					; s�tter p� h�gtalaren.
	call			DELAY					;
	ret										;								

SPACE:
	ldi				DELAY_REGISTER,5*N		; Som jag skrev uppe i NEXT_CHAR s� laddar vi bara in 5 tidsenheter ist�llet f�r 7 d� vi redan har 2 tidsenheter av DELAY efter varje bokstav.
	call			DELAY					; 
	jmp				NEXT_CHAR				; 

DELAY:
	adiw			r24,1					; DELAY har f�rst en standard delay i och med "adiw r24,1 men i och med att vi �ven har "dec DELAY_REGISTER" kan vi f� DELAY att likna en metod
	brne			DELAY					; som i exempelvis Java d� den tar in "argument". I detta fall �r "argumentet" 
	dec				DELAY_REGISTER			; 
	brne			DELAY					; 
	ret										; 

STOP:
	jmp				STOP					; 

MESSAGE:
	.db				"ADA HY   ADA HY   ADA HY",$00

BTAB:
    .db				$60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8