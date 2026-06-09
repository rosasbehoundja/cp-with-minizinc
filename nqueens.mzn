% Problème des N-Reines
% Modèle par permutation : T[i] = colonne de la reine sur la ligne i
% Les colonnes sont garanties distinctes car T est une permutation.
% Il suffit donc de vérifier uniquement les diagonales.
include "alldifferent.mzn";

% Le nombre de reines (et la taille de l'échiquier)
int: n = 10;

% T est un tableau de taille n, dont les valeurs sont une permutation de 0..n-1
% T[i] représente la colonne de la reine placée sur la ligne i
array[0..n-1] of var 0..n-1: T;

% --- Contrainte 1 : T est une permutation ---
% Cela garantit que toutes les colonnes sont distinctes d'un coup.
constraint alldifferent(T);

% --- Contrainte 2 : pas de conflit sur les diagonales ---
% Deux reines i et j sont en conflit diagonal si
% la différence de lignes == différence de colonnes
% c'est-à-dire : |i - j| == |T[i] - T[j]|
constraint forall(i in 0..n-1, j in 0..n-1 where i < j)(
    abs(i - j) != abs(T[i] - T[j])
);

% --- Recherche d'une solution ---
% solve :: int_search(T, first_fail, indomain_min) satisfy;
solve satisfy;

% --- Affichage ---
output
  % Bordure supérieure : "+---+---+---+ ..."
  [ "+" ++ concat(["---+" | _ in 0..n-1]) ++ "\n" ] ++

  % Pour chaque ligne i...
  [ 
    % ...on affiche une rangée de cases
    % si la colonne j correspond à T[i], on place une reine "Q", sinon une case vide
    "| " ++ concat([ if fix(T[i]) == j then "Q | " else ". | " endif | j in 0..n-1 ]) ++ "\n" ++
    
    % Séparateur horizontal après chaque ligne
    "+" ++ concat(["---+" | _ in 0..n-1]) ++ "\n"

  | i in 0..n-1 ];