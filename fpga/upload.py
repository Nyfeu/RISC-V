import serial
import struct
import sys
import time
import os

# CONFIGURAÇÕES
SERIAL_PORT = "COM6" 
BAUD_RATE   = 115200
FILE_NAME   = "app.bin"

# --- DETECÇÃO DE SISTEMA OPERACIONAL E TECLADO ---
if os.name == 'nt':
    # Windows
    import msvcrt
    
    def kb_hit():
        return msvcrt.kbhit()
    
    def get_char():
        return msvcrt.getch()
        
    class TerminalSettings:
        def __enter__(self):
            return self
        def __exit__(self, exc_type, exc_val, exc_tb):
            pass # Nada a fazer no Windows

else:
    # Linux / WSL / Mac
    import tty
    import termios
    import select
    
    def kb_hit():
        # Verifica se há algo no stdin pronto para ler
        dr, dw, de = select.select([sys.stdin], [], [], 0)
        return dr != []
    
    def get_char():
        return sys.stdin.read(1).encode('utf-8')

    class TerminalSettings:
        # Context Manager para colocar o terminal em modo RAW (lê tecla sem Enter)
        def __enter__(self):
            self.fd = sys.stdin.fileno()
            self.old_settings = termios.tcgetattr(self.fd)
            tty.setcbreak(self.fd)
            return self
        def __exit__(self, exc_type, exc_val, exc_tb):
            termios.tcsetattr(self.fd, termios.TCSADRAIN, self.old_settings)

# --- PROGRAMA PRINCIPAL ---

def main():
    if len(sys.argv) > 1:
        fname = sys.argv[1]
    else:
        fname = FILE_NAME

    if not os.path.exists(fname):
        print(f"Erro: Arquivo '{fname}' não encontrado.")
        return

    file_size = os.path.getsize(fname)
    ser = None
    
    # Contexto para garantir que o terminal volte ao normal no Linux
    with TerminalSettings():
        try:
            # Tenta abrir porta. No WSL, pode precisar de permissão (sudo chmod 666 /dev/ttyS6)
            ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=5)
            print(f"--- Conectado em {SERIAL_PORT} ---")
            print("Pressione 'ESC' a qualquer momento para sair.\n")
            
            print("1. Aguardando Bootloader (Reinicie a placa se necessario)...")
            
            # --- FASE 1: HANDSHAKE ---
            waiting_boot = True
            while waiting_boot:
                # Checa saída - Teclado
                if kb_hit():
                    if get_char() == b'\x1b': return # ESC

                # Checa entrada - Serial
                if ser.in_waiting:
                    line = ser.readline().decode('utf-8', errors='ignore')
                    if "BOOT" in line:
                        print(">> Bootloader detectado!")
                        waiting_boot = False
            
            # Envia Magic Word
            print("2. Enviando Magic Word...")
            ser.write(b'\xCA\xFE\xBA\xBE')
            
            ack = ser.read(1)
            if ack != b'!':
                print(f"Erro: Sem ACK (recebeu {ack}).")
                return

            # Envia Tamanho
            print(f"3. Enviando tamanho ({file_size} bytes)...")
            ser.write(struct.pack('<I', file_size))

            # --- FASE 2: UPLOAD ---
            print("4. Enviando dados...")
            CHUNK_SIZE = 32
            with open(fname, "rb") as f:
                payload = f.read()
                total_sent = 0
                for i in range(0, len(payload), CHUNK_SIZE):
                    if kb_hit() and get_char() == b'\x1b': return
                    
                    chunk = payload[i : i + CHUNK_SIZE]
                    ser.write(chunk)
                    ser.flush()
                    total_sent += len(chunk)
                    time.sleep(0.005) 
                    
                    sys.stdout.write(f"\rProgresso: {total_sent}/{len(payload)} bytes")
                    sys.stdout.flush()

            print("\nEnvio concluído. Verificando integridade...")

            # Monitora 'R' (Run) ou '.' (Check)
            while True:
                if kb_hit() and get_char() == b'\x1b': return
                
                if ser.in_waiting:
                    c = ser.read(1).decode('utf-8', errors='ignore')
                    if c == '.':
                        sys.stdout.write('.')
                        sys.stdout.flush()
                    elif c == 'R':
                        print("\n\n>> SUCESSO! Executando app...")
                        break
            
            # --- FASE 3: MONITOR SERIAL (MODO TERMINAL) ---
            print("=====================================================")
            print("   MONITOR SERIAL ATIVO - Pressione [ESC] para sair   ")
            print("=====================================================")
            
            while True:
                # 1. Dados da Serial -> Tela
                if ser.in_waiting:
                    try:
                        data = ser.read(ser.in_waiting).decode('utf-8', errors='replace')
                        print(data, end='')
                        sys.stdout.flush()
                    except: pass

                # 2. Teclado -> Sair
                if kb_hit():
                    k = get_char()
                    if k == b'\x1b': # ESC
                        print("\n[ESC] Encerrando.")
                        break
                
                time.sleep(0.01)

        except serial.SerialException as e:
            print(f"\nErro de Serial: {e}")
            print("Dica WSL: Verifique se a porta é /dev/ttyS... e se tem permissão.")
        except Exception as e:
            print(f"\nErro: {e}")
        finally:
            if ser and ser.is_open:
                ser.close()

if __name__ == "__main__":
    main()