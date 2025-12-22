#include <stdint.h>

// Endereços Base (Conforme Mapa de Memória)
#define UART_BASE 0x10000000
#define RAM_BASE  0x80000000

// Registradores UART (Offsets baseados no seu uart_controller)
#define UART_DATA (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STAT (*(volatile uint32_t*)(UART_BASE + 0x04))

// Registrador de Status: Bit 1 = RX Ready (Dado disponível)
#define UART_RX_READY 0x02 

void main() {
    uint32_t *ram_ptr = (uint32_t *)RAM_BASE;
    
    // 1. Sinaliza que o bootloader iniciou (Opcional: piscar LED ou enviar 'B')
    UART_DATA = 'B';

    // 2. Loop de Carregamento
    // Protocolo Simplificado: O bootloader fica lendo bytes e escrevendo na RAM.
    // Em um caso real, você implementaria um tamanho de pacote ou timeout.
    // Aqui, vamos assumir um loop infinito ou um número fixo para teste.
    
    while(1) {
        // Espera dado chegar na UART
        while ((UART_STAT & UART_RX_READY) == 0); 

        // Lê o dado (assumindo que enviamos palavras de 32 bits ou bytes)
        // Se for byte a byte, precisamos montar a word de 32 bits.
        // Simplificação: Vamos supor que o testbench envia words prontas.
        uint32_t data = UART_DATA; 

        // Escreve na RAM
        *ram_ptr = data;
        
        // Incrementa ponteiro
        ram_ptr++;

        // Verifica se terminou (Exemplo: se receber um "Magic Number" de fim)
        if (data == 0xDEADBEEF) {
            break;
        }
    }

    // 3. Pula para a aplicação na RAM
    // Cria um ponteiro de função para o início da RAM e chama
    void (*app_entry)() = (void (*)())RAM_BASE;
    app_entry();
}