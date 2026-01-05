#include <stdint.h>

// =========================================================
// DEFINIÇÕES DE HARDWARE (MEMORY MAP)
// =========================================================
#define GPIO_BASE 0x20000000
#define UART_BASE 0x10000000
#define VGA_BASE  0x30000000

// Acesso direto aos registradores
#define REG_LEDS        (*(volatile uint32_t *)(GPIO_BASE + 0x00))
#define REG_SW          (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define REG_UART_DATA   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define REG_UART_STATUS (*(volatile uint32_t *)(UART_BASE + 0x04))

// Acesso à Memória de Vídeo (VRAM)
// Usamos uint8_t para escrever byte a byte (o Hardware agora alinha isso automaticamente)
#define VGA_VRAM        ((volatile uint8_t *)VGA_BASE)

// Registrador de Status do VGA (VSYNC)
// Mapeado no último endereço acessível do bloco VGA (Offset 0x1FFFF)
#define VGA_VSYNC_REG   (*(volatile uint32_t *)(VGA_BASE + 0x1FFFF))

// Dimensões da Tela
#define WIDTH  320
#define HEIGHT 240

// Cores Básicas (Formato 8 bits: RRR-GGG-BB)
#define BLACK   0x00
#define WHITE   0xFF
#define RED     0xE0
#define GREEN   0x1C
#define BLUE    0x03
#define YELLOW  0xFC
#define CYAN    0x1F
#define MAGENTA 0xE3

// =========================================================
// DRIVERS BÁSICOS
// =========================================================

// Função Bloqueante: Espera o VSYNC acontecer
// Garante que o jogo rode a 60 FPS cravados e sem "rasgar" a imagem
void wait_vsync() {
    // 1. Se já estivermos no meio de um pulso VSYNC (0), espera acabar
    while ((VGA_VSYNC_REG & 1) == 0);
    
    // 2. Espera o próximo pulso VSYNC começar (Sinal ir de 1 para 0)
    // Isso indica o EXATO momento que o monitor terminou de desenhar o quadro
    while ((VGA_VSYNC_REG & 1) == 1);
}

// Limpa a tela inteira (Lento, usar apenas no início)
void vga_clear(uint8_t color) {
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
        VGA_VRAM[i] = color;
    }
}

// Desenha um retângulo sólido (Otimizado)
void vga_rect(int x, int y, int w, int h, uint8_t color) {
    // Clipping Simples (Evita escrever fora da memória e travar o processador)
    if (x >= WIDTH || y >= HEIGHT) return;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x + w > WIDTH) w = WIDTH - x;
    if (y + h > HEIGHT) h = HEIGHT - y;

    // Desenha linha por linha
    for (int j = 0; j < h; j++) {
        int offset = (y + j) * WIDTH + x;
        volatile uint8_t *line_ptr = &VGA_VRAM[offset];
        
        for (int i = 0; i < w; i++) {
            line_ptr[i] = color;
        }
    }
}

// Gerador de números pseudo-aleatórios (Linear Congruential Generator)
uint32_t rand_state = 12345;
uint8_t get_random_color() {
    rand_state = rand_state * 1103515245 + 12345;
    uint8_t c = (rand_state >> 16) & 0xFF;
    return (c == 0) ? 0xFF : c; // Evita cor preta (invisível)
}

// =========================================================
// MAIN - O "JOGO"
// =========================================================
void main() {
    // --- Setup Inicial ---
    int box_size = 20;
    int x = 10, y = 10;     // Posição Inicial
    int dx = 2, dy = 2;     // Velocidade (Pixels por frame)
    uint8_t color = RED;
    
    REG_LEDS = 0x00;        // Reseta contador de batidas

    // Limpa a tela para começar limpo
    vga_clear(BLACK);
    
    // Desenha as bordas do campo (Brancas)
    vga_rect(0, 0, WIDTH, 2, WHITE);            // Topo
    vga_rect(0, HEIGHT-2, WIDTH, 2, WHITE);     // Base
    vga_rect(0, 0, 2, HEIGHT, WHITE);           // Esquerda
    vga_rect(WIDTH-2, 0, 2, HEIGHT, WHITE);     // Direita

    // --- Loop Infinito (Game Loop) ---
    while (1) {
        
        // 1. SINCRONIA: Espera o monitor terminar o quadro anterior
        // O processador fica "travado" aqui até dar 1/60 de segundo.
        // Isso substitui qualquer 'delay' manual.
        wait_vsync();

        // 2. LIMPEZA: Apaga o quadrado na posição VELHA (Pinta de preto)
        // Muito mais rápido que limpar a tela toda
        vga_rect(x, y, box_size, box_size, BLACK);

        // 3. FÍSICA: Calcula nova posição
        x += dx;
        y += dy;

        // 4. LÓGICA: Verifica Colisões nas Paredes
        int hit = 0;

        // Eixo X (Esquerda/Direita)
        // Usamos margem de 3 pixels por causa da borda branca desenhada
        if (x <= 3 || x + box_size >= WIDTH - 3) {
            dx = -dx;   // Inverte direção
            hit = 1;
            // Correção de posição para não "enterrar" na parede
            if (x <= 3) x = 3;
            else x = WIDTH - box_size - 3;
        }

        // Eixo Y (Cima/Baixo)
        if (y <= 3 || y + box_size >= HEIGHT - 3) {
            dy = -dy;   // Inverte direção
            hit = 1;
            // Correção de posição
            if (y <= 3) y = 3;
            else y = HEIGHT - box_size - 3;
        }

        // Se bateu, muda de cor e atualiza LEDs
        if (hit) {
            color = get_random_color();
            REG_LEDS = REG_LEDS + 1; // Contador binário nos LEDs da FPGA
        }

        // 5. DESENHO: Pinta o quadrado na posição NOVA
        vga_rect(x, y, box_size, box_size, color);
    }
}