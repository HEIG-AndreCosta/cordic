# SCF - Labo 8 - Calculateur CORDIC

## Simulation

```bash
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

# Bloc de pré-traitement
vsim -do "do ../scripts/sim_bloc.do pre_test"

# Bloc de cordic itération
vsim -do "do ../scripts/sim_bloc.do cordic_iteration_test"

# Bloc de post-traitement
vsim -do "do ../scripts/sim_bloc.do post_test"
```

## Doc info

Nous utilisons typst pour générer la documentation en pdf.
### Installation de typst

Sources: https://github.com/typst/typst

### ubuntu / linux snap
sudo snap install typst

### Windows 
winget install --id Typst.Typst

### Utilisation de typst

#### Watches source files and recompiles on changes:
typst watch ./docs/report/report.typ

