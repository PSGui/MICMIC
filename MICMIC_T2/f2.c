/* 

 * Este programa em linguagem C destina-se a um microcontrolador AVR.

 * Ele controla um motor usando técnicas de modulação por largura de pulso (PWM)

 * e exibe informações em um display de 7 segmentos.

 * 

 * Funcionalidades:

 * - Temporizador TC0 com interrupção a cada 5ms.

 * - Temporizador TC2 configurado para PWM, com saída em OC2 (PB7) e frequência de 500Hz.

 * - Sentido de rotação controlado pelos pinos Dir0 (PB5) e Dir1 (PB6).

 * - SW1 incrementa a velocidade em 5 unidades.

 * - SW2 decrementa a velocidade em 5 unidades.

 * - SW5 inverte o sentido de rotação (motor parado por 500ms).

 * - SW6 para o motor.

 */



#include <avr/interrupt.h>

#include <util/delay.h>

#include <stdio.h>

#define F_CPU 16000000UL



const unsigned char digitos[] = {0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0xFF};

const unsigned char minus[] = {0xFF, 0b10111111};

unsigned char i = 1;



volatile unsigned char flag5ms = 0;

volatile unsigned char flagStop = 0;

volatile unsigned char flagInv = 0;

volatile unsigned char dt = 50;

volatile unsigned char flagMode = 0; //modo digital(0) e switches(1)

unsigned char x;

unsigned char inPut;

unsigned char disp0 = 0;

unsigned char disp1 = 5;

unsigned char sinal = 0;



typedef struct USARTRX {

    char receiver_buffer;

    unsigned char status;

    unsigned char receive:1;

    unsigned char error:1;

} USARTRX_st;



volatile USARTRX_st rxUSART = {0, 0, 0, 0};



char transmit_buffer[10]; //TENHO DE ACABAR!!!!!!!!!!!!!!!!!!!!



void inic(void) {

    DDRA = 0b11000000;      // Porto A (interruptores e define display)

    PORTA = 0b11000000;     // Escolher display 0

    DDRC = 0b11111111;      // Porto C (display de 7 segmentos)

    PORTC = 0b11111111;     // Apagar display

    DDRB = 0b11100000;

    PORTB = 0b01000000;     // Defenir direção de rotação do motor



    /*********************************

        USART1 config

    *********************************/

    UBRR1H = 0;   // Ativa USART1

    UBRR1L = 103; // 19200 bps depende do U2X1

    UCSR1A = (1 << U2X1); // dobro da velocidade

    UCSR1B = (1 << RXCIE1) | (1 << RXEN1) | (1 << TXEN1);

    UCSR1C = (1 << UCSZ11) | (1 << UCSZ10);



    /*********************************

        TC0 e TC2 config

    *********************************/



    OCR0 = 77;       // 5ms

    TCCR0 = 0b00001111; //



    OCR2 = 128;

    TCCR2 = 0b01100011; // Modo Phase Correct, prescaler 64 (490Hz)



    TIMSK |= 0b00000010; //

    sei(); // SREG |= 0x80

}



///////////////////////////////////////////////////////////////



void send_message(char *buffer) { //TENHO DE ACABAR

    unsigned char i = 0;

    while (buffer[i] != '\0') {

    }

}



///////////////////////////////////////////////////////////////



ISR(USART1_RX_vect) {

    rxUSART.status = UCSR1A;

    if (rxUSART.status & ((1 << FE1) | (1 << DOR1) | (1 << UPE1))) {

        rxUSART.error = 1;

    }

    rxUSART.receiver_buffer = UDR1;

    rxUSART.receive = 1;

}



ISR(TIMER0_COMP_vect) {

    // flag5ms=1;

    if (flagInv != 0) {

        flagInv--;

        PORTC = digitos[10];

    } else {

        disp0 = dt % 10;

        disp1 = dt / 10;

        if (disp1 == 10) {

            disp1 = 9;

            disp0 = 9;

        }

        switch (i) {

        case 0:

            PORTA = 0b11000000;

            PORTC = digitos[disp0];

            break;

        case 1:

            PORTA = 0b10000000;

            PORTC = digitos[disp1];

            break;

        case 2:

            PORTA = 0b01000000;

            PORTC = minus[sinal];

            break;

        }

        i++;

        if (i == 3) i = 0;

    }

}



void Inv(void) {

    while (flagInv != 0);

    if (sinal == 0) {

        sinal = 1;

        PORTB = 0b00100000;

    } else {

        sinal = 0;

        PORTB = 0b01000000;

    }

    x = (dt * 255) / 100;

    OCR2 = x;

}



int main(void) {

    unsigned char flag = 0;

    inic();

    while (1) {

        if (flagMode == 0) {

            if (rxUSART.receive == 1) {

                inPut = rxUSART.receiver_buffer;

                rxUSART.receive = 0;

            }

        } else {

            inPut = PINA & 0b00110011;

        }

        switch (inPut) {

        case 0b00110010: // SW1 Incrementa 5%

        case '+':

            _delay_ms(5);

            if (flag == 0) {

                flag = 1;

                if (flagStop == 1) {

                    flagStop = 0;

                    x = (dt * 255) / 100;

                    OCR2 = x;

                } else {

                    if (dt < 100) {

                        dt = dt + 5;

                        x = (dt * 255) / 100;

                        OCR2 = x;

                    }

                }

            }



            break;

        case 0b00110001: // SW2 Decrementa 5%

        case '-':

            _delay_ms(5);

            if (flag == 0) {

                flag = 1;

                if (flagStop == 1) {

                    flagStop = 0;

                    x = (dt * 255) / 100;

                    OCR2 = x;

                } else {

                    if (dt > 0) {

                        dt = dt - 5;

                        x = (dt * 255) / 100;

                        OCR2 = x;

                    }

                }

            }



            break;

        case 0b00100011: // SW5 Inverte rotação

        case 'i':

        case 'I':

            _delay_ms(5);

            if (flag == 0 && flagStop == 0) {

                flag = 1;

                flagInv = 100;

                OCR2 = 0;

                Inv();

            }



            break;

        case 0b00010011: // SW6 Stop

        case 'p':

        case 'P':

            _delay_ms(5);

            if (flag == 0) {

                flag = 1;

                flagStop = 1;

                OCR2 = 0;

            }



            break;

        default:

            flag = 0;

            break;

        }

        inPut = 0b00000000;

        /*if (flag5ms==1){

            flag5ms=0;

            Display();

            }*/

    }

}