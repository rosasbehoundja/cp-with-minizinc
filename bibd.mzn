%**
%*  Balanced Incomplete Block Design Problem
%**

% Parameters
int: n_grains = 7;
int: n_plots = 7;
int: grains_per_plot = 3;
int: plots_per_grain = 3;
int: balance = 1;

% Decision Variables: 1 if grain i is in plot j, 0 otherwise
array[1..n_grains, 1..n_plots] of var 0..1: design;

% 1. Equal sample size: Every grain is grown in 3 plots
constraint forall(i in 1..n_grains) (
    sum(j in 1..n_plots)(design[i, j]) = plots_per_grain
);

% 2. Equal growth load: Every plot grows 3 grains
constraint forall(j in 1..n_plots) (
    sum(i in 1..n_grains)(design[i, j]) = grains_per_plot
);

% 3. Balance: Every grain pair is grown in 1 common plot
% We use the dot product of two rows to count common plots
constraint forall(i1, i2 in 1..n_grains where i1 < i2) (
    sum(j in 1..n_plots)(design[i1, j] * design[i2, j]) = balance
);

solve satisfy;

% Output formatting
output [
    if j = 1 then "\n" else " " endif ++ show(design[i,j])
    | i in 1..n_grains, j in 1..n_plots
];