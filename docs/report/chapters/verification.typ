= CORDIC Vérification - UVM
== introduction
La conception du testbench de ce laboratoire devait normalement se faire de manière simple, c'est à dire que l'on devait tout simplement concevoir un module simple testant tous les cas possible du CORDIC avec tout simplement 4 entrée et 4 sorties, mais suite à la conception du système nous nous somme retrouvés avec 3 bloc qui complétaient le module complet de CORDIC, un bloc de pré-traitement, un bloc de calcul pour CORDIC et un bloc de post-traitement. De ce fait afin de se familiariser un peu avec la réalisation d'un testbench réel, un UVM a été réalisé en s'inspirant de la documentation officiel de ce #link("https://www.chipverify.com/tutorials/uvm")[lien].

== Schéma du testbench
=== pré-traitement
#image("../media/pre_env.png")

=== cordic-itération-traitement
#image("../media/cordic_iteration_env.png")

=== post-traitement
#image("../media/post_env.png")

== Choix de conception
Théoriquement afin d'avoir un UVM complet il aurais fallu regrouper chacun des environnements dans un seul grand environnement afin de tester le système complet, cela aurait permis de récupérer les valeurs de chacun des bloc durant tout le processus. Cela utiliserais le même princpipe que le schéma ci-dessous:
#image("../media/vseqr.png")
Malheureusement n'ayant pas le temps de le réaliser et comprendre ce type de système, la partie vérifiant le système complet à été réaliser dans un autres fichier à l'extérieur de l'UVM, n'utilisant aucun des concept de ce dernier.

== Stimulus et contrainte
Afin de réaliser 100% des cas possible sur les différents bloc chacun des bloc se retrouve avec son coverage ainsi que ces contraintes, cela nous permet d'être certain du bon fonctionnement de chaque bloc.

=== pré-traitement
La fonctionnalité principale du pré-traitement est tout simplement de ramener les cordonnée cartesienne vers le premier octant (total de 8 octants), donc afin de vérifier cela le sequencer génère une centaine de valeur aléatoire ce qui garanti de tester la majorité des cas. Afin de savoir si tout les octant on bien été couvers une variable nommé octant à été ajouté afin de vérifier à l'aide d'un coverage que chacun des octants a été testé. 

Contraintes:

Afin d'assurer le bon fonctionnement de la randomisation voici les contrainte utilisée:
- range: défini les valeurs min et max que peuvent prendre re et im
- my_octant: défini quels valeurs appartient à quel octant

Coverage: 

Le coverage all_octant vérifie tout simplement que tout les octants ont été testé.

=== cordic-itération-traitement
Pour cette partie l'objectif principal est de vérifier que le calcul est correct pour chaque itération possible, donc entre 1 et 10.

Contraintes:

voici les contraintes utilisée:
- range: défini les valeurs min et max que peuvent prendre re, im, phi et iter
- re_bigger_im: s'il s'agit de la première itération alors re dois être plus grand ou égal à im

Coverage:

Le coverage cordic_iteration_cg vérifie tout simplement que toutes les itérations ont été testé.

=== post-traitement
Afin d'assurer un bon fonctionnement de ce bloc il nous faut vérifier que pour chaque quadrant et chaque changement de signal que le calcul soit fait correctement. 

Contraintes:

Voici donc la contrainte utilisée:
- range: défini les valeurs min et max que peuvent prendre re, im et phi

Coverages:

Le coverage post_cg vérifie que chaque quadrant ont été testé avec des changement de signal ou non (cross).

== Scoreboard
Chacun des scoreboards reçois les transactions du driver et du moniteur au travers d'une FIFO, voici à quoi ressemble les envoies au scoreboard:

monitor/driver → analysis_port → FIFO → scoreboard

une fois les valeurs reçu le scoreboard calcule en premier lieu le résultat à obtenir avec les valeurs d'entrée puis les compare aux valeur reçu du DUT.

== Test
Chacun des blocs n'ayant pas énormément de combinaison possible, afin d'être certain que chacun fonctionne individuellement une 100 de valeurs random différentes ont été testé sur chacun des bloc.

Chacun des tests peut être lancé individuellement à l'aide des commandes suivante:
- vsim -do "do ../scripts/sim_bloc.do pre_test" => Lance les tests du bloc de pré-traitement
- vsim -do "do ../scripts/sim_bloc.do cordic_iteration_test" => Lance les tests du bloc cordic-itération-traitement
- vsim -do "do ../scripts/sim_bloc.do post_test" => Lance les tests du bloc post-traitement
- vsim -do "do ../scripts/sim_bloc.do all" => Lance les tests de tout les blocs

En cas de problème avec un chemin de fichier, n'hésitez pas à modifier les PATH dans le fichier de simulation.

Si vous souhaitez voir plus en détail les valeurs testée décomenté les _uvm_info_ dans les scoreboards et les séquences.


== Résultat
=== pré-traitement
```c
# ************  PRE  SUMMARY  ************
#  Number of Transactions : 100
#  Total Coverage         : 100.00 %
#  Test Passed            : 100
#  Test Failed            : 0
# ****************************************
```
=== cordic-itération-traitement
```c
# ************  ITERATION  SUMMARY  *******
#  Number of Transactions : 100
#  Total Coverage         : 100.00 %
#  Test Passed            : 100
#  Test Failed            : 0
# *****************************************
```
=== post-traitement
```c
# ************  POST  SUMMARY  ************
#  Number of Transactions : 100
#  Total Coverage         : 100.00 %
#  Test Passed            : 100
#  Test Failed            : 0
# *****************************************
```


