#include <stdint.h>

// ============================================================================
// CONFIGURAÇÃO
// ============================================================================
#define UART_BASE       0x10000000
#define UART_DATA_REG   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_CTRL_REG   (*(volatile uint32_t *)(UART_BASE + 0x04))

#define STATUS_RX_AVAIL (1 << 1) 
#define CMD_POP_FIFO    (1 << 0) 

// O Bootloader fica em 0x0000. O App do usuário começa em 0x80000800 (2KB offset)
#define USER_APP_BASE   0x80000800

// ============================================================================
// AUXILIARES
// ============================================================================
uint8_t uart_get_byte() {
    while ((UART_CTRL_REG & STATUS_RX_AVAIL) == 0);
    uint8_t c = (uint8_t)UART_DATA_REG;
    UART_CTRL_REG = CMD_POP_FIFO;
    return c;
}

void uart_putc(char c) {
    while ((UART_CTRL_REG & 1) != 0); 
    UART_DATA_REG = c;
}

uint32_t uart_get_uint32() {
    uint32_t val = 0;
    // Recebe 4 bytes (Little Endian do Python struct.pack)
    val |= ((uint32_t)uart_get_byte()) << 0;
    val |= ((uint32_t)uart_get_byte()) << 8;
    val |= ((uint32_t)uart_get_byte()) << 16;
    val |= ((uint32_t)uart_get_byte()) << 24;
    return val;
}

// ============================================================================
// BOOTLOADER PRINCIPAL
// ============================================================================
void main() {
    // Feedback visual que estamos no bootloader
    uart_putc('\r'); uart_putc('\n');
    uart_putc('['); uart_putc('B'); uart_putc('O'); uart_putc('O'); uart_putc('T'); uart_putc(']');
    uart_putc(' ');

    // 1. ESPERA PELA MAGIC WORD "CAFEBABE"
    // Esperamos a sequência exata de bytes: CA, FE, BA, BE.
    // Isso funciona como uma máquina de estados simples.
    while (1) {
        if (uart_get_byte() == 0xCA) {
            if (uart_get_byte() == 0xFE) {
                if (uart_get_byte() == 0xBA) {
                    if (uart_get_byte() == 0xBE) {
                        break; // Recebeu o ticket dourado!
                    }
                }
            }
        }
        // Se errar a sequência, continua no loop esperando um novo 0xCA
    }

    // Envia ACK para o script Python saber que acordamos
    uart_putc('!'); 

    // 2. Recebe o tamanho (4 bytes)
    uint32_t program_size = uart_get_uint32();

    // 3. Grava na RAM
    volatile uint8_t *ram_ptr = (volatile uint8_t *)USER_APP_BASE;
    for (uint32_t i = 0; i < program_size; i++) {
        *ram_ptr = uart_get_byte();
        ram_ptr++;
        
        // Feedback a cada 1KB
        if ((i & 0x3FF) == 0) uart_putc('.');
    }

    uart_putc('>'); // Indica fim
    uart_putc('\r'); uart_putc('\n');

    // 4. JUMP PARA O APP DO USUÁRIO
    void (*user_app)() = (void (*)())USER_APP_BASE;
    user_app();

    // Armadilha caso o app retorne (não deveria)
    while(1); 
}