# =============================================================================
#  Script de Build para FPGA (VIVADO)
# =============================================================================

# Define os caminhos
$LogDir = "build\fpga"
$ScriptTcl = "fpga\scripts\build.tcl"

# 1. Cria a pasta de logs se ela não existir
if (-not (Test-Path -Path $LogDir)) {
    Write-Host ">>> Criando diretorio: $LogDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
}

# 2. Executa o Vivado
#    -mode batch : Não abre interface gráfica
#    -notrace    : Reduz o lixo no log
#    -log        : Redireciona o vivado.log
#    -journal    : Redireciona o vivado.jou
#    -source     : Executa o script TCL

Write-Host ">>> Iniciando Vivado..." -ForegroundColor Green
Write-Host "    Logs serao salvos em: $LogDir" -ForegroundColor Gray

vivado -mode batch -notrace `
       -log "$LogDir\vivado.log" `
       -journal "$LogDir\vivado.jou" `
       -source $ScriptTcl

mv clockInfo.txt build\fpga -Force
rm .Xil
rm "build/fpga/*backup*"

# 3. Verifica o status de saída
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n>>> Build finalizado com SUCESSO!" -ForegroundColor Green
} else {
    Write-Host "`n>>> Ocorreu um ERRO durante o build." -ForegroundColor Red
}