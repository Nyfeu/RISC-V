# ==========================================================================================
#                             CONFIGURAÇÕES DO PROJETO
# ==========================================================================================

# Nome do Top Level (Sua entidade principal)
set topEntity "soc_top"

# Parte da FPGA (Nexys 4 DDR / A7-100T)
set targetPart "xc7a100tcsg324-1"

# Arquitetura do Core a ser usada (single_cycle ou multi_cycle)
set coreArch "multi_cycle"

# Diretórios de Saída
set outputDir ./build/fpga_bitstream
file mkdir $outputDir

# ==========================================================================================
#                             REDUÇÃO DE RUÍDO (SILENCE!)
# ==========================================================================================
puts ">>> [1/6] Configurando ambiente e silenciando logs..."

# Suprime mensagens informativas inúteis do Vivado
set_msg_config -severity INFO -suppress
set_msg_config -severity STATUS -suppress
# Mostra warnings, mas limita a 10 para não poluir
set_msg_config -severity WARNING -limit 10

# ==========================================================================================
#                             LEITURA DE FONTES (AUTO-DISCOVERY)
# ==========================================================================================
puts ">>> [2/6] Lendo repositório RISC-V..."

# Função auxiliar para ler VHDL de um diretório
proc read_dir {dir pattern} {
    set files [glob -nocomplain -directory $dir $pattern]
    foreach f $files {
        # puts "    + Lendo: [file tail $f]" ;# Descomente para ver cada arquivo
        read_vhdl $f
    }
}

# 1. Packages (Devem vir primeiro!)
# -------------------------------------------------------
read_dir "./pkg" "*.vhd"
# O pacote da microarquitetura fica dentro da pasta do core específico
read_dir "./rtl/core/$coreArch" "*pkg.vhd"

# 2. Core Common (ALU, RegFile, etc)
# -------------------------------------------------------
read_dir "./rtl/core/common" "*.vhd"

# 3. Core Architecture (Datapath, Control do single ou multi)
# -------------------------------------------------------
# Lemos tudo que NÃO for pkg (já lido acima)
set core_files [glob -nocomplain -directory "./rtl/core/$coreArch" "*.vhd"]
foreach f $core_files {
    if {[string first "pkg.vhd" $f] == -1} {
        read_vhdl $f
    }
}

# 4. Periféricos (UART, GPIO, etc)
# -------------------------------------------------------
# Varre subpastas dentro de rtl/perips
set perip_dirs [glob -nocomplain -type d "./rtl/perips/*"]
foreach dir $perip_dirs {
    read_dir $dir "*.vhd"
}
# Se tiver arquivos soltos na raiz de perips
read_dir "./rtl/perips" "*.vhd"

# 5. SoC (Bus, Top Level, RAM, ROM)
# -------------------------------------------------------
read_dir "./rtl/soc" "*.vhd"

# 6. Constraints (.xdc)
# -------------------------------------------------------
# Aponta para o seu arquivo de pinos atualizado
set xdc_file "./fpga/constraints/pins.xdc" 

if {[file exists $xdc_file]} {
    read_xdc $xdc_file
} else {
    puts "❌ ERRO CRÍTICO: Arquivo de constraints não encontrado: $xdc_file"
    exit 1
}

# ==========================================================================================
#                             SÍNTESE
# ==========================================================================================
puts ">>> [3/6] Executando Síntese (Aguarde)..."

# O comando 'catch' captura erros para não explodir o script sem aviso
if {[catch {
    # -quiet: Remove o lixo do terminal
    # -flatten_hierarchy rebuilt: Otimização boa para FPGAs Xilinx
    synth_design -top $topEntity -part $targetPart -flatten_hierarchy rebuilt -retiming -quiet
} err]} {
    puts " "
    puts "❌ FALHA NA SÍNTESE!"
    puts "-----------------------------------------------------------"
    puts $err
    puts "-----------------------------------------------------------"
    exit 1
}

# Salva checkpoint e relatório
write_checkpoint -force $outputDir/post_synth.dcp
report_utilization -file $outputDir/utilization_synth.rpt

# ==========================================================================================
#                             IMPLEMENTAÇÃO (PLACE & ROUTE)
# ==========================================================================================
puts ">>> [4/6] Otimização, Place e Route..."

if {[catch {
    opt_design -quiet
    place_design -quiet
    route_design -quiet
} err]} {
    puts "❌ FALHA NA IMPLEMENTAÇÃO!"
    puts $err
    exit 1
}

write_checkpoint -force $outputDir/post_route.dcp
report_utilization -file $outputDir/utilization_route.rpt
# Checagem básica de timing (opcional, mas bom ter)
report_timing_summary -file $outputDir/timing_summary.rpt

# ==========================================================================================
#                             BITSTREAM
# ==========================================================================================
puts ">>> [5/6] Gerando Bitstream..."

write_bitstream -force $outputDir/${topEntity}.bit

puts " "
puts "============================================================"
puts "✅ SUCESSO! Bitstream gerado em:"
puts "   $outputDir/${topEntity}.bit"
puts "============================================================"

# ==========================================================================================
#                             PROGRAMAÇÃO (OPCIONAL)
# ==========================================================================================
puts ">>> [6/6] Tentando programar a placa..."

if {[catch {
    open_hw_manager
    connect_hw_server
    open_hw_target
    current_hw_device [lindex [get_hw_devices] 0]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
    
    set_property PROGRAM.FILE "$outputDir/${topEntity}.bit" [lindex [get_hw_devices] 0]
    program_hw_devices [lindex [get_hw_devices] 0]
    
    close_hw_target
    close_hw_manager
    puts ">>> 🔌 Placa programada com sucesso!"
} err]} {
    puts ">>> ⚠️ Aviso: Não foi possível programar a placa automaticamente."
    puts "       (Provavelmente a placa não está conectada ou driver ocupado)"
    puts "       Bitstream está pronto para gravação manual."
}

exit