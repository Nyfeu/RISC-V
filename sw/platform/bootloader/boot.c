#include <stdint.h>

// =========================================================
// DEFINIÇÕES DE HARDWARE
// =========================================================

// Endereços Base
#define GPIO_BASE 0x20000000
#define UART_BASE 0x10000000

// --- GPIO ---
#define REG_LEDS        (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define REG_SW          (*(volatile uint32_t *)(GPIO_BASE + 0x04))

// --- UART ---
#define REG_UART_DATA   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_STATUS (*(volatile uint32_t *)(UART_BASE + 0x04))

// Máscaras de Bits
#define UART_TX_BUSY    (1 << 0)
#define UART_RX_READY   (1 << 1)

// =========================================================
// DRIVERS DA UART
// =========================================================

// Envia um caractere
void uart_putc(char c) {
    while (REG_UART_STATUS & UART_TX_BUSY);
    REG_UART_DATA = c;
}

// Envia uma string
void uart_puts(const char* str) {
    while (*str) {
        uart_putc(*str++);
    }
}

// =========================================================
// FUNÇÕES AUXILIARES MATEMÁTICAS 
// =========================================================

// Implementação manual de divisão e resto para evitar erros de
// "undefined reference to __udivsi3" em sistemas sem libgcc.

void simple_div_mod(uint32_t numerator, uint32_t denominator, uint32_t *quotient, uint32_t *remainder) {
    if (denominator == 0) {
        *quotient = 0;
        *remainder = 0;
        return;
    }

    uint32_t q = 0;
    uint32_t r = 0;

    // Percorre os 32 bits do numerador
    for (int i = 31; i >= 0; i--) {
        r <<= 1; // Desloca o resto para a esquerda
        r |= (numerator >> i) & 1; // "Desce" o próximo bit do numerador

        if (r >= denominator) {
            r -= denominator;
            q |= (1U << i); // Define o bit correspondente no quociente
        }
    }

    *quotient = q;
    *remainder = r;
}

// Função para imprimir números decimais usando a divisão manual
void print_dec(uint32_t n) {
    if (n == 0) {
        uart_putc('0');
        return;
    }

    char buffer[12];
    int i = 0;
    uint32_t q, r;

    while (n > 0) {
        // Substitui: r = n % 10; n = n / 10;
        simple_div_mod(n, 10, &q, &r);
        
        buffer[i++] = r + '0';
        n = q;
    }

    while (i > 0) {
        uart_putc(buffer[--i]);
    }
}

// =========================================================
// PROGRAMA PRINCIPAL
// =========================================================

void main() {
    volatile int i;
    
    // Variáveis para Fibonacci
    uint32_t t1 = 0, t2 = 1, nextTerm = 0;

    // 1. Sinalização Visual (Pisca LEDs)
    REG_LEDS = 0xFFFF;
    for (i = 0; i < 500000; i++);
    REG_LEDS = 0x0000;

    // 2. Cabeçalho na Serial
    uart_puts("\n\r");
    uart_puts("--------------------------------\n\r");
    uart_puts(" RISC-V Fibonacci               \n\r");
    uart_puts("--------------------------------\n\r");

    while (1) {
        // Reinicia a sequência
        t1 = 0;
        t2 = 1;

        uart_puts("Iniciando sequencia:\n\r");
        
        uart_puts("Termo 1: "); print_dec(t1); uart_puts("\n\r");
        uart_puts("Termo 2: "); print_dec(t2); uart_puts("\n\r");

        // Loop para gerar os próximos termos (limite 45 para não estourar 32 bits)
        for (int count = 3; count <= 45; ++count) {
            
            nextTerm = t1 + t2;
            t1 = t2;
            t2 = nextTerm;

            uart_puts("Termo ");
            print_dec(count);
            uart_puts(": ");
            print_dec(nextTerm);
            uart_puts("\n\r");

            // Exibe nos LEDs
            REG_LEDS = nextTerm & 0xFFFF;

            // Delay
            for (i = 0; i < 500000; i++);
        }

        uart_puts("--- Reiniciando ---\n\r");
        for (i = 0; i < 1000000; i++);
    }
}