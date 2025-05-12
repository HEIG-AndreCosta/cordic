= Calcul de référence

Calcule des 10 itérations CORDIC pour re=1000, im=500.

== Étape 1 : Prétraitement
- Calcul de la valeur absolue de re et im. Ceci projette les coordonnées dans le premier quadrant.
- Comparaison entre re et im. Si re > im alors leurs valeurs sont échangées. Ceci projette les coordonnées dans le premier octant.
  - Coordonnées initiales : re=1000, im=500
  - Les deux sont positifs → premier quadrant (original_quadrant_id = "00")
  - Valeurs absolues : re=1000, im=500 (pas de changement car déjà positifs)
  - re > im → on échange : re=500, im=1000, signals_exchanged=1

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

À chaque itération, on teste si le signe de im est négatif :

Le tableau jusqu'à 10 itérations :

#table(
  columns: 10,
  stroke: 0.5pt,
  [*Iter*], [*re_i*], [*im_i*], [*phi_i*], [*im < 0 ?*], [*im_i/2^i*], [*re_i/2^i*], [*re_i+1*], [*im_i+1*], [*phi_i+1*],
  [Init], [500], [1000], [0], [-], [-], [-], [-], [-], [-],
  [1], [500], [1000], [0], [NON], [500], [250], [1000], [750], [302],
  [2], [1000], [750], [302], [NON], [187], [250], [1187], [500], [462],
  [3], [1187], [500], [462], [NON], [62], [148], [1249], [352], [543],
  [4], [1249], [352], [543], [NON], [22], [78], [1271], [274], [584],
  [5], [1271], [274], [584], [NON], [8], [39], [1279], [235], [604],
  [6], [1279], [235], [604], [NON], [3], [19], [1282], [216], [614],
  [7], [1282], [216], [614], [NON], [1], [10], [1283], [206], [619],
  [8], [1283], [206], [619], [NON], [0], [5], [1283], [201], [622],
  [9], [1283], [201], [622], [NON], [0], [2], [1283], [199], [623],
  [10], [1283], [199], [623], [NON], [0], [1], [1283], [198], [624],
)

Détails des calculs (avec divisions entières) :
- Itération 2 : $"im"_i\/2^2$ = 750/4 = 187, $"re"_i\/2^2$ = 1000/4 = 250
- Itération 3 : $"im"_i\/2^3$ = 500/8 = 62, $"re"_i\/2^3$ = 1187/8 = 148
- Itération 4 : $"im"_i\/2^4$ = 352/16 = 22, $"re"_i\/2^4$ = 1249/16 = 78
- Itération 5 : $"im"_i\/2^5$ = 274/32 = 8, $"re"_i\/2^5$ = 1271/32 = 39
- Itération 6 : $"im"_i\/2^6$ = 235/64 = 3, $"re"_i\/2^6$ = 1279/64 = 19
- Itération 7 : $"im"_i\/2^7$ = 216/128 = 1, $"re"_i\/2^7$ = 1282/128 = 10
- Itération 8 : $"im"_i\/2^8$ = 206/256 = 0, $"re"_i\/2^8$ = 1283/256 = 5
- Itération 9 : $"im"_i\/2^9$ = 201/512 = 0, $"re"_i\/2^9$ = 1283/512 = 2
- Itération 10 : $"im"_i\/2^10$ = 199/1024 = 0, $"re"_i\/2^10$ = 1283/1024 = 1

À la fin des 10 itérations :
- re final = 1283
- im final = 198
- phi final = 624

== Étape 3 : Projection de l'angle sur les 4 quadrants

Rappel des valeurs après les itérations :
- phi après itérations = 624
- signals_exchanged = 1 (échange lors du prétraitement)
- original_quadrant_id = "00" (premier quadrant)

=== Projection sur le premier quadrant :

- PI   = $2^(11-1)$ = $2^10$ = 1024 (d'après la constante pidiv1_c dans le package)
- PI/2 = $2^(11-2)$ = $2^9$  =  512 (d'après la constante pidiv2_c dans le package)

Si les coordonnées re et im ont été échangées à l'étape 1, appliquer la correction $phi = pi\/2 - phi$. Sinon laisser l'angle tel quel.
- signals_exchanged = 1 → on fait la correction $phi = pi\/2 - phi$
- PI/2 = $2^(11-2)$ = $2^9$ = 512 (d'après la constante pidiv2_c dans le package)
- phi = 512 - 624 = -112

=== Projection sur les quatre quadrants :

- Premier quadrant : $phi = phi$
- Deuxième quadrant : $phi = pi - phi$
- Troisième quadrant : $phi = phi + pi$
- Quatrième quadrant : $phi = -phi$

Donc:
- original_quadrant_id = "00" → Premier quadrant
- Pour le premier quadrant : $phi = phi$ (pas de modification)
- Donc phi = -112

*Résultat de l'étape 3* : $phi_"o"$ = -112

== Étape 4 : Extraction de l'amplitude

L'algorithme CORDIC en mode "vectoring" rabat le vecteur sur l'axe des réels. L'amplitude est donc simplement la valeur réelle de la dernière itération.

*Résultat de l'étape 4* : $"amp"_"o"$ = re final = 1283

== Résultats finaux du calculateur CORDIC :
- Amplitude ($"amp"_"o"$) = 1283
- Phase ($phi_"o"$) = -112

Conversion de la phase en radians :
- -112 sur 11 bits signés correspond à : $-112 / 2^10 times pi approx -0.109 times pi approx -0.343$ radians

Comparaison avec les valeurs théoriques :
- Amplitude théorique = $"sqrt"(1000^2 + 500^2) approx 1118$
- Phase théorique = $"atan2"(500, 1000) approx 0.464$ radians