;
; POSTLAB2.asm
;
; Created: 2/12/2025 4:03:59 PM
; Author : LUIS PEDRO MONTERROSO
;
.include"M328PBDEF.inc"
.cseg
.org 0x0000
.DEF	COUNTER = R23
.DEF	CONTADOR_DISP = R24
.DEF	CONTADOR_LEDS = R25
//configuracion de la pila
LDI		R16, LOW(RAMEND)
OUT		SPL, R16 //CARGAR 0XFF A SPL(STACK POINTER LOW)
LDI		R16, HIGH(RAMEND)
OUT		SPH, R16 //CARGAR 0X08 A SPH(STACK POINTER HIGH)

SETUP:
	//--------------------------------------------------SETUP DE LA FRECUENCIA DE TODO EL MC
    LDI     R16, (1 << CLKPCE)
    STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0b00000100		// 2^4 = 16 ES DECIR DIVIDIMOS 16MHz ENTRE 16
    STS     CLKPR, R16          // Configurar Prescaler a 1MHz
	//--------------------------------------------------SETUP DEL TIMER
	CALL    INIT_TMR0
	// DESACTIVAR UART PARA QUE NO EMPIECEN ENCENDIDOS LOS PRIMEROS DOS BITS DEL PORTD
	//DESACTIVAR UART
	LDI		R16, 0x00  
    STS		UCSR0B, R16  ; Deshabilitar transmisión y recepción  
	/*
    STS		UCSR0A, R16  ; Limpiar banderas de estado  
    STS		UCSR0C, R16  ; Asegurar que no está en modo especial  

	STS     UBRR0H, R16  
	STS     UBRR0L, R16  
	*/

//----------------------------------------------------------CONFIGURAR PUERTOS (DDRx, PORTx, PINx)
	//limpiar puerto 
	LDI		R16, 0x00  
	OUT		DDRD, R16  ; Temporariamente lo configuro como entrada  
	OUT		PORTD, R16 ; Aseguro que inicia apagado   
	//CONFIGURAR PUERTO D COMO SALIDA
	LDI		R16, 0xFF
	OUT		DDRD, R16 // CONFIGURAMOS PUERTO D COMO SALIDA
	LDI		R16, 0x00
	OUT		PORTD, R16 // LEDS APAGADOS

	//PUERTO C COMO SALIDA DE LAS LEDS
	LDI		R16, 0xFF
	OUT		DDRC, R16 // CONFIGURAMOS PUERTO D COMO SALIDA
	LDI		R16, 0x00
	OUT		PORTC, R16 // LEDS APAGADOS

	//CONFIGURAR PUERTO B COMO ENTRADA CON PULL UPS HABILITADOS
	LDI		R16, 0x00
	OUT		DDRB, R16 // CONFIGURAMOS PUERTO B COMO ENTRADA
	LDI		R16, 0xFF
	OUT		PORTB, R16 //HABILITAMOS PULL-PUS
	LDI		R18, 0xFF

	//-------------------------------------------------------------------------------CONFIGURAMOS DIRECCIONAMIENTO
	//LLENAR X CON LOS VALORES DEL DISPLAY
	LDI		XL, 0x00
	LDI		XH, 0x01
	.equ	SIZE = 17 //
	TABLA:	.db 0X7E, 0X30,0X6D,0X79,0X33,0X5B,0X5F,0X70,0X7F,0X7B,0X77,0X1F,0X4E,0X3D,0X4F,0X47
	LDI		ZH, HIGH(TABLA << 1)
	LDI		ZL, LOW(TABLA << 1)
	LDI		XH, 0X01
	LDI		XL, 0X00
	LDI		R21, SIZE
	COPIAR: 
			LPM		R22,Z+
			DEC		R21
			CPI		R21,0
			BREQ	INICIAR
			ST		X+,R22
			RJMP	COPIAR
//---------------------------------------------INICIZAR PUNTERO X Y SALIDA DEL DISPLAY
INICIAR:
	//VOLVEMOS A APUNTAR A 0X0100 
	LDI		XL, 0x00
	LDI		XH, 0x01
	LDI		R21, 0x00  //SALIDA DEL DISPLAY
	LDI		COUNTER, 0X00 //INICIALIZO EL COUNTER 
	LDI		R19,0X00 //SALIDA DE PORTC INICIALMENTE
	LDI		R17, 0X00
	LDI		CONTADOR_DISP,0X00
	LDI		CONTADOR_LEDS, 0X00
MAIN_LOOP:
	IN      R17, TIFR0          // Leer registro de interrupcion de TIMER 0
    SBRC    R17, TOV0           // Salta si el bit 0 esta "set" (TOV0 bit)
    RJMP    LEDS
	//---------------------------------------LOGICA DE LOS BOTONES---------------------------------------------
	IN      R16, PINB  // LEO PUERTO B
    CP      R16, R18   // VERIFICAR SI HAY CAMBIO
    BREQ    MAIN_LOOP  //EN BUCLE HASTA QUE CAMBIE

    CALL    DELAY  // AGREGO DELAY

	//REVISO OTRA VEZ DEPSUES DEL DELAY
	IN      R16, PINB  // LEO PUERTO B
    CP      R16, R18   // VERIFICAR SI HAY CAMBIO
    BREQ    MAIN_LOOP

	CALL    DELAY  // 2DO DELAY

	IN      R16, PINB  // LEO PUERTO B
    CP      R16, R18   // VERIFICAR SI HAY CAMBIO
    BREQ    MAIN_LOOP
	CALL	BOTONES
	CALL	COMPARAR
	RJMP	MAIN_LOOP

 COMPARAR:
	//ACA VAMOS A VER SI ESTAN EN LA MISMA POSICION
	CP		CONTADOR_DISP, CONTADOR_LEDS
	BREQ	REINICIAR
	RET
REINICIAR:
	SBI		PINC, 4
	LDI     R16, 100			// CON ESTE VALOR, TCNT0 ESTARA SET CADA 10MS      
    OUT     TCNT0, R16			//CARGAR VALOR A TCNT0
	LDI		R19, 0X00
	LDI		COUNTER, 0X00
	RET

	//-----------------------------------------------------LOGICA DE LAS LEDS------------------------------------------------
LEDS:
	// Reiniciar loop
    SBI     TIFR0, TOV0         // Limpiar bandera de "overflow"
    LDI     R17, 100            
    OUT     TCNT0, R17          // Volver a cargar valor inicial en TCNT0
    INC     COUNTER
    CPI     COUNTER, 100            // COUNTER = 100 DESPUES DE 1s (TCNT0 SET CADA 10MS)
	BRNE    MAIN_LOOP
	CLR     COUNTER				//aca ya paso 1 s
    CALL	OVERFLOW_CONT
    OUT		PORTC, R19
    RJMP	MAIN_LOOP
BOTONES:
// REVISAR QUE BOTON SE APACHO  
    EOR     R18, R16   // PONE EN 1 EL BOTON APACHADO
	LDI		R20 , 0XFF
	EOR		R20,R16
	AND		R18, R20
	LDI		R20, 0XFF
	EOR		R18,R20


    SBRC    R18, 0  
    CALL    SUMADOR
	MOV     R18, R16 

    SBRC    R18, 1  
    CALL    RESTADOR
	MOV     R18, R16 

    OUT     PORTD, R21  // NUMERO EN DISPLAY
    MOV     R18, R16    // Guardar el nuevo estado de botones
	RET

OVERFLOW_CONT:
	CPI		R19, 0x0F
	BREQ	LIMPIAR
	INC		R19
	INC		CONTADOR_LEDS
	RET

LIMPIAR:
	LDI		R19,0x00
	LDI		CONTADOR_LEDS, 0X00
	RET

SUMADOR:
	PUSH	R16
	LDI		R16, 0X0f //llego a 15
	CP		R16,R21
	BREQ	OVERF
    LD      R21, X+  // Cargar el siguiente valor desde la tabla
    POP		R16
	INC		CONTADOR_DISP
	RET
OVERF:
	POP		R16
	LDI		R21,0X7E //cero al disp
	LDI		XL, 0x00
	LDI		XH, 0x01
	LDI		CONTADOR_DISP, 0X00
	RET

RESTADOR:
	PUSH	R16
	LDI		R16, 0X00
	CP		R16,R21
	BREQ	UNDERF
    LD      R21, -X  
    POP		R16
	DEC		CONTADOR_DISP
	RET
UNDERF: //0X010F
	POP		R16
	LDI		R21,0X47 //cargo f al disp
	LDI		XL, 0x0F
	LDI		XH, 0x01
	LDI		CONTADOR_DISP, 0XFF
	RET

// -------------------DELAY-------------------

DELAY:
	PUSH	R20
	LDI		R20, 0
SUBDELAY1:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY1
	LDI		R20, 0
SUBDELAY2:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY2
SUBDELAY3:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY3
SUBDELAY4:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY4
SUBDELAY5:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY5
SUBDELAY6:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY6
SUBDELAY7:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY7
SUBDELAY8:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY8
SUBDELAY9:
	INC		R20
	CPI		R20,0
	BRNE	SUBDELAY9
	POP		R20
	RET

	//---------------------------------- INICIALIZAR TIMER0
INIT_TMR0:
    LDI     R16, (1<<CS01) | (1<<CS00)
    OUT     TCCR0B, R16         // Setear prescaler del TIMER 0 a 64 TCCTBOB = 0000 0011
    LDI     R16, 100			// CON ESTE VALOR, TCNT0 ESTARA SET CADA 10MS      
    OUT     TCNT0, R16          // Cargar valor inicial en TCNT0
    RET