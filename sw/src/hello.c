// Aponta para o nosso endereço de console mapeado em memória (MMIO)
#define console_output (*((volatile char*)0x10000000))

void print_string(const char* s) {
    
    while (*s) console_output = *s++;

}

int main() {

    // Imprime "Hello, World!\n" iterativamente
    print_string("Hello, World!\n");

    // Finaliza o código
    return 0;

}