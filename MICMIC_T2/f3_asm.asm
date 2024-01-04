#include <avr/io.h>
.extern valA
.global lerADC

lerADC:
	push r16

	lds r16, ADCSRA
	ori r16, 0b01000000
	sts ADCSRA, r16
waitADC:
	lds r16, ADCSRA
	andi r16, 0b01000000
	cpi r16, 0b01000000
	breq waitADC
	
	lds r16, ADCH
	sts valA, r16
	
	pop r16

	ret