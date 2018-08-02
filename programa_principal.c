// *****************************************************************************
//                           ¿Qué es esto?
// *****************************************************************************
/*
 Este es el programa propuesto para mi Real Case. Se lee la línea de CAN1 cada
 1 segundo y se manda esta informacióna al módulo xBee mediante el protocolo 
 RS-232. 
 Para comprobar el funcionamiento del circuito sin canal de comunicaciones, se 
 ha incorporado también una secuencia de parpadeo de LEDs. 
 
 Este programa se ha implementado con el dsPIC33EP128GP502. 
 
 
 Nombre del programa:               real_case.c
 Programador:                       Marta Basquens
 
 e-Tech Racing 2018 ©
 
 */

/*--------------------------------------------------
                     *    DEFINICIÓN DE VARIABLES       *
 * 
                    -------------------------------------------------------*/

unsigned int dato=0x15;
unsigned int flag_can1=0, data_can1_buff0=0,data_can1_buff1=0,data_can1_buff2=0, data_can1_buff3=0, leng_can1=0, data=0,cobid_can1;
unsigned char contador, contador_1, flag_led, flag_CAN, n=0, flag_alive=0, cont_alive=0, rbuf_can1;

/*--------------------------------------------------
                     *    DEFINICIÓN DE LIBRERÍAS       *
 * 
                    -------------------------------------------------------*/

#if defined(__PIC33xxx__)
#include <p33xxx.h>
#endif

#if defined(__PIC24xxx__)
#include <p24xxx.h>
#endif

#include <xc.h>
#include "main.h"
#include <stdio.h>
#include <stdlib.h>
#include <p33ep128gp502.h>


/*--------------------------------------------------
                     *    TIMER 2       *
 * Se entra en la interrupción cada 5 ms. 
                    -------------------------------------------------------*/

void __attribute__((__interrupt__,no_auto_psv)) _T2Interrupt(void){
    contador++;
    TMR2 = 15536;                         // 65536 - 50000 (5 ms) 
    IFS0bits.T2IF = 0;                    //PONE A 0 EL FLAG DE LA INTERRUPCIÓN DEL TIMER 2
    if (contador >= 20)                   // 20 x 5 ms = 100 ms 
    {
        contador=0;
        contador_1++;
    }
}

/*--------------------------------------------------
                     *    INTERRUPCIÓN UART       *
 * Cada vez que se transmite un carácter y por lo tanto se vacía el buffer
 * del shift register, se manda el siguiente carácter.
                    -------------------------------------------------------*/

void __attribute__((interrupt, no_auto_psv)) _U1TXInterrupt(void)
{
        IFS0bits.U1TXIF = 0;            // reset flag de interrupción TX  uart  
}

/*--------------------------------------------------
                     *    INTERRUPCIÓN CAN       *
 * Cada vez que se recibe un mensaje por la línea de CAN1 se lee el mensaje. 
                    -------------------------------------------------------*/

//CAN 1
void __attribute__ ( (interrupt, no_auto_psv) ) _C1Interrupt( void )
{  
    IFS2bits.C1IF = 0;                    // clear interrupt flag
    
    if( C1INTFbits.TBIF  )
    {
        C1INTFbits.TBIF = 0;             //Clear interrupt
    }
    if (C1INTFbits.RBIF  )
    {
        flag_CAN=1;
        C1INTFbits.RBIF = 0;             // clear interrupt RX
    }
}

//DMAs
void __attribute__ ( (interrupt, no_auto_psv) ) _DMA0Interrupt( void )
{
    IFS0bits.DMA0IF = 0;    // Clear the DMA0 Interrupt Flag;
}

void __attribute__ ( (interrupt, no_auto_psv) ) _DMA2Interrupt( void )
{
    IFS1bits.DMA2IF = 0;    // Clear the DMA0 Interrupt Flag;
}

/*--------------------------------------------------
                     *    PROGRAMA PRINCIPAL       *
 * 
                    -------------------------------------------------------*/

int main(void){
 /*                 ////////
 *        INICIALIZACIÓN DE CONFIGURACIONES        *
                    ////////                        */
    
    oscillator_config();
    clear_interrupt_flags();
    
    Ecan1Init();
    DMA0Init();
    DMA2Init();
    
    IEC2bits.C1IE = 1;
    C1INTEbits.TBIE = 1;
    C1INTEbits.RBIE = 1;
    
    timer_2_config();
    UART_config();
    
/*                 ////////
 *            DEFINICIÓN DE PUERTOS              *
                    ////////                    */
    ANSELB = 0;                              // PUERTO B DIGITAL
    ANSELA = 0;                              // PUERTO A DIGITAL
    
    TRISAbits.TRISA1=0;                      // leds 
    TRISBbits.TRISB1=0;
    
    TRISBbits.TRISB6=0;                      // TX como SALIDA - UART
    TRISBbits.TRISB7=1;                      // RX como ENTRADA - UART

    TRISBbits.TRISB10=0;                     // TX COMO SALIDA - CAN 1
    TRISBbits.TRISB11=1;                     // RX COMO ENTRADA - CAN 1
 
    
   while (1){
       
       if (flag_CAN ==1)
       {
           if (can1_isempty() == 1)
           {
              flag_CAN=0; 
           }
           else {
                //flag_CAN=0;
                PORTAbits.RA1=1;
                rbuf_can1 = can1_getrxbuf();  
                cobid_can1 = can1_getcobid(rbuf_can1);
                /*
                 printf("RBuf: %u\n", rbuf_can1);
                                // extrae el cobid del mensaje del buffer
                 printf("Cobid: %x\n", cobid_can1);
                 * */
                if (cobid_can1 == 0x80)
                {
                   flag_alive++;
                     if (flag_alive==4)
                     {
                         can1_write(0, 2, 0x600, cont_alive, 0, 0, 0);
                         C1TR01CONbits.TXREQ0 = 1;
                         cont_alive++;
                         PORTBbits.RB1=1;
                     } 
                }
                else if (cobid_can1 == 0x91)             // si recibe el cobid de los sensores de APPS1, APPS2, Brake y Steering
                {
                    leng_can1 = can1_getlength(rbuf_can1);           // extrae la longitud del mensaje del buffer
                     data_can1_buff0 = can1_getdata(rbuf_can1,0);     // extrae la información de la posición 0 del mensaje (2 primeros bytes)
                     data_can1_buff1 = can1_getdata(rbuf_can1,1);
                     data_can1_buff2 = can1_getdata(rbuf_can1,2);
                     data_can1_buff3 = can1_getdata(rbuf_can1,3);
                     C1RXFUL1 = 0;                                    // desmarcar el buffer como lleno 
                     C1RXFUL2 = 0;
                }
            }
        }
       
       if (contador_1 >=10){                // MANDA MENSAJE CADA 1 s por uart y secuencia de parpadeo LEDs 
           contador_1=0;
            if (flag_led==1){
                PORTBbits.RB1=0;            // apaga led
                PORTAbits.RA1=1;            // eciende led
                contador_1=0;
                flag_led=0;
            }
            else{
                PORTBbits.RB1=1;            // enciende led
                PORTAbits.RA1=0;            // apaga led
                contador_1=0;
                flag_led=1;
            }
           //  * */
           
           
            if (!U1STAbits.UTXBF)
            {
                U1TXREG = cont_alive;                  
                cont_alive++;
            }
            }   // */
       }    
}


//llegir cobid - 0x91 -> APPS1, APPS1, BRAKE, STEERING i enviar la seva informaició per UART 
//envia cobid 0x600 (alive) cada 4 cops que rebi 0x80 (missatge de si està viu o no)
// cada cop envia un contador incremental (per saber que està viu)