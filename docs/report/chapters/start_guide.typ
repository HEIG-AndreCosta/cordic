= Guide de démarrage rapide

Voici comment lancer les différents tests:

```bash
mkdir -p code/sim
cd code/sim

# Lancer les tests pour chaque architecture
# NOTE: Pressez sur NO quand le test actuel fini pour lancer la prochaine architecture
vsim -do "do ../scripts/sim.do all"

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

