#include <stdint.h>

// Definições de Endereços (Baseado no seu bus_interconnect e soc_top)
#define GPIO_BASE 0x20000000

// Ponteiros para os registradores
// Offset 0x00: LEDs (Write/Read)
#define REG_LEDS  (*(volatile uint32_t *)(GPIO_BASE + 0x00))
// Offset 0x04: Switches (Read Only)
#define REG_SW    (*(volatile uint32_t *)(GPIO_BASE + 0x04))

void main() {
    uint32_t counter = 0;
    uint32_t switches = 0;
    volatile int i; // 'volatile' impede o compilador de remover o loop de delay

    // Teste Inicial: Acende todos os LEDs por um momento
    REG_LEDS = 0xFFFF;
    for (i = 0; i < 1000000; i++); 

    while (1) {
        // Lê os switches
        switches = REG_SW;

        // Se o Switch 0 estiver ligado, copia os Switches para os LEDs
        // (Modo Pass-through para teste de entrada)
        if (switches & 0x1) {
            REG_LEDS = switches;
        } 
        // Se Switch 0 desligado, conta em binário
        else {
            REG_LEDS = counter;
            counter++;

            // Delay simples
            // Ajuste o valor 200000 se ficar muito rápido ou lento
            for (i = 0; i < 200000; i++);
        }
    }
}