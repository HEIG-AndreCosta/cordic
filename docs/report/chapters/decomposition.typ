= Decomposition

Le problème est bien décrit, nous avons 3 étapes principales :

#image("../media/schema_bloc.png")

Notons l'importance de faire passer le quadrant d'origine et un flag pour savoir si les valeurs ont été échangés par le bloc de calcul.
Ceci est important car pour les étapes de version séquentiel et pipeline, il faut garantir que ces signaux arrivent au bon moment au bloc de post-traitement final.
