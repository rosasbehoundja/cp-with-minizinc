%**
%*  Magic Sequence
%**

include "count.mzn";

% Parameters
int: n = 4; % Length of the magic series (can be adjusted)

% Decision Variables
array[0..n-1] of var 0..n-1: x;

% Constraints
% For all i from 0 to n-1, the value i must appear exactly x[i] times in x
constraint forall(i in 0..n-1) (
    count(x, i) = x[i]
);

% Redundant Constraints (Important for performance in larger n)
% 1. The sum of the elements must equal n
constraint sum(x) = n;

% 2. The weighted sum sum(i * x[i]) must also equal n
constraint sum(i in 0..n-1)(i * x[i]) = n;

solve satisfy;

output [
    "Magic Series (n=\(n)): ", show(x)
];