# :author: Maxime VINCENT

using Cbc, JuMP

"""
Donne les successeurs du sommet i du graphe g.
Ce sont les indices des cases valant 1 de la ième ligne.

:param g: matrice d'adjacence du graphe
:param i: indice du sommet
"""
function successors(g::Matrix{Int}, i::Int)::Vector{Int}
    return findall(x->x==1, g[i,:])
end

"""
Donne les prédecesseurs du sommet j du graphe g.
Ce sont les indices des cases valant 1 de la jème colonne.

:param g: matrice d'adjacence du graphe
:param j: indice du sommet
"""
function predecessors(g::Matrix{Int}, j::Int)::Vector{Int}
    return findall(x->x==1, g[:,j])
end

"""
Programme linéaire résolvant le problème de flot maximal
du graphe g de la source a à la cible b en variables binaires

:param g: matrice d'adjacence du graphe
:param a: indice de la source
:param b: indice de la cible
:return: valeur du flot maximal, graphe du flot maximal
"""
function P(g::Matrix{Int}, a::Int, b::Int)::Tuple{Int, Matrix{Int}}
    # Vérification des arguments
    @assert size(g, 1) == size(g, 2)
    n = size(g, 1)
    @assert 0 < a <= n
    @assert 0 < b <= n
    @assert a != b

    # Définition du programme linéaire
    m = JuMP.Model(Cbc.Optimizer)

    # x[i,j] dans [0,1] représente le flot de l'arc (i,j)
    @variable(m, x[i in 1:n, j in 1:n], Bin)
    # Si on veut généraliser avec des capacités positives
    #@variable(m, x[i in 1:n, j in 1:n] >= 0) 

    # Le flot x[i,j] de l'arc (i,j) ne peut pas excéder 
    # la capacité g[i,j] de l'arête (i,j) du réseau g
    @constraint(m, capacity[i in 1:n, j in 1:n], x[i,j] <= g[i,j])

    # Le flot entrant du sommet i doit être égal à son flot sortant
    # de manière à former un chemin continu des sommets a à b
    # La règle ne s'applique pas pour a et b
    @constraint(m, path[i in [i for i in 1:n if !(i in [a,b])]], 
                sum(x[j,i] for j in predecessors(g, i)) 
                == sum(x[i,j] for j in successors(g, i)))

    # Aucun flot ne doit entrer dans la source a
    @constraint(m, sum(x[i,a] for i in predecessors(g, a)) == 0)

    # Aucun flot ne doit sortir de la cible b
    @constraint(m, sum(x[b,j] for j in successors(g, b)) == 0)
	
    # On maximise le flot sortant du sommet source 
	@objective(m, Max, sum(x[a,j] for j in successors(g, a)))
	
    # Lancement de l'optimisation
    MOI.set(m, MOI.Silent(), true)
	optimize!(m)
	
	# Une solution a-t-elle été trouvée ?
	status = termination_status(m)
	@assert status == MOI.OPTIMAL "Aucune solution trouvée pour le problème de flot maximal"

    return round(Int, JuMP.objective_value(m)), round.(Int, JuMP.value.(x))
end

"""
Calcule la Strong Edge Connectivity (SEC) du graphe g.
Donne la coupe minimale associée sous forme d'une liste d'arcs (i,j).
Complexité en n sommets.

:param g: matrice d'adjacence du graphe
:return: valeur entière de la SEC, coupe minimale associée
"""
function sec(g::Matrix{Int}, verbose::Bool=false)::Tuple{Int, Array{Tuple{Int, Int}}}
    # Vérification des arguments
    @assert size(g, 1) == size(g, 2)
    n = size(g, 1)

    # Cas de base si moins de 2 sommets
    if n < 2 return 0 end

    # Recherche de la SEC minimale
    pmin, x = P(g, 1, 2)
    if verbose println("P(", 1, ",", 2, ")=", pmin) end
    # Le graphe n'est pas fortement connexe
    if pmin == 0 return pmin, [] end
    mincut = map(y -> (1, y), successors(x, 1))

    for a in 2:n
        # si a = n alors b = 1 sinon b = a + 1
        b = (a % n) + 1 
        p, x = P(g, a, b)
        if verbose println("P(", a, ",", b, ")=", p) end

        # Mise à jour de la SEC et de la coupe minimales
        if p < pmin
            pmin = p
            # Le graphe n'est pas fortement connexe
            if pmin == 0
                mincut = []; break
            else 
                mincut = map(y -> (a, y), successors(x, a)) 
            end
        end
    end 

    return pmin, mincut
end

"""
Génère une matrice carré aléatoire binaire de taille n.

:param n: taille de la matrice
:param p: probabilité de tirer 1
:return: matrice aléatoire
"""
function rand_graph(n::Int, p::Float64)::Matrix{Int}
    return rand(n, n) .<= p
end
