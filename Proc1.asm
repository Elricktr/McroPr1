;EvEE
PROCESSOR 16F887  
#include <xc.inc>
    
psect  barfunc,local,class=CODE,delta=2
    
;----------------------------------------------------------
; PROGRAMA FIBONACCI PARA PIC16F887 CON DISPLAY 7 SEGMENTOS
;----------------------------------------------------------

; CONFIGURACIÓN DEL MICROCONTROLADOR
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT 
  CONFIG  WDTE = OFF            
  CONFIG  PWRTE = ON            
  CONFIG  MCLRE = ON            
  CONFIG  CP = OFF              
  CONFIG  CPD = OFF             
  CONFIG  BOREN = ON            
  CONFIG  IESO = ON             
  CONFIG  FCMEN = ON            
  CONFIG  LVP = OFF             

; CONFIG2
  CONFIG  BOR4V = BOR40V        
  CONFIG  WRT = OFF             

; VARIABLES EN MEMORIA
    Contador    equ 0x20
    F_n         equ 0x21
    F_n1        equ 0x22
    F_n2        equ 0x23
    Centena     equ 0x24
    Decena      equ 0x25
    Unidad      equ 0x26
    ControlWord equ 0x28
    Delay1      equ 0x29
    Delay2      equ 0x30

; DEFINICIONES PARA DISPLAY 7 SEGMENTOS
#define DEC_PORT     PORTB ;Puerto para los segmentos
#define CEN_PORT     PORTD   ; Puerto para seleccionar dígito
#define UNI_PORT     PORTC

ORG 0x00
    GOTO Inicio
ORG 0x04
    RETFIE           ; Sin usar interrupciones

;----------------------------------------------------------
; CONFIGURACIÓN DEL RELOJ INTERNO
;----------------------------------------------------------
Configurar_Reloj:
    BANKSEL OSCCON
    MOVLW   0x70      ; Configura el oscilador interno a 8 MHz
    MOVWF   OSCCON
    RETURN

;----------------------------------------------------------
; SUBRUTINA DE RETARDO
;----------------------------------------------------------
Retardo:
    MOVLW   0xFF
    MOVWF   Delay1
Loop_Delay1:
    MOVLW   0xFF
    MOVWF   Delay2
Loop_Delay2:
    DECFSZ  Delay2, F
    GOTO    Loop_Delay2
    DECFSZ  Delay1, F
    GOTO    Loop_Delay1
    RETURN

;----------------------------------------------------------
; TABLA DE CONVERSIÓN PARA DISPLAY 7 SEGMENTOS
;----------------------------------------------------------
tabla_7seg: 
    ADDWF PCL, F        ; Ajusta el contador de programa (PCL) según el valor en W
    RETLW 0b00111111   ; 0
    RETLW 0b00000110   ; 1
    RETLW 0b01011011   ; 2
    RETLW 0b01001111   ; 3
    RETLW 0b01100110   ; 4
    RETLW 0b01101101   ; 5
    RETLW 0b01111101   ; 6
    RETLW 0b00000111   ; 7
    RETLW 0b01111111   ; 8
    RETLW 0b01101111   ; 9

;----------------------------------------------------------
; CONVERSIÓN BINARIO A DECIMAL (3 DÍGITOS)
;----------------------------------------------------------
Binario_a_Decimal:
    CLRF Centena
    CLRF Decena
    CLRF Unidad
    

Resta100:
    MOVLW   100
    SUBWF   F_n, W
    BTFSS   STATUS, 0
    GOTO    Resta10
    INCF    Centena, F
    MOVWF   F_n
    GOTO    Resta100

Resta10:
    MOVLW   10
    SUBWF   F_n, W
    BTFSS   STATUS, 0
    GOTO    Resta1
    INCF    Decena, F
    MOVWF   F_n
    GOTO    Resta10

Resta1:
    MOVF    F_n, W
    MOVWF   Unidad
    RETURN

;----------------------------------------------------------
; FUNCIÓN PARA ESCRIBIR EN DISPLAY 7 SEGMENTOS
;----------------------------------------------------------
Mostrar_En_Display:
    CALL Binario_a_Decimal
    
    MOVF Centena, W
    CALL tabla_7seg
    MOVWF CEN_PORT
   ;MOVLW 0b00000100
   ;MOVWF DIGIT_PORT
    CALL Retardo
    
    MOVF Decena, W
    CALL tabla_7seg
    MOVWF DEC_PORT
   ;MOVLW 0b00000010
   ;MOVWF DIGIT_PORT
    CALL Retardo
    
    MOVF Unidad, W
    CALL tabla_7seg
    MOVWF UNI_PORT
   ;MOVLW 0b00000001
   ;MOVWF DIGIT_PORT
    CALL Retardo
    
    RETURN

;----------------------------------------------------------
; PROGRAMA PRINCIPAL
;----------------------------------------------------------
Inicio:
    CALL Configurar_Reloj   ; Asegura que el reloj interno está configurado correctamente
    
    ; Configuración de puertos
    BANKSEL TRISB
    CLRF    TRISB      ; PORTB como salida (display 7 segmentos)
    CLRF    TRISC      ; PORTC como salida (selección de dígito)
    CLRF    TRISD
    BANKSEL PORTA
    MOVLW   0xff
    MOVWF   TRISA      ; PORTA como entrada
    
    ; Inicializa secuencia Fibonacci
    MOVLW   0
    MOVWF   F_n1       ; F(0) = 0
    MOVLW   1
    MOVWF   F_n2       ; F(1) = 1
    
    ; Calcula los 14 términos
    MOVLW   12         ; Ya tenemos 2 términos
    MOVWF   Contador

Calculo_Fibonacci:
    MOVF    F_n1, W
    ADDWF   F_n2, W
    MOVWF   F_n        ; F_n = F_n1 + F_n2
    
    
    ; Muestra en display 7 segmentos
    CALL    Mostrar_En_Display
    CALL    Retardo    ; Pequeña pausa para visualizar
    
    ; Actualiza valores
    MOVF    F_n2, W
    MOVWF   F_n1
    MOVF    F_n, W
    MOVWF   F_n2
    
    
    DECFSZ  Contador, F
    GOTO    Calculo_Fibonacci

Loop_Principal:
    GOTO    Loop_Principal

END
