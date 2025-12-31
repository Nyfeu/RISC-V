# ==========================================================================================
#                             CONFIGURACOES DO PROJETO
# ==========================================================================================

# Nome do Top Level
set topEntity "soc_top"

# Parte da FPGA (Digilent Nexys 4)
set targetPart "xc7a100tcsg324-1"

# Arquitetura do Core (multi_cycle)
set coreArch "multi_cycle"

# Diretorios
set outputDir ./build/fpga
file mkdir $outputDir

# ==========================================================================================
#                             PREPARACAO DO AMBIENTE
# ==========================================================================================
puts "\n--------------------------------------------------------------------------------------------------------------------------------"
puts ">>> [1/6] Configurando ambiente...\n"

# Suprime mensagens informativas padrao
set_msg_config -severity INFO -suppress
set_msg_config -severity STATUS -suppress

# ==========================================================================================
#                             LEITURA DE FONTES
# ==========================================================================================
puts "\n--------------------------------------------------------------------------------------------------------------------------------"
puts ">>> [2/6] Lendo arquivos fonte do projeto RISC-V...\n"

proc read_dir {dir pattern} {
    set files [glob -nocomplain -directory $dir $pattern]
    if {[llength $files] > 0} {
        read_vhdl $files
    }
}

# 1. Packages
read_dir "./pkg" "*.vhd"
read_dir "./rtl/core/$coreArch" "*pkg.vhd"

# 2. Core Common
read_dir "./rtl/core/common" "*.vhd"

# 3. Core Architecture
set core_files [glob -nocomplain -directory "./rtl/core/$coreArch" "*.vhd"]
foreach f $core_files {
    if {[string first "pkg.vhd" $f] == -1} {
        read_vhdl $f
    }
}

# 4. Perifericos
set perip_dirs [glob -nocomplain -type d "./rtl/perips/*"]
foreach dir $perip_dirs {
    read_dir $dir "*.vhd"
}
read_dir "./rtl/perips" "*.vhd"

# 5. SoC
read_dir "./rtl/soc" "*.vhd"

# 6. Constraints
set xdc_file "./fpga/constraints/pins.xdc" 
if {[file exists $xdc_file]} {
    puts "    + Lendo Constraints: [file tail $xdc_file]"
    read_xdc $xdc_file
} else {
    puts "!!! ERRO: Arquivo de constraints nao encontrado: $xdc_file"
    exit 1
}

# ==========================================================================================
#                             SINTESE
# ==========================================================================================
puts "\n--------------------------------------------------------------------------------------------------------------------------------"
puts ">>> [3/6] Executando Sintese do Projeto...\n"

if {[catch {
    synth_design -top $topEntity -part $targetPart -flatten_hierarchy rebuilt -retiming -quiet
} err]} {
    puts "\n!!! FALHA NA SINTESE !!!"
    puts "$err"
    exit 1
}

write_checkpoint -force $outputDir/post_synth.dcp
report_utilization -file $outputDir/utilization_synth.rpt
report_timing_summary -file $outputDir/timing_summary.rpt

# ==========================================================================================
#                             IMPLEMENTACAO
# ==========================================================================================
puts "\n--------------------------------------------------------------------------------------------------------------------------------"
puts ">>> [4/6] Opt, Place & Route...\n"

if {[catch {
    opt_design -quiet
    place_design -quiet
    route_design -quiet
} err]} {
    puts "\n!!! FALHA NA IMPLEMENTACAO !!!"
    puts "$err"
    exit 1
}

write_checkpoint -force $outputDir/post_route.dcp
report_utilization -file $outputDir/utilization_route.rpt

# ==========================================================================================
#                             BITSTREAM
# ==========================================================================================
puts "\n--------------------------------------------------------------------------------------------------------------------------------"
puts ">>> [5/6] Gerando Bitstream...\n"

write_bitstream -force $outputDir/${topEntity}.bit

puts " "
puts "================================================================"
puts "   SUCESSO! Bitstream gerado:"
puts "   $outputDir/${topEntity}.bit"
puts "================================================================"

# ==========================================================================================
#                             PROGRAMACAO
# ==========================================================================================
puts "\n--------------------------------------------------------------------------------------------------------------------------------"
puts ">>> [6/6] Tentando programar a placa...\n"

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
    puts "   -> Placa programada com sucesso!"
} err]} {
    puts "   -> Aviso: Programacao automatica falhou (Placa desconectada?)"
    puts "      O bitstream esta pronto para uso manual."
}

puts "\n--------------------------------------------------------------------------------------------------------------------------------"

exit