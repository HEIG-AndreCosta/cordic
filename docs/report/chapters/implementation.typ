= Implémentation du calculateur CORDIC

== Architecture générale

L'implémentation du calculateur CORDIC a été décomposée en trois composants principaux afin de faciliter la réutilisation entre les différentes architectures et d'améliorer la lisibilité du code :

- *Composant de prétraitement* (`cordic_pre_treatment`) : Réalise la première étape de l'algorithme CORDIC en projetant les coordonnées dans le premier octant.
- *Composant d'itération* (`cordic_iteration`) : Effectue une itération de l'algorithme CORDIC selon les formules définies dans le cahier des charges.
- *Composant de post-traitement* (`cordic_post_treatment`) : Applique les corrections nécessaires pour obtenir la phase correcte en fonction du quadrant d'origine et extrait l'amplitude du vecteur.

Cette décomposition modulaire permet d'implémenter les trois architectures demandées (combinatoire, pipeline, séquentielle) en réutilisant ces blocs de base et en modifiant uniquement la manière dont ils sont connectés et synchronisés.

#image("../media/schema_bloc.png")

== Architecture combinatoire

=== Schéma bloc

#image("../media/cordic-combinatoire.svg")

=== Principe de fonctionnement

L'architecture combinatoire instancie les composants de manière purement combinatoire, sans registres entre les étapes de calcul. Elle est caractérisée par :

- Un bloc de prétraitement
- 10 blocs d'itération CORDIC connectés en série
- Un bloc de post-traitement

=== Caractéristiques

- *Avantages* : Latence minimale (le résultat est disponible immédiatement après l'application des entrées).
- *Inconvénients* : Chemin critique très long traversant tous les composants, limitant significativement la fréquence maximale de fonctionnement.

=== Fréquence Maximale 

Pour cette architecture, il n'est pas possible de calculer la fréquence maximale, dû au fait qu'il n'y a pas de registres pour dans le système synthétisé.
Cependant nous pouvons en déduire de la fréquence maximale de l'architecture pipeliné (voir ci-dessus).

L'architecture pipeliné tourne à `304,4MHz` ce qui implique un temps de propagation maximale de:

$ 1 /(304 * 10^6) = 3"ns" $

Si l'on considère que chaque bloc est équivalent, nous pouvons en déduire que le temps de propagation de notre système sera de 

$ 12 * 1 / (304 * 10^6) = 39"ns" $

et donc, notre bloc limiterait la fréquence maximale dans un système plus complet à 

$ 1 / (12 * 1 / (304 * 10^6)) = 25.6 "MHz" $

Note: Le 12 dans notre calcul prend en compte les 10 blocs itération et les 2 blocs pré et post traitement.

== Architecture pipeline

=== Schéma bloc

#image("../media/cordic-pipeline.svg")

=== Principe de fonctionnement
L'architecture pipeline insère des registres entre chaque étape de calcul pour découper le chemin critique en segments plus courts. Elle comprend :

- Un bloc de prétraitement suivi d'un registre
- 10 blocs d'itération CORDIC, chacun suivi d'un registre
- Un bloc de post-traitement
- Une gestion du flux de données avec des signaux de contrôle permettant de stopper le pipeline si nécessaire

Le schéma bloc de cette architecture est très similaire à l'architecture combinatoire.
En effet, nous ajoutons des registres entre chaque étape pour garantir le plus petit temps de propagation possible.
La partie la plus compliqué est de gérer correctement l'arrêt de la pipeline, pour cela, notre implémentation permet aux données d'arriver à la dernière étape 
avant de s'arrêter au cas où le composant qui vient après n'est pas prêt.

=== Caractéristiques
- *Avantages* : Fréquence de fonctionnement élevée, débit maximal (un résultat par cycle d'horloge en régime permanent).
- *Inconvénients* : Latence importante (12 cycles entre l'entrée et la sortie), consommation de ressources plus élevée pour les registres.
- *Fréquence maximale* : 304.4 MHz - Compilation avec Quartus pour la carte DE1-SoC - modèle Slow 1100mV 85C

== Architecture séquentielle

=== Schéma bloc

#image("../media/cordic-sequentiel.svg")

=== Principe de fonctionnement
L'architecture séquentielle utilise une machine à états finis pour contrôler la réutilisation d'un seul bloc d'itération. Elle est composée de :

- Un bloc de prétraitement
- Un seul bloc d'itération CORDIC utilisé séquentiellement 10 fois
- Un bloc de post-traitement
- Une machine à états finis qui gère le séquencement des étapes

Les états principaux de la machine à états sont :
- `IDLE` : Attente d'une nouvelle entrée
- `ITERATION` : Exécution séquentielle des 10 itérations CORDIC
- `POST_TREATMENT` : Application du post-traitement
- `VALID` : Signalement que le résultat est valide

Même pour cette architecture, nous pouvons utiliser les mêmes blocs utilisées auparavant. Ceci montre l'élégance de la décomposition effectué au début 
de l'implémentation.

=== Caractéristiques
- *Avantages* : Utilisation minimale de ressources, particulièrement adapté pour les applications où la surface est critique.
- *Inconvénients* : Débit limité (un résultat tous les 12 cycles d'horloge), latence moyenne (12 cycles).
- *Fréquence maximale* : 195.85 MHz - Compilation avec Quartus pour la carte DE1-SoC - modèle Slow 1100mV 85C

== Comparaison des performances

Le tableau suivant présente une comparaison des performances des trois architectures implémentées :
#table(
  columns: (auto, auto, auto, auto, auto),
  inset: 10pt,
  align: horizon,
  table.header(
    [Architecture], [Fréquence maximale], [Latence (cycles)], [Débit max (résultats/cycle)], [Utilisation de ressources]
  ),
    [ Combinatoire ], [25.2 MHz  ], [1 ], [1   ], [Faible  ],
    [ Pipeline     ], [304.4 MHz ], [12], [1   ], [Élevée  ],
    [ Séquentielle ], [195.85 MHz ], [12], [1/12], [Minimale],
)

== Conclusion implémentation

Les trois architectures implémentées pour le calculateur CORDIC offrent différents compromis entre fréquence de fonctionnement, latence, débit et utilisation des ressources. Le choix de l'architecture dépend donc des contraintes spécifiques de l'application :

- L'architecture *combinatoire* est adaptée aux applications nécessitant une latence minimale sans contrainte forte sur la fréquence.
- L'architecture *pipeline* convient parfaitement aux applications à haut débit requérant une fréquence de fonctionnement élevée.
- L'architecture *séquentielle* est idéale pour les applications où les ressources matérielles sont limitées et où le débit n'est pas critique.

La modularité de notre implémentation facilite le passage d'une architecture à l'autre, ce qui permet d'adapter facilement le calculateur CORDIC aux besoins spécifiques de différentes applications.
