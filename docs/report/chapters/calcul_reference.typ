= Calcul de référence

Calcul des 10 itérations CORDIC pour re=1000, im=500.

== Étape 1 : Prétraitement
- Calcul de la valeur absolue de re et im. Ceci projette les coordonnées dans le premier quadrant.
- Comparaison entre re et im. Si im > re alors leurs valeurs sont échangées. Ceci projette les coordonnées dans le premier octant.
  - Coordonnées initiales : re=1000, im=500
  - Les deux sont positifs → premier quadrant (original_quadrant_id = "00")
  - Valeurs absolues : re=1000, im=500 (pas de changement car déjà positifs)
  - im < re → pas d'échange : re=1000, im=500, signals_exchanged=0

== Étape 2 : Itérations CORDIC
Les constantes alpha_const sont fournies dans le package (cordic_pkg.vhd) :
- $alpha_1$ = 302 (= 00100101110 en binaire)
- $alpha_2$ = 160 (= 00010100000)
- $alpha_3$ = 81  (= 00001010001)
- $alpha_4$ = 41  (= 00000101001)
- $alpha_5$ = 20  (= 00000010100)
- $alpha_6$ = 10  (= 00000001010)
- $alpha_7$ = 5   (= 00000000101)
- $alpha_8$ = 3   (= 00000000011)
- $alpha_9$ = 1   (= 00000000001)
- $alpha_10$ = 1  (= 00000000001)

=== Explication sur les shifts arithmétiques vs division entière

Dans l'implémentation matérielle du CORDIC, les divisions par puissances de 2 sont réalisées par des décalages binaires (shifts). Il est important de comprendre la différence entre une division entière classique et un décalage arithmétique, particulièrement pour les nombres négatifs :

- *Division entière* : Lorsqu'on calcule manuellement, on obtient par exemple -156 / 16 = -9,75, qui est tronqué à -9 (arrondi vers zéro)
- *Décalage arithmétique à droite (-156 >> 4)* : Le décalage préserve le bit de signe et arrondit vers le bas (vers -∞), donnant -10 en complément à deux

Cette différence peut expliquer les écarts entre un calcul manuel théorique en utilisant la division entière et l'implémentation matérielle réelle.
Afin de vérifier notre implémentation matérielle, nous avons vérifié les calcules à l'aide de shift.

=== Calculs des itérations

À chaque itération, les calculs suivants sont effectués selon le signe de im :

- Si la partie imaginaire à l'itération i est négative :
  - $"re"_{i+1} = "re"_i - "im"_i/2^i$ (où la division est un décalage arithmétique)
  - $"im"_{i+1} = "im"_i + "re"_i/2^i$
  - $phi_{i+1} = phi_i - "alpha_const"_i$
- Si la partie imaginaire à l'itération i est positive :
  - $"re"_{i+1} = "re"_i + "im"_i/2^i$
  - $"im"_{i+1} = "im"_i - "re"_i/2^i$
  - $phi_{i+1} = phi_i + "alpha_const"_i$

Le tableau jusqu'à 10 itérations (avec décalages arithmétiques) :

#table(
  columns: 10,
  stroke: 0.5pt,
  [*Iter*], [*re_i*], [*im_i*], [*phi_i*], [*im < 0 ?*], [*im_i>>i*], [*re_i>>i*], [*re_i+1*], [*im_i+1*], [*phi_i+1*],
  [Init], [1000], [500], [0], [-], [-], [-], [-], [-], [-],
  [1], [1000], [500], [0], [NON], [250], [500], [1250], [0], [302],
  [2], [1250], [0], [302], [NON], [0], [312], [1250], [-312], [462],
  [3], [1250], [-312], [462], [OUI], [-39], [156], [1289], [-156], [381],
  [4], [1289], [-156], [381], [OUI], [-10], [80], [1299], [-76], [340],
  [5], [1299], [-76], [340], [OUI], [-3], [40], [1302], [-36], [320],
  [6], [1302], [-36], [320], [OUI], [-1], [20], [1303], [-16], [310],
  [7], [1303], [-16], [310], [OUI], [-1], [10], [1304], [-6], [305],
  [8], [1304], [-6], [305], [OUI], [-1], [5], [1305], [-1], [302],
  [9], [1305], [-1], [302], [OUI], [-1], [2], [1306], [1], [301],
  [10], [1306], [1], [301], [NON], [0], [1], [1306], [0], [302],
)

Détails des calculs (avec décalages arithmétiques pour les nombres négatifs) :
- Itération 1 : $"im"_i>>1$ = 500>>1 = 250, $"re"_i>>1$ = 1000>>1 = 500
- Itération 2 : $"im"_i>>2$ = 0>>2 = 0, $"re"_i>>2$ = 1250>>2 = 312
- Itération 3 : $"im"_i>>3$ = (-312)>>3 = -39, $"re"_i>>3$ = 1250>>3 = 156
- Itération 4 : $"im"_i>>4$ = (-156)>>4 = -10, $"re"_i>>4$ = 1289>>4 = 80
- Itération 5 : $"im"_i>>5$ = (-76)>>5 = -3, $"re"_i>>5$ = 1299>>5 = 40
- Itération 6 : $"im"_i>>6$ = (-36)>>6 = -1, $"re"_i>>6$ = 1302>>6 = 20
- Itération 7 : $"im"_i>>7$ = (-16)>>7 = -1, $"re"_i>>7$ = 1303>>7 = 10
- Itération 8 : $"im"_i>>8$ = (-6)>>8 = -1, $"re"_i>>8$ = 1304>>8 = 5
- Itération 9 : $"im"_i>>9$ = (-1)>>9 = -1, $"re"_i>>9$ = 1305>>9 = 2
- Itération 10 : $"im"_i>>10$ = 1>>10 = 0, $"re"_i>>10$ = 1306>>10 = 1

À la fin des 10 itérations :
- re final = 1306
- im final = 0
- phi final = 302

== Étape 3 : Projection de l'angle sur les 4 quadrants

Rappel des valeurs après les itérations :
- phi après itérations = 302
- signals_exchanged = 0 (pas d'échange lors du prétraitement)
- original_quadrant_id = "00" (premier quadrant)

=== Projection sur le premier quadrant :

- PI   = $2^(11-1)$ = $2^10$ = 1024 (d'après la constante pidiv1_c dans le package)
- PI/2 = $2^(11-2)$ = $2^9$  =  512 (d'après la constante pidiv2_c dans le package)

Si les coordonnées re et im ont été échangées à l'étape 1, appliquer la correction $phi = pi/2 - phi$. Sinon laisser l'angle tel quel.
- signals_exchanged = 0 → pas de correction, phi reste à 302

=== Projection sur les quatre quadrants :

- Premier quadrant : $phi = phi$
- Deuxième quadrant : $phi = pi - phi$
- Troisième quadrant : $phi = phi + pi$
- Quatrième quadrant : $phi = -phi$

Donc:
- original_quadrant_id = "00" → Premier quadrant
- Pour le premier quadrant : $phi = phi$ (pas de modification)
- Donc phi = 302

*Résultat de l'étape 3* : $phi_o$ = 302

== Étape 4 : Extraction de l'amplitude

L'algorithme CORDIC en mode "vectoring" rabat le vecteur sur l'axe des réels. L'amplitude est donc simplement la valeur réelle de la dernière itération.

*Résultat de l'étape 4* : $"amp"_o$ = re final = 1306

== Résultats finaux du calculateur CORDIC :
- Amplitude ($"amp"_o$) = 1306
- Phase ($phi_o$) = 302

Conversion de la phase en radians :
- 302 sur 11 bits signés correspond à : $302 / 2^10 * pi approx 0.295 * pi approx 0.926$ radians

Comparaison avec les valeurs théoriques :
- Amplitude théorique = $sqrt(1000^2 + 500^2) approx 1118$
- Phase théorique = $arctan(500/1000) approx 0.464$ radians