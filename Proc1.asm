#include <xc.inc>

;********************************************************************
; Programa para PIC16F887 que implementa un array de 14 elementos
; seleccionables mediante 4 bits del Puerto A
;********************************************************************
    
    LIST P=16F887
   
    
    ; Configuración del microcontrolador
   ; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (RC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, RC on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF             ; Watchdog Timer Enable bit (WDT enabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = ON            ; Brown Out Reset Selection bits (BOR enabled)
  CONFIG  IESO = ON             ; Internal External Switchover bit (Internal/External Switchover mode is enabled)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF   
 ;********************************************************************
; Programa para PIC16F887 que calcula los 14 primeros números de Fibonacci,
; los almacena en un array y permite visualizarlos en 3 displays de 7 segmentos
; controlados por 4 bits de entrada
;****************************************************************
    
    ; Variables en RAM
        org 0x20
        FibArray:ds  14 ; Array para los 14 números de Fibonacci
        Temp          equ 0x20     ; Variable temporal
        Index         equ 0x30      ; Índice seleccionado (0-13)
        Unidades      equ 0x31 ; Valor para display de unidades
        Decenas       equ 0x32 ; Valor para display de decenas
        Centenas     equ 0x33 ; Valor para display de centenas
        Counter      equ 0x34 ; Contador para multiplexación
        DisplayFlag  equ 0x35 ; Flag para control de displays
	 SEG_0      equ 0x40
	 SEG_1 equ 0x41 
	 SEG_2 equ 0x42 
	 SEG_3 equ 0x43 
	 SEG_4  equ 0x44 
         SEG_5 equ 0x45 
	 SEG_6 equ 0x46 
	 SEG_7 equ 0x47 
	 SEG_8 equ 0x48 
	 SEG_9 equ 0x49  
  
    
    ; Vector de reset
    ORG 0x000
    GOTO Inicio
    
    ; Vector de interrupción para multiplexación
    ORG 0x004
    GOTO Interrupcion
    
Inicio:
    ; Configuración del oscilador interno
    BANKSEL OSCCON
    MOVLW   0b01110000  ; Frecuencia de 8MHz
    MOVWF   OSCCON
    
    ; Configuración del Puerto A (RA0-RA3 como entradas digitales)
    BANKSEL ANSEL
    CLRF    ANSEL        ; Todos los pines como digitales
    BANKSEL TRISA
    MOVLW   0b00001111  ; RA0-RA3 como entradas, RA4-RA7 como salidas
    MOVWF   TRISA
    BANKSEL PORTA
    CLRF    PORTA        ; Limpiar Puerto A
    
    ; Configuración del Puerto B como salida (para displays de 7 segmentos)
    BANKSEL TRISB
    CLRF    TRISB        ; Puerto B como salida (segmentos)
    BANKSEL PORTB
    CLRF    PORTB
    
    ; Configuración del Puerto D como salida (para selección de displays)
    BANKSEL TRISD
    CLRF    TRISD        ; Puerto D como salida
    BANKSEL PORTD
    CLRF    PORTD
    
    ; Inicializar valores de los segmentos (ánodo común)
    MOVLW   0b11000000  ; Patrón para 0
    MOVWF   SEG_0
    MOVLW   0b11111001  ; Patrón para 1
    MOVWF   SEG_1
    MOVLW   0b10100100  ; Patrón para 2
    MOVWF   SEG_2
    MOVLW   0b10110000  ; Patrón para 3
    MOVWF   SEG_3
    MOVLW   0b10011001  ; Patrón para 4
    MOVWF   SEG_4
    MOVLW   0b10010010  ; Patrón para 5
    MOVWF   SEG_5
    MOVLW   0b10000010  ; Patrón para 6
    MOVWF   SEG_6
    MOVLW   0b11111000  ; Patrón para 7
    MOVWF   SEG_7
    MOVLW   0b10000000  ; Patrón para 8
    MOVWF   SEG_8
    MOVLW   0b10010000  ; Patrón para 9
    MOVWF   SEG_9
    
    ; Calcular serie de Fibonacci
    CALL    CalcularFibonacci
    
    ; Configurar interrupción para multiplexación de displays
    BANKSEL INTCON
    MOVLW   0b10100000  ; Habilitar interrupciones globales y TMR0
    MOVWF   INTCON
    BANKSEL OPTION_REG
    MOVLW   0b00000111  ; Prescaler 1:256 para TMR0
    MOVWF   OPTION_REG
    
MainLoop:
    ; Leer el valor del Puerto A (solo los 4 bits bajos)
    BANKSEL PORTA
    MOVF    PORTA, W
    ANDLW   0x0F        ; Máscara para solo los 4 bits bajos
    MOVWF   Index       ; Guardar el índice seleccionado
    
    ; Verificar que el índice esté en el rango 0-13 (14 elementos)
    MOVLW   0x0E        ; 14 en decimal
    SUBWF   Index, W    ; W = Index - 14
    BTFSC   STATUS, 0   ; Si Index >= 14, C=1
    GOTO    MainLoop    ; Si es mayor o igual, ignorar
    
    ; Obtener el número de Fibonacci seleccionado
    MOVLW   LOW FibArray ; Parte baja de la dirección inicial
    ADDWF   Index, W    ; Sumar el índice
    MOVWF   FSR         ; Guardar en FSR (File Select Register)
    MOVF    INDF, W     ; Leer el valor apuntado por FSR
    MOVWF   Temp        ; Guardar temporalmente
    
    ; Separar en centenas, decenas y unidades
    CALL    SepararDigitos
    
    GOTO    MainLoop    ; Repetir indefinidamente
    
;********************************************************************
; Subrutina: CalcularFibonacci
; Calcula los primeros 14 números de Fibonacci y los almacena en el array
;********************************************************************
CalcularFibonacci:
    ; Inicializar los dos primeros números (0 y 1)
    MOVLW   0
    MOVWF   FibArray+0
    MOVLW   1
    MOVWF   FibArray+1
    
    ; Calcular los siguientes números
    MOVLW   0x02        ; Empezar en el índice 2
    MOVWF   Index
    
CalcLoop:
    ; Calcular FibArray[n] = FibArray[n-1] + FibArray[n-2]
    MOVF    Index, W
    ADDLW   LOW FibArray
    MOVWF   FSR         ; FSR apunta a FibArray[n]
    
    DECF    FSR, F      ; FSR apunta a FibArray[n-1]
    MOVF    INDF, W     ; W = FibArray[n-1]
    MOVWF   Temp
    
    DECF    FSR, F      ; FSR apunta a FibArray[n-2]
    MOVF    INDF, W     ; W = FibArray[n-2]
    ADDWF   Temp, W     ; W = FibArray[n-1] + FibArray[n-2]
    
    INCF    FSR, F      ; FSR apunta a FibArray[n-1]
    INCF    FSR, F      ; FSR apunta a FibArray[n]
    MOVWF   INDF        ; Guardar el resultado
    
    ; Incrementar índice y verificar si hemos terminado
    INCF    Index, F
    MOVLW   0x0E
    SUBWF   Index, W
    BTFSS   STATUS, 0
    GOTO    CalcLoop
    
    RETURN
    
;********************************************************************
; Subrutina: SepararDigitos
; Separa un número en Temp en centenas, decenas y unidades
;********************************************************************
SepararDigitos:
    CLRF    Centenas
    CLRF    Decenas
    CLRF    Unidades
    
    ; Calcular centenas
CentenasLoop:
    MOVLW   100
    SUBWF   Temp, W
    BTFSS   STATUS, 0   ; Si Temp >= 100
    GOTO    CalcularDecenas
    MOVLW   100
    SUBWF   Temp, F
    INCF    Centenas, F
    GOTO    CentenasLoop
    
    ; Calcular decenas
CalcularDecenas:
    MOVLW   10
    SUBWF   Temp, W
    BTFSS   STATUS, 0   ; Si Temp >= 10
    GOTO    CalcularUnidades
    MOVLW   10
    SUBWF   Temp, F
    INCF    Decenas, F
    GOTO    CalcularDecenas
    
    ; El resto son unidades
CalcularUnidades:
    MOVF    Temp, W
    MOVWF   Unidades
    RETURN
    
;********************************************************************
; Rutina de interrupción para multiplexación de displays
;********************************************************************
Interrupcion:
    BANKSEL INTCON
    BCF     INTCON, 2  ; Limpiar flag de interrupción
    
    ; Rotar entre los tres displays
    BTFSC   DisplayFlag, 0
    GOTO    MostrarDecenas
    BTFSC   DisplayFlag, 1
    GOTO    MostrarCentenas
    
    ; Mostrar unidades
MostrarUnidades:
    BCF     DisplayFlag, 1
    BSF     DisplayFlag, 0
    
    ; Cargar patrón para unidades
    MOVLW   LOW SEG_0
    ADDWF   Unidades, W
    MOVWF   FSR
    MOVF    INDF, W
    BANKSEL PORTB
    MOVWF   PORTB
    
    ; Activar display de unidades (RD0)
    BANKSEL PORTD
    MOVLW   0b00000001
    MOVWF   PORTD
    RETFIE
    
MostrarDecenas:
    BCF     DisplayFlag, 0
    BSF     DisplayFlag, 1
    
    ; Cargar patrón para decenas
    MOVLW   LOW SEG_0
    ADDWF   Decenas, W
    MOVWF   FSR
    MOVF    INDF, W
    BANKSEL PORTB
    MOVWF   PORTB
    
    ; Activar display de decenas (RD1)
    BANKSEL PORTD
    MOVLW   0b00000010
    MOVWF   PORTD
    RETFIE
    
MostrarCentenas:
    BCF     DisplayFlag, 1
    
    ; Cargar patrón para centenas
    MOVLW   LOW SEG_0
    ADDWF   Centenas, W
    MOVWF   FSR
    MOVF    INDF, W
    BANKSEL PORTB
    MOVWF   PORTB
    
    ; Activar display de centenas (RD2)
    BANKSEL PORTD
    MOVLW   0b00000100
    MOVWF   PORTD
    RETFIE
    
    END
