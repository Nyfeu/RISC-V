// Aponta para o nosso endereço de console mapeado em memória (MMIO)
#define console_output (*((volatile char*)0x10000000))

void print_start() {
    // Imprime apenas um caractere
    console_output = 'S'; 
    console_output = 'T';
    console_output = 'A';
    console_output = 'R';
    console_output = 'T';
    console_output = '\n';
}

int main() {
    // Imprime "START\n" iterativamente
    while(1) {
        print_start();
    }

    // Finaliza o código
    return 0;
}