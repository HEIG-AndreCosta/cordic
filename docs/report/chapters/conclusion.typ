= Conclusion

Ce projet de calculateur CORDIC a permis d'explorer différentes stratégies d'implémentation matérielle d'un algorithme mathématique complexe sur FPGA.
L'approche modulaire adoptée, divisant le traitement en trois étapes distinctes (prétraitement, itérations CORDIC et post-traitement), s'est révélée particulièrement
efficace pour faciliter le développement et la réutilisation du code à travers les trois architectures proposées.

Les résultats obtenus mettent en évidence les compromis inhérents à chaque architecture :

- L'architecture combinatoire offre une latence minimale (1 cycle) mais une fréquence de fonctionnement limitée à environ 25,2 MHz en raison de son long chemin critique.
- L'architecture pipeline atteint la fréquence la plus élevée (304,4 MHz) avec un débit maximal d'un résultat par cycle, au prix d'une latence de 12 cycles et d'une consommation de ressources plus importante.
- L'architecture séquentielle présente une utilisation minimale de ressources tout en maintenant une fréquence respectable de 195,85 MHz, mais son débit est limité à un résultat tous les 12 cycles.

La vérification du système a été réalisée à l'aide d'une méthodologie UVM (Universal Verification Methodology), permettant de tester indépendamment chaque composant et
d'atteindre une couverture de test de 100% pour toutes les fonctionnalités. Cette approche rigoureuse a confirmé le bon fonctionnement du système dans toutes les configurations possibles.
Nous avons également noté une divergence entre les résultats théoriques et ceux calculés par notre implémentation. Cette différence s'explique par les approximations inhérentes à l'algorithme CORDIC,
notamment lors des divisions par décalage arithmétique. Cette observation souligne l'importance d'adapter les méthodes de vérification à la nature de l'algorithme plutôt que de se
fier uniquement aux valeurs théoriques idéales.

En conclusion, ce projet illustre la puissance de l'algorithme CORDIC pour implémenter efficacement des fonctions mathématiques complexes sur FPGA,
tout en démontrant l'impact des choix architecturaux sur les performances du système. La méthodologie de conception et de vérification employée offre un cadre robuste pour le développement
de systèmes numériques complexes, adaptable à diverses contraintes de conception.
