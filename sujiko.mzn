%**
%*  Sujiko
%**

include "alldifferent.mzn";

% Parameters: The four quadrant sums
% Top-Left (TL), Top-Right (TR), Bottom-Left (BL), Bottom-Right (BR)
int: sumTL;
int: sumTR;
int: sumBL;
int: sumBR;

% Decision Variables: The 3x3 grid
% 1 2 3
% 4 5 6
% 7 8 9
array[1..3, 1..3] of var 1..9: grid;

% 1. All numbers 1-9 must be used exactly once
constraint alldifferent([grid[i,j] | i,j in 1..3]);

% 2. Quadrant Sum Constraints
% Top-Left quadrant (cells 1,1; 1,2; 2,1; 2,2)
constraint grid[1,1] + grid[1,2] + grid[2,1] + grid[2,2] = sumTL;

% Top-Right quadrant (cells 1,2; 1,3; 2,2; 2,3)
constraint grid[1,2] + grid[1,3] + grid[2,2] + grid[2,3] = sumTR;

% Bottom-Left quadrant (cells 2,1; 2,2; 3,1; 3,2)
constraint grid[2,1] + grid[2,2] + grid[3,1] + grid[3,2] = sumBL;

% Bottom-Right quadrant (cells 2,2; 2,3; 3,2; 3,3)
constraint grid[2,2] + grid[2,3] + grid[3,2] + grid[3,3] = sumBR;

constraint grid[3,1] = 8; constraint grid[3,3] = 7;

solve satisfy;

output [
    show(grid[i,j]) ++ if j == 3 then "\n" else " " endif
    | i,j in 1..3
];