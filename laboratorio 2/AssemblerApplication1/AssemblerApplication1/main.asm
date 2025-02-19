;
; AssemblerApplication1.asm
;
; Created: 2/12/2025 1:42:01 PM
; Author : Luis Pedro Monterroso
;


; Replace with your application code
.include"M328PBDEF.inc"
.cseg
.org 0x0000
.def    COUNTER = R20
//configuracion de la pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16 //CARGAR 0XFF A SPL(STACK POINTER LOW)
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16 //CARGAR 0X08 A SPH(STACK POINTER HIGH)


// Configuracion MCU
SETUP:
    // Configurar Prescaler "Principal"
    LDI     R16, (1 << CLKPCE)
    STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0b00000100
    STS     CLKPR, R16          // Configurar Prescaler a 1MHz

    // Inicializar timer0
    CALL    INIT_TMR0

    // Configurar PORTB como salida con leds apagados

    LDI		R16, 0xFF
	OUT		DDRB, R16 //PUERTO B COMO SALIDA
	LDI		R16, 0x00
	OUT		PORTB, R16  //Apago las LEDS
    
    LDI     COUNTER, 0x00
	LDI		R19 , 0x00  //CONTADOR

MAIN_LOOP:
    IN      R16, TIFR0          // Leer registro de interrupción de TIMER 0
    SBRS    R16, TOV0           // Salta si el bit 0 está "set" (TOV0 bit)
    RJMP    MAIN_LOOP           // Reiniciar loop
    SBI     TIFR0, TOV0         // Limpiar bandera de "overflow"
    LDI     R16, 100            
    OUT     TCNT0, R16          // Volver a cargar valor inicial en TCNT0
    INC     COUNTER
    CPI     COUNTER, 10         // R20 = 10 after 100ms (since TCNT0 is set to 10 ms)
    BRNE    MAIN_LOOP
    CLR     COUNTER				//aca ya pasaron 100ms
    CALL	OVERFLOW_CONT
    OUT		PORTB, R19
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
INIT_TMR0:
    LDI     R16, (1<<CS01) | (1<<CS00)
    OUT     TCCR0B, R16         // Setear prescaler del TIMER 0 a 64
    LDI     R16, 100            
    OUT     TCNT0, R16          // Cargar valor inicial en TCNT0
    RET
OVERFLOW_CONT:
	CPI		R19, 0x0F
	BREQ	LIMPIAR
	INC		R19
	RET
LIMPIAR:
	LDI		R19,0x00
	RET