# Description
Projet d'Optimisation de M2 ISD portant sur la connexité forte d'un graphe.

# Fichiers
* **project_2022_2023.pdf**: Énoncé du projet annoté.
* **modeling.pdf**: Notes manuscrites de la modélisation du problème.
* **sec.jl**: Fonctions de résolution du problème dont le calcul de la SEC.
* **tests.jl**: Tests automatiques des fonctions sur des graphes.

# Dépendances
```shell
$ julia
julia> import Pkg; Pkg.add("Cbc")
julia> import Pkg; Pkg.add("JuMP")
```

# Exécution
```shell
$ julia tests.jl
```

