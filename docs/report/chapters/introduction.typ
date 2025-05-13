= Introduction

Le traitement numérique du signal requiert fréquemment des transformations entre différentes représentations de données, notamment entre les coordonnées cartésiennes et polaires.
Dans les systèmes numériques embarqués, où les ressources de calcul sont souvent limitées, l'implémentation efficace de fonctions trigonométriques devient un défi majeur.
L'algorithme CORDIC (COordinate Rotation DIgital Computer) offre une solution élégante à ce problème en permettant d'effectuer ces calculs complexes sans recourir à des multiplicateurs
dédiés ou à des tables de correspondance volumineuses.

Ce rapport présente la conception, l'implémentation et la vérification d'un calculateur CORDIC fonctionnant en mode "vectoring" pour transformer des coordonnées cartésiennes (re, im)
en coordonnées polaires (amplitude, phase). Trois architectures distinctes ont été explorées : combinatoire, pipeline et séquentielle, chacune offrant un compromis différent entre latence,
débit, fréquence maximale de fonctionnement et utilisation des ressources matérielles.
