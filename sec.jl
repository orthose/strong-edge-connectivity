# :author: Maxime VINCENT

using Cbc, JuMP

"""
Donne les successeurs du sommet i du graphe g.
Ce sont les indices des cases valant 1 de la ième ligne.

:param g: matrice d'adjacence du graphe
:param i: indice du sommet
"""
function successors(g::Matrix{Int}, i::Int)
    return findall(x->x==1, g[i,:])
end

"""
Donne les prédecesseurs du sommet j du graphe g.
Ce sont les indices des cases valant 1 de la jème colonne.

:param g: matrice d'adjacence du graphe
:param j: indice du sommet
"""
function predecessors(g::Matrix{Int}, j::Int)
    return findall(x->x==1, g[:,j])
end

"""
Programme linéaire résolvant le problème de flot maximal
du graphe g de la source a à la cible b.

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

    # Le flot x[i,j] de l'arc (i,j) ne peut pas excéder 
    # la capacité g[i,j] de l'arête (i,j) du réseau g
    @constraint(m, capacity[i in 1:n, j in 1:n], x[i,j] <= g[i,j])

    # Le flot entrant du sommet i doit être égal à son flot sortant
    # de manière à former un chemin continu des sommets a à b
    # La règle ne s'applique pas pour a et b
    @constraint(m, path[i in [i for i in 1:n if !(i in [a,b])]], 
                sum(x[j,i] for j in predecessors(g, i)) 
                == sum(x[i,j] for j in successors(g, i)))
	
    # On maximise le flot sortant du sommet source 
	@objective(m, Max, sum(x[a,j] for j in successors(g, a)))
	
    # Lancement de l'optimisation
	optimize!(m)
	
	# Une solution a-t-elle été trouvée ?
	status = termination_status(m)
	@assert status == MOI.OPTIMAL "Aucune solution trouvée pour le problème de flot maximal"

    return round(Int, JuMP.objective_value(m)), round.(Int, JuMP.value.(x))
end
