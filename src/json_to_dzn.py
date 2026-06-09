"""
json_to_dzn.py
Convertit simu.json → soutenances.dzn pour MiniZinc.
Usage : python json_to_dzn.py simu.json soutenances.dzn
"""

import json
import sys

def dzn_array2d(rows, cols, data, row_label, col_label):
    return f"array2d({row_label}, {col_label}, [\n" + \
           ",\n".join("  " + ", ".join(str(v) for v in row) for row in data) + \
           "\n])"

def dzn_array3d(d1, d2, d3, data, l1, l2, l3):
    flat = [data[i][j][k] for i in range(d1) for j in range(d2) for k in range(d3)]
    vals = ", ".join(str(v) for v in flat)
    return f"array3d({l1}, {l2}, {l3}, [{vals}])"

def convert(json_path, dzn_path):
    rank_values = {'Ingénieur': 1, 'Docteur': 2, 'MA': 3, 'MC': 4, 'Professeur': 5}

    with open(json_path) as f:
        data = json.load(f)

    etudiants   = data["students"]
    enseignants = data["professeurs"]
    salles      = data["salles"]

    nb_e  = len(etudiants)
    nb_p  = len(enseignants)
    nb_s  = len(salles)
    nb_j  = len(enseignants[0]["disponibilite"])
    nb_h  = len(enseignants[0]["disponibilite"][0])

    ens_idx = {e["id"]: i for i, e in enumerate(enseignants)}
    grades  = [rank_values[e["grade"]] for e in enseignants]

    dispo = [
        [[enseignants[e]["disponibilite"][j][h] for h in range(nb_h)]
         for j in range(nb_j)]
        for e in range(nb_p)
    ]

    mm = [[0] * nb_p for _ in range(nb_e)]
    for t, etd in enumerate(etudiants):
        mm_id = etd.get("mm_id")
        if mm_id in ens_idx:
            mm[t][ens_idx[mm_id]] = 1

    spec = [[0] * nb_p for _ in range(nb_e)]
    for t, etd in enumerate(etudiants):
        for e, ens in enumerate(enseignants):
            if etd["speciality"] in ens["specialities"]:
                spec[t][e] = 1

    lines = [
        f"nb_jours       = {nb_j};",
        f"nb_heures      = {nb_h};",
        f"nb_salles      = {nb_s};",
        f"nb_etudiants   = {nb_e};",
        f"nb_enseignants = {nb_p};",
        "",
        f"grade = {grades};",
        "",
        f"disponibilite = {dzn_array3d(nb_p, nb_j, nb_h, dispo, 'ENSEIGNANTS', 'JOURS', 'HEURES')};",
        "",
        f"mm = {dzn_array2d(nb_e, nb_p, mm, 'ETUDIANTS', 'ENSEIGNANTS')};",
        "",
        f"specialist = {dzn_array2d(nb_e, nb_p, spec, 'ETUDIANTS', 'ENSEIGNANTS')};",
    ]

    with open(dzn_path, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"✅ Fichier généré : {dzn_path}")
    print(f"   {nb_e} étudiants | {nb_p} enseignants | {nb_s} salles | {nb_j} jours × {nb_h} heures")

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "simu.json"
    dst = sys.argv[2] if len(sys.argv) > 2 else "soutenances.dzn"
    convert(src, dst)
