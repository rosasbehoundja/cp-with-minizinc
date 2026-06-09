% ----------
% CP model of the MultiProduct Vehicle 
% Routing Problem with ChangeOver Costs
%
% @author: Rosas B.
% @url: https://github.io
% @date: 06.2026
% ----------
include "globals.mzn";
include "subcircuit.mzn";

% ----> parameters
int: N_PRODS;
int: N_DEPOT_PRODUCTS;
int: N_GARAGES;
int: N_REQUESTS;
int: N_VEHICLES;
int: N_NODES;

set of int: NODES = 1..N_NODES;
set of int: PRODUCTS = 1..N_PRODS;
set of int: DEPOTS = 1..N_DEPOT_PRODUCTS;
set of int: GARAGES = (N_DEPOT_PRODUCTS + 1)..(N_DEPOT_PRODUCTS + N_GARAGES);
set of int: REQUESTS = (N_DEPOT_PRODUCTS + N_GARAGES + 1)..N_NODES;
set of int: VEHICLES = 1..N_VEHICLES;

% Facteur multiplicateur pour préserver 3 décimales de précision sous forme d'entiers
int: SCALE = 1000;

% Lecture des coûts de changement de produit
array[PRODUCTS, PRODUCTS] of float: changeover_cost;
array[PRODUCTS, PRODUCTS] of int: changeover_cost_int = array2d(PRODUCTS, PRODUCTS, [round(changeover_cost[p1, p2] * SCALE) | p1, p2 in PRODUCTS]);

% Lecture des dépôts
array[1..N_DEPOT_PRODUCTS] of int: depot_id;
array[1..N_DEPOT_PRODUCTS] of int: depot_product;
array[1..N_DEPOT_PRODUCTS] of float: depot_stock;
array[1..N_DEPOT_PRODUCTS] of int: depot_stock_int = [round(depot_stock[d] * SCALE) | d in 1..N_DEPOT_PRODUCTS];
array[1..N_DEPOT_PRODUCTS] of float: depot_x;
array[1..N_DEPOT_PRODUCTS] of float: depot_y;

% Lecture des garages
array[1..N_GARAGES] of int: garage_id;
array[1..N_GARAGES] of float: garage_x;
array[1..N_GARAGES] of float: garage_y;

% Lecture des requêtes
array[1..N_REQUESTS] of int: request_id;
array[1..N_REQUESTS] of int: request_product;
array[1..N_REQUESTS] of float: request_demand;
array[1..N_REQUESTS] of int: request_demand_int = [round(request_demand[r] * SCALE) | r in 1..N_REQUESTS];
array[1..N_REQUESTS] of float: request_x;
array[1..N_REQUESTS] of float: request_y;

% Lecture des véhicules
array[VEHICLES] of int: vehicle_id;
array[VEHICLES] of float: vehicle_capacity;
array[VEHICLES] of int: vehicle_capacity_int = [round(vehicle_capacity[v] * SCALE) | v in VEHICLES];
array[VEHICLES] of int: vehicle_home_garage_raw; 
array[VEHICLES] of int: vehicle_init_product;

% Lecture de la matrice des distances
array[1..N_NODES,1..N_NODES] of float: dist; 
array[1..N_NODES,1..N_NODES] of int: dist_int = array2d(1..N_NODES, 1..N_NODES, [round(dist[i, j] * SCALE) | i, j in 1..N_NODES]);

% ----> Derived/Coerced Mappings for Global Node Alignment
array[VEHICLES] of int: vehicle_home_garage = [
    vehicle_home_garage_raw[v] + N_DEPOT_PRODUCTS | v in VEHICLES
];

array[REQUESTS] of int: req_product = array1d(REQUESTS, request_product);
array[REQUESTS] of int: req_demand = array1d(REQUESTS, request_demand_int);

% ----> Bornes supérieures entières calculées pour Gecode
int: MAX_CAPACITY = max(vehicle_capacity_int);
int: MAX_DEMAND_SUM = sum(request_demand_int);
int: MAX_DIST_SUM = sum(i, j in NODES)(dist_int[i, j]);
int: MAX_CHANGEOVER_SUM = sum(p1, p2 in PRODUCTS)(changeover_cost_int[p1, p2]) * N_NODES;
int: MAX_COST_SUM = MAX_DIST_SUM + MAX_CHANGEOVER_SUM;

% ----> decisions variables (Domaines entiers explicites)
array[VEHICLES, NODES] of var NODES: next;     
array[VEHICLES, NODES] of var PRODUCTS: prod;  
array[VEHICLES, NODES] of var 0..MAX_DEMAND_SUM: qty;      
array[VEHICLES, NODES] of var 0..MAX_CAPACITY: carried;  
array[VEHICLES, NODES] of var bool: visited;   
array[VEHICLES] of var bool: isUsed;           

% ----> constraints 

% Link visited status to the successor variable
constraint forall(v in VEHICLES, i in NODES) (
    visited[v, i] = (next[v, i] != i)
);

% Enforce that visited nodes for each vehicle form a valid subcircuit
constraint forall(v in VEHICLES) (
    subcircuit([next[v, i] | i in NODES])
);

% Vehicles start with an empty load at their home garage
constraint forall(v in VEHICLES) (
    carried[v, vehicle_home_garage[v]] = 0
);

% 1. A vehicle is used if it leaves its home garage
constraint forall(v in VEHICLES) (
    isUsed[v] = visited[v, vehicle_home_garage[v]]
);

% 2. Unused vehicles cannot visit any node
constraint forall(v in VEHICLES, i in NODES) (
    not isUsed[v] -> not visited[v, i]
);

% 3. If a vehicle is used, it must start at its home garage and go directly to a depot
constraint forall(v in VEHICLES) (
    isUsed[v] -> (next[v, vehicle_home_garage[v]] in DEPOTS)
);

% 4. The vehicle must start with its designated initial product
constraint forall(v in VEHICLES) (
    isUsed[v] -> (prod[v, vehicle_home_garage[v]] = vehicle_init_product[v])
);

% 5. A vehicle can NEVER visit a garage that is not its assigned home garage
constraint forall(v in VEHICLES, g in GARAGES) (
    g != vehicle_home_garage[v] -> not visited[v, g]
);

% 6. Product changes/loading can only occur at a depot node
constraint forall(v in VEHICLES, i in NODES) (
    (visited[v, i] /\ not (next[v, i] in DEPOTS)) -> (prod[v, next[v, i]] = prod[v, i])
);

% If a vehicle visits a depot, the product it carries must match that depot's product type
constraint forall(v in VEHICLES, d in DEPOTS) (
    visited[v, d] -> (prod[v, d] = depot_product[d])
);

% A vehicle cannot visit a request node without carrying the product needed by it
constraint forall(v in VEHICLES, r in REQUESTS) (
    visited[v, r] -> (prod[v, r] = req_product[r])
);

% A vehicle can never carry more than its capacity
constraint forall(v in VEHICLES, i in NODES) (
    carried[v, i] <= vehicle_capacity_int[v]
);

% A vehicle must deliver a strictly positive quantity to a visited request node
constraint forall(v in VEHICLES, r in REQUESTS) (
    visited[v, r] -> (qty[v, r] > 0)
);

% If a node is not visited by a vehicle, its delivered quantity and carried load are zero
constraint forall(v in VEHICLES, i in NODES) (
    not visited[v, i] -> (qty[v, i] = 0 /\ carried[v, i] = 0)
);

% All requests must be completely satisfied
constraint forall(r in REQUESTS) (
    sum(v in VEHICLES) (qty[v, r]) = req_demand[r]
);

% A vehicle cannot transition to a request node if its incoming carried quantity is zero
constraint forall(v in VEHICLES, i in NODES) (
    (visited[v, i] /\ next[v, i] in REQUESTS) -> (carried[v, i] > 0)
);

% Quantity tracking along the route (Réécriture compatible avec l'indexation int de Gecode)
constraint forall(v in VEHICLES, i in NODES) (
    visited[v, i] -> (
        let { var NODES: j = next[v, i] } in
        if j in REQUESTS then
            carried[v, j] = carried[v, i] - qty[v, j]
        elseif j in DEPOTS then
            if prod[v, j] != prod[v, i] then
                carried[v, j] = qty[v, j]
            else
                carried[v, j] = carried[v, i] + qty[v, j]
            endif
        else 
            carried[v, j] = 0
        endif
    )
);

% The total quantity loaded from any depot cannot exceed its available stock
constraint forall(d in DEPOTS) (
    sum(v in VEHICLES) (qty[v, d]) <= depot_stock_int[d]
);

% ----> objective function (Utilise désormais des entiers indexés par des variables sans erreur)
var 0..MAX_DIST_SUM: total_dist = sum(v in VEHICLES, i in NODES)(if visited[v, i] then dist_int[i, next[v, i]] else 0 endif);
var 0..MAX_CHANGEOVER_SUM: total_changeover = sum(v in VEHICLES, i in NODES)(if visited[v, i] then changeover_cost_int[prod[v, i], prod[v, next[v, i]]] else 0 endif);
var 0..MAX_COST_SUM: total_cost = total_dist + total_changeover;

% ----> search
% Stratégie de recherche : on fixe d'abord les routes puis les affectations de produits
solve :: seq_search([
    int_search([next[v, i] | v in VEHICLES, i in NODES], dom_w_deg, indomain_random),
    int_search([prod[v, i] | v in VEHICLES, i in NODES], first_fail, indomain_min),
    int_search([qty[v, i]  | v in VEHICLES, i in NODES], first_fail, indomain_min)
]) minimize total_cost;


% ----> output displaying (Division par SCALE pour retrouver les vraies valeurs float d'origine)
output [
    "===========================================================\n",
    " MPVRP-CC OPTIMIZATION RESULTS\n",
    "===========================================================\n",
    "Total Optimized Cost : " ++ show(total_cost / SCALE) ++ "\n",
    "  - Distance Cost    : " ++ show(total_dist / SCALE) ++ "\n",
    "  - Changeover Cost  : " ++ show(total_changeover / SCALE) ++ "\n",
    "===========================================================\n"
] ++ [
    "Vehicle " ++ show(v) ++ " [" ++ if fix(isUsed[v]) then "USED" else "UNUSED" endif ++ "]:\n" ++
    if fix(isUsed[v]) then
        concat([
            "  Node " ++ show(i) ++ " -> Next: " ++ show(fix(next[v, i])) ++ 
            " | Product Carried: " ++ show(fix(prod[v, i])) ++ 
            " | Load Left: " ++ show(fix(carried[v, i]) / SCALE) ++ 
            " | Qty Action: " ++ show(fix(qty[v, i]) / SCALE) ++ "\n"
            | i in NODES % Note: fermeture de la boucle d'affichage manquante corrigée ici
        ])
    else "" endif
    | v in VEHICLES
];
