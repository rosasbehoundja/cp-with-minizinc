% ─────────────────────────────────────────────────────────────
% PARAMÈTRES
% ─────────────────────────────────────────────────────────────

int: nb_jours;
int: nb_heures;
int: nb_salles;
int: nb_etudiants;
int: nb_enseignants;

set of int: JOURS      = 1..nb_jours;
set of int: HEURES     = 1..nb_heures;
set of int: SALLES     = 1..nb_salles;
set of int: ETUDIANTS  = 1..nb_etudiants;
set of int: ENSEIGNANTS = 1..nb_enseignants;
set of int: ROLES      = 0..2;   % 0=Président, 1=Maître mémoire, 2=Examinateur

% Grade de chaque enseignant (1=Ingénieur … 5=Professeur)
int: g_min = 2;   % grade minimum pour être président
array[ENSEIGNANTS] of int: grade;

% disponibilite[e,j,h] = 1 si l'enseignant e est disponible le jour j à l'heure h
array[ENSEIGNANTS, JOURS, HEURES] of 0..1: disponibilite;

% mm[t,e] = 1 si e est le maître de mémoire de t
array[ETUDIANTS, ENSEIGNANTS] of 0..1: mm;

% specialist[t,e] = 1 si e est spécialiste de la spécialité de t
array[ETUDIANTS, ENSEIGNANTS] of 0..1: specialist;

% Pénalités pour les contraintes soft
int: p1 = 10000;   % dépassement de 8 soutenances/salle/jour
int: p2 = 1000000;    % changement de salle pour un enseignant
int: p3 = 5000000;     % temps d'attente entre deux jurys

% ─────────────────────────────────────────────────────────────
% VARIABLES DE DÉCISION
% ─────────────────────────────────────────────────────────────

% x[j,h,k,t] = 1 ↔ étudiant t soutient le jour j, heure h, salle k
array[JOURS, HEURES, SALLES, ETUDIANTS] of var 0..1: x;

% y[j,h,k,e,r] = 1 ↔ enseignant e joue le rôle r dans le jury
%                      de la soutenance en salle k, jour j, heure h
array[JOURS, HEURES, SALLES, ENSEIGNANTS, ROLES] of var 0..1: y;

% ─────────────────────────────────────────────────────────────
% VARIABLES AUXILIAIRES (contraintes soft)
% ─────────────────────────────────────────────────────────────

% a[e,j,h] = 1 si l'enseignant e intervient le jour j à l'heure h
array[ENSEIGNANTS, JOURS, HEURES] of var 0..1: a;

% z[e,j,k] = 1 si l'enseignant e intervient dans la salle k le jour j
array[ENSEIGNANTS, JOURS, SALLES] of var 0..1: z;

% s_soft[j,k] = dépassement du seuil de 8 soutenances/salle/jour
array[JOURS, SALLES] of var 0..nb_etudiants: s_soft;

% w[e,j] = nombre de salles en excès utilisées par e le jour j
array[ENSEIGNANTS, JOURS] of var 0..nb_salles: w;

% T_min[e,j], T_max[e,j] : premier et dernier créneau actif
array[ENSEIGNANTS, JOURS] of var 1..nb_heures: T_min;
array[ENSEIGNANTS, JOURS] of var 1..nb_heures: T_max;

% waiting_time[e,j] : créneaux perdus entre le premier et le dernier jury
array[ENSEIGNANTS, JOURS] of var 0..nb_heures: waiting_time;

% ─────────────────────────────────────────────────────────────
% LIENS ENTRE VARIABLES AUXILIAIRES ET DÉCISION
% ─────────────────────────────────────────────────────────────

% Lien a ↔ y
constraint forall(e in ENSEIGNANTS, j in JOURS, h in HEURES)(
    a[e,j,h] = sum(k in SALLES, r in ROLES)(y[j,h,k,e,r])
);

% Lien z ↔ y
constraint forall(e in ENSEIGNANTS, j in JOURS, k in SALLES)(
    z[e,j,k] = bool2int(
        sum(h in HEURES, r in ROLES)(y[j,h,k,e,r]) > 0
    )
);

% ─────────────────────────────────────────────────────────────
% CONTRAINTES DURES
% ─────────────────────────────────────────────────────────────

% a) Chaque étudiant soutient au plus une fois
constraint forall(t in ETUDIANTS)(
    sum(j in JOURS, h in HEURES, k in SALLES)(x[j,h,k,t]) <= 1
);

% b) Pas de conflit dans une salle (≤ 1 soutenance par créneau/salle)
constraint forall(j in JOURS, h in HEURES, k in SALLES)(
    sum(t in ETUDIANTS)(x[j,h,k,t]) <= 1
);

% c) Pas de conflit horaire pour les enseignants
constraint forall(e in ENSEIGNANTS, j in JOURS, h in HEURES)(
    sum(k in SALLES, r in ROLES)(y[j,h,k,e,r]) <= 1
);

% d) Disponibilité des enseignants
constraint forall(e in ENSEIGNANTS, j in JOURS, h in HEURES, k in SALLES, r in ROLES)(
    y[j,h,k,e,r] <= disponibilite[e,j,h]
);

% e) Constitution du jury : exactement 3 membres par soutenance
constraint forall(j in JOURS, h in HEURES, k in SALLES)(
    let { var 0..1: slot = sum(t in ETUDIANTS)(x[j,h,k,t]) } in (
        % 3 membres exactement
        sum(e in ENSEIGNANTS, r in ROLES)(y[j,h,k,e,r]) = 3 * slot
        /\
        % un enseignant n'a qu'un seul rôle par soutenance
        forall(e in ENSEIGNANTS)(
            sum(r in ROLES)(y[j,h,k,e,r]) <= 1
        )
        /\
        % un seul président
        sum(e in ENSEIGNANTS)(y[j,h,k,e,0]) <= 1
        /\
        % le maître de mémoire (rôle 1) doit être celui de l'étudiant
        sum(e in ENSEIGNANTS, t in ETUDIANTS)(mm[t,e] * y[j,h,k,e,1]) >= slot
        /\
        % l'examinateur (rôle 2) doit être spécialiste
        sum(e in ENSEIGNANTS, t in ETUDIANTS)(specialist[t,e] * y[j,h,k,e,2]) >= slot
    )
);

% f) Président : grade minimum + exactement 1 si soutenance
constraint forall(j in JOURS, h in HEURES, k in SALLES)(
    let { var 0..1: slot = sum(t in ETUDIANTS)(x[j,h,k,t]) } in (
        sum(e in ENSEIGNANTS)(grade[e] * y[j,h,k,e,0]) >= g_min * slot
        /\
        sum(e in ENSEIGNANTS)(y[j,h,k,e,0]) = slot
    )
);

% g) Maximum 4 soutenances par enseignant par jour
constraint forall(e in ENSEIGNANTS, j in JOURS)(
    sum(h in HEURES, k in SALLES, r in ROLES)(y[j,h,k,e,r]) <= 4
);

% h) Le président doit avoir le grade le plus élevé du jury
%    → Pour chaque paire (ep, em) avec grade[ep] < grade[em],
%      ep et em ne peuvent pas être simultanément dans le même jury
constraint forall(j in JOURS, h in HEURES, k in SALLES,
                  ep in ENSEIGNANTS, em in ENSEIGNANTS
                  where ep != em /\ grade[ep] < grade[em])(
    y[j,h,k,ep,0] + sum(r in 1..2)(y[j,h,k,em,r]) <= 1
);

% i) L'examinateur doit être spécialiste de l'étudiant soutenant dans ce slot
constraint forall(j in JOURS, h in HEURES, k in SALLES,
                  e in ENSEIGNANTS, t in ETUDIANTS
                  where specialist[t,e] = 0)(
    y[j,h,k,e,2] + x[j,h,k,t] <= 1
);

% j) Le maître de mémoire de t doit avoir le rôle 1 si t soutient ici
constraint forall(j in JOURS, h in HEURES, k in SALLES, t in ETUDIANTS)(
    sum(e in ENSEIGNANTS)(mm[t,e] * y[j,h,k,e,1]) >= x[j,h,k,t]
);

% ─────────────────────────────────────────────────────────────
% CONTRAINTES SOFT – variables d'écart
% ─────────────────────────────────────────────────────────────

% Soft 1 : max 8 soutenances par salle par jour
constraint forall(j in JOURS, k in SALLES)(
    s_soft[j,k] >= sum(h in HEURES, t in ETUDIANTS)(x[j,h,k,t]) - 8
);

% Soft 2 : pénalité changement de salle
constraint forall(e in ENSEIGNANTS, j in JOURS)(
    w[e,j] >= sum(k in SALLES)(z[e,j,k]) - 1
);

% Soft 3 : temps d'attente
%   T_min[e,j] <= h dès que a[e,j,h] = 1
%   T_max[e,j] >= h dès que a[e,j,h] = 1
constraint forall(e in ENSEIGNANTS, j in JOURS, h in HEURES)(
    a[e,j,h] = 1 -> (T_min[e,j] <= h /\ T_max[e,j] >= h)
);
% Si l'enseignant n'intervient pas du tout ce jour, T_min = T_max = 1
constraint forall(e in ENSEIGNANTS, j in JOURS)(
    sum(h in HEURES)(a[e,j,h]) = 0 -> (T_min[e,j] = 1 /\ T_max[e,j] = 1)
);

constraint forall(e in ENSEIGNANTS, j in JOURS)(
    waiting_time[e,j] >= T_max[e,j] - T_min[e,j] + 1
                         - sum(h in HEURES)(a[e,j,h])
);

% ─────────────────────────────────────────────────────────────
% FONCTION OBJECTIF
%   Maximiser : ∑ soutenances − p1·∑ s_soft − p2·∑ w − p3·∑ waiting_time
% ─────────────────────────────────────────────────────────────

var int: total_soutenances  = sum(j in JOURS, h in HEURES, k in SALLES, t in ETUDIANTS)(x[j,h,k,t]);
var int: penalite_soft1     = p1 * sum(j in JOURS, k in SALLES)(s_soft[j,k]);
var int: penalite_soft2     = p2 * sum(e in ENSEIGNANTS, j in JOURS)(w[e,j]);
var int: penalite_soft3     = p3 * sum(e in ENSEIGNANTS, j in JOURS)(waiting_time[e,j]);

solve maximize (total_soutenances - penalite_soft1 - penalite_soft2 - penalite_soft3);

% ─────────────────────────────────────────────────────────────
% AFFICHAGE
% ─────────────────────────────────────────────────────────────

output [
    "=== Résultats ===\n",
    "Soutenances planifiées : ", show(total_soutenances), "\n",
    "Pénalité soft1 (dépassement salle) : ", show(penalite_soft1), "\n",
    "Pénalité soft2 (changement salle)  : ", show(penalite_soft2), "\n",
    "Pénalité soft3 (temps d'attente)   : ", show(penalite_soft3), "\n",
    "\n--- Détail des soutenances ---\n"
] ++
[
    if fix(x[j,h,k,t]) = 1 then
        "Étudiant " ++ show(t) ++
        " | Jour " ++ show(j) ++
        " | Heure " ++ show(h) ++
        " | Salle " ++ show(k) ++
        " | Président: "  ++ show([e | e in ENSEIGNANTS where fix(y[j,h,k,e,0])=1]) ++
        " | MM: "         ++ show([e | e in ENSEIGNANTS where fix(y[j,h,k,e,1])=1]) ++
        " | Examinateur: " ++ show([e | e in ENSEIGNANTS where fix(y[j,h,k,e,2])=1]) ++
        "\n"
    else ""
    endif
    | j in JOURS, h in HEURES, k in SALLES, t in ETUDIANTS
];
