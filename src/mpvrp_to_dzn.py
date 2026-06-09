import math
import sys

class MPVRPInstance:
    def __init__(self):
        self.uuid = ""
        self.n_prods = 0
        self.n_depots_read = 0
        self.n_garages = 0
        self.n_stations_read = 0
        self.n_vehicles = 0
        self.changeover_cost = []
        self.vehicles = []
        self.depot_products = []
        self.garages = []
        self.requests = []
        self.dist_matrix = []

def read_instance(filename):
    with open(filename, 'r') as f:
        tokens = f.read().split()
    
    if not tokens:
        raise ValueError("The provided instance file is empty.")
        
    iterator = iter(tokens)
    
    # Mimic Java: reader.getString() twice to extract uuid
    next(iterator) 
    uuid = next(iterator)
    
    n_prods = int(next(iterator))
    n_depots_read = int(next(iterator))
    n_garages = int(next(iterator))
    n_stations_read = int(next(iterator))
    n_vehicles = int(next(iterator))
    
    # Changeover cost matrix (nProds x nProds)
    changeover_cost = []
    for _ in range(n_prods):
        row = [float(next(iterator)) for _ in range(n_prods)]
        changeover_cost.append(row)
        
    # Vehicle fleet
    vehicles = []
    for _ in range(n_vehicles):
        v_id = int(next(iterator))
        capacity = float(next(iterator))
        home_garage_id = int(next(iterator))
        init_prod = int(next(iterator))
        vehicles.append({
            'id': v_id,
            'capacity': capacity,
            'home_garage_id': home_garage_id,
            'init_prod': init_prod
        })
        
    current_global_id = 0
    
    # Depot-product nodes
    depot_products = []
    for _ in range(n_depots_read):
        d_id = int(next(iterator))
        x = float(next(iterator))
        y = float(next(iterator))
        for p in range(n_prods):
            stock = float(next(iterator))
            if stock > 0:
                depot_products.append({
                    'id': d_id,
                    'global_id': current_global_id,
                    'x': x,
                    'y': y,
                    'product': p,
                    'stock': stock
                })
                current_global_id += 1
                
    # Garages (nodes where vehicles start/end routes)
    garages = []
    for _ in range(n_garages):
        g_id = int(next(iterator))
        x = float(next(iterator))
        y = float(next(iterator))
        garages.append({
            'id': g_id,
            'global_id': current_global_id,
            'x': x,
            'y': y
        })
        current_global_id += 1
        
    # Requests (stations)
    requests = []
    for _ in range(n_stations_read):
        r_id = int(next(iterator))
        x = float(next(iterator))
        y = float(next(iterator))
        for p in range(n_prods):
            demand = float(next(iterator))
            if demand > 0:
                requests.append({
                    'id': r_id,
                    'global_id': current_global_id,
                    'x': x,
                    'y': y,
                    'product': p,
                    'demand': demand
                })
                current_global_id += 1
                
    # Build full distance matrix mirroring Java node order
    all_nodes = []
    all_nodes.extend(depot_products)
    all_nodes.extend(garages)
    all_nodes.extend(requests)
    
    num_nodes = len(all_nodes)
    dist_matrix = [[0.0] * num_nodes for _ in range(num_nodes)]
    
    for i in range(num_nodes):
        for j in range(num_nodes):
            dx = all_nodes[i]['x'] - all_nodes[j]['x']
            dy = all_nodes[i]['y'] - all_nodes[j]['y']
            dist_matrix[i][j] = math.hypot(dx, dy)
            
    inst = MPVRPInstance()
    inst.uuid = uuid
    inst.n_prods = n_prods
    inst.n_depots_read = n_depots_read
    inst.n_garages = n_garages
    inst.n_stations_read = n_stations_read
    inst.n_vehicles = n_vehicles
    inst.changeover_cost = changeover_cost
    inst.vehicles = vehicles
    inst.depot_products = depot_products
    inst.garages = garages
    inst.requests = requests
    inst.dist_matrix = dist_matrix
    
    return inst

def export_to_dzn(inst):
    lines = [f"% Generated from MPVRP Instance: {inst.uuid}", ""]
    
    # Dimensions
    lines.append(f"N_PRODS = {inst.n_prods};")
    lines.append(f"N_DEPOT_PRODUCTS = {len(inst.depot_products)};")
    lines.append(f"N_GARAGES = {inst.n_garages};")
    lines.append(f"N_REQUESTS = {len(inst.requests)};")
    lines.append(f"N_VEHICLES = {inst.n_vehicles};")
    lines.append(f"N_NODES = {len(inst.dist_matrix)};\n")
    
    # Formatter Utilities
    def fmt_1d(arr):
        return "[" + ", ".join(str(x) for x in arr) + "]"
        
    def fmt_2d(matrix):
        rows = [", ".join(str(x) for x in row) for row in matrix]
        return "[| " + "\n  | ".join(rows) + " |]"

    # Changeover Costs
    lines.append(f"changeover_cost = {fmt_2d(inst.changeover_cost)};\n")
    
    # Depot Products (Converting 0-indexed products to 1-indexed)
    lines.append(f"depot_id = {fmt_1d([d['global_id'] for d in inst.depot_products])};")
    lines.append(f"depot_product = {fmt_1d([d['product'] + 1 for d in inst.depot_products])};")
    lines.append(f"depot_stock = {fmt_1d([d['stock'] for d in inst.depot_products])};")
    lines.append(f"depot_x = {fmt_1d([d['x'] for d in inst.depot_products])};")
    lines.append(f"depot_y = {fmt_1d([d['y'] for d in inst.depot_products])};\n")
    
    # Garages
    lines.append(f"garage_id = {fmt_1d([g['global_id'] for g in inst.garages])};")
    lines.append(f"garage_x = {fmt_1d([g['x'] for g in inst.garages])};")
    lines.append(f"garage_y = {fmt_1d([g['y'] for g in inst.garages])};\n")
    
    # Requests (Converting 0-indexed products to 1-indexed)
    lines.append(f"request_id = {fmt_1d([r['global_id'] for r in inst.requests])};")
    lines.append(f"request_product = {fmt_1d([r['product'] + 1 for r in inst.requests])};")
    lines.append(f"request_demand = {fmt_1d([r['demand'] for r in inst.requests])};")
    lines.append(f"request_x = {fmt_1d([r['x'] for r in inst.requests])};")
    lines.append(f"request_y = {fmt_1d([r['y'] for r in inst.requests])};\n")
    
    # Vehicles mapping
    # Maps garage raw ID to its 1-based index inside the GARAGES set
    garage_id_to_idx = {g['global_id']: idx + 1 for idx, g in enumerate(inst.garages)}
    
    lines.append(f"vehicle_id = {fmt_1d([v['id'] for v in inst.vehicles])};")
    lines.append(f"vehicle_capacity = {fmt_1d([v['capacity'] for v in inst.vehicles])};")
    lines.append(f"vehicle_home_garage_raw = {fmt_1d([garage_id_to_idx[v['home_garage_id']] for v in inst.vehicles])};")
    
    # Accounts for initial product being unassigned (-1 -> 0) or 0-indexed (0 -> 1)
    # print([v['init_prod'] for v in inst.vehicles])
    vehicle_inits = [v['init_prod'] for v in inst.vehicles]
    lines.append(f"vehicle_init_product = {fmt_1d(vehicle_inits)};\n")
    
    # Flattened Distance Matrix
    lines.append(f"dist = {fmt_2d(inst.dist_matrix)};")
    
    return "\n".join(lines)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python mpvrp_to_dzn.py <input_file.dat> <output_file.dzn>")
    else:
        try:
            inst = read_instance(sys.argv[1])
            dzn_data = export_to_dzn(inst)
            with open(sys.argv[2], 'w') as out_f:
                out_f.write(dzn_data)
            print(f"Successfully exported data to {sys.argv[2]}")
        except Exception as e:
            print(f"Error during execution: {e}")