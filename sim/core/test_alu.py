import cocotb
from cocotb.triggers import Timer
import random
import logging

# ==============================================================================
# 1. CONFIGURAÇÃO DE LOGGING E VISUAL (A Mágica acontece aqui)
# ==============================================================================

# Suprime logs irrelevantes do GHDL/GPI (Remove o warning "vpi_iterate")
logging.getLogger("gpi").setLevel(logging.ERROR)

class Colors:
    """Códigos ANSI para colorir o terminal"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def log_header(msg):
    cocotb.log.info(f"{Colors.HEADER}{Colors.BOLD}>>> {msg}{Colors.ENDC}")

def log_success(msg):
    cocotb.log.info(f"{Colors.GREEN}✔ {msg}{Colors.ENDC}")

# ==============================================================================
# 2. CONSTANTES (Espelho do riscv_pkg.vhd)
# ==============================================================================
# Certifique-se que estes valores batem com seu VHDL!
ALU_ADD  = 0b0000 
ALU_SUB  = 0b1000 
ALU_SLL  = 0b0001 
ALU_SLT  = 0b0010 
ALU_SLTU = 0b0011 
ALU_XOR  = 0b0100 
ALU_SRL  = 0b0101 
ALU_SRA  = 0b1101 
ALU_OR   = 0b0110 
ALU_AND  = 0b0111 

# ==============================================================================
# 3. GOLDEN MODEL (Referência em Python)
# ==============================================================================

def to_signed(val, bits=32):
    val = val & ((1 << bits) - 1)
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def to_unsigned(val, bits=32):
    return val & ((1 << bits) - 1)

def model_alu(opcode, a, b):
    a_s, b_s = to_signed(a), to_signed(b)
    a_u, b_u = to_unsigned(a), to_unsigned(b)
    shamt = b_u & 0x1F

    res = 0
    if opcode == ALU_ADD:   res = a_u + b_u
    elif opcode == ALU_SUB: res = a_u - b_u
    elif opcode == ALU_AND: res = a_u & b_u
    elif opcode == ALU_OR:  res = a_u | b_u
    elif opcode == ALU_XOR: res = a_u ^ b_u
    elif opcode == ALU_SLL: res = a_u << shamt
    elif opcode == ALU_SRL: res = a_u >> shamt
    elif opcode == ALU_SRA: res = a_s >> shamt
    elif opcode == ALU_SLT: res = 1 if a_s < b_s else 0
    elif opcode == ALU_SLTU:res = 1 if a_u < b_u else 0
    
    res_masked = to_unsigned(res)
    is_zero = 1 if res_masked == 0 else 0
    return res_masked, is_zero

async def settle():
    await Timer(1, unit="ns")

# ==============================================================================
# 4. TESTES
# ==============================================================================

@cocotb.test()
async def test_basic_ops(dut):
    log_header("Iniciando Teste Básico (ADD/SUB)")
    
    # ADD
    dut.ALUControl_i.value = ALU_ADD
    dut.A_i.value, dut.B_i.value = 10, 32
    await settle()
    
    assert int(dut.Result_o.value) == 42, "ADD Falhou"
    assert dut.Zero_o.value == 0
    log_success("ADD OK")

    # SUB (Zero Flag Check)
    dut.ALUControl_i.value = ALU_SUB
    dut.A_i.value, dut.B_i.value = 10, 10
    await settle()
    
    assert int(dut.Result_o.value) == 0, "SUB Falhou"
    assert dut.Zero_o.value == 1
    log_success("SUB & Zero Flag OK")

@cocotb.test()
async def test_shifts(dut):
    log_header("Iniciando Teste de Shifts (SLL, SRL, SRA)")
    val_neg, shift = 0xFFFFFFF0, 4

    for op, name in [(ALU_SRA, "SRA"), (ALU_SRL, "SRL"), (ALU_SLL, "SLL")]:
        dut.ALUControl_i.value = op
        dut.A_i.value, dut.B_i.value = val_neg, shift
        await settle()
        
        expected, _ = model_alu(op, val_neg, shift)
        got = int(dut.Result_o.value)
        assert got == expected, f"{name} Falhou. Esp: {hex(expected)} Obt: {hex(got)}"
        log_success(f"{name} OK")

@cocotb.test()
async def test_slt_logic(dut):
    log_header("Iniciando Teste de Comparações (SLT/SLTU)")
    
    # SLT (Signed)
    dut.ALUControl_i.value = ALU_SLT
    dut.A_i.value, dut.B_i.value = 0xFFFFFFFF, 1 # -1 < 1
    await settle()
    assert int(dut.Result_o.value) == 1
    log_success("SLT (Signed) OK")

    # SLTU (Unsigned)
    dut.ALUControl_i.value = ALU_SLTU
    dut.A_i.value, dut.B_i.value = 0xFFFFFFFF, 1 # MAX > 1
    await settle()
    assert int(dut.Result_o.value) == 0
    log_success("SLTU (Unsigned) OK")

@cocotb.test()
async def test_randomized(dut):
    log_header("Iniciando Teste de Estresse Randômico (1000 iterações)")
    
    ops = [ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU]
    
    for i in range(1000):
        op = random.choice(ops)
        a, b = random.getrandbits(32), random.getrandbits(32)

        dut.ALUControl_i.value = op
        dut.A_i.value, dut.B_i.value = a, b
        await settle()

        expected_res, expected_zero = model_alu(op, a, b)
        
        # Check Rápido para performance
        if int(dut.Result_o.value) != expected_res or int(dut.Zero_o.value) != expected_zero:
             msg = f"\n{Colors.FAIL}FALHA na iteração {i}{Colors.ENDC}\nOp: {bin(op)}\nA: {hex(a)}\nB: {hex(b)}"
             assert int(dut.Result_o.value) == expected_res, f"{msg} -> Res Errado"
             assert int(dut.Zero_o.value) == expected_zero, f"{msg} -> Zero Errado"

    log_success(f"1000 Vetores Aleatórios Verificados com Sucesso")