# SCF - Labo 8 - Calculateur CORDIC

## Simulation
´´´bash
# 1. Naviguer vers le répertoire sim
cd ~/cordic/code/sim

# 2. Lancer ModelSim/QuestaSim
vsim

# 3. Exécuter le script
do ../scripts/sim.do

# Architecture combinatoire (par défaut)
vsim -do "do ../scripts/sim.do comb 0"

# Architecture pipeline
vsim -do "do ../scripts/sim.do pipeline 1"

# Architecture séquentielle
vsim -do "do ../scripts/sim.do sequential 2"

# Toutes les architectures
vsim -do "do ../scripts/sim.do all"

´´´

## Doc info
### Installation de typst

Sources: https://github.com/typst/typst

### ubuntu / linux snap
sudo snap install typst

### Windows 
winget install --id Typst.Typst

### Utilisation de typst

#### Watches source files and recompiles on changes.
typst watch ./docs/report/report.typ

