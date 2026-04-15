%**
%* Guess my birthday year
%**

int : current_year = 2025;

% Parameters
var 0..2 : la;
var 0..9 : lb;
var 0..9 : lc;
var 0..9 : ld;

% Decisions variables
array[1..4] of var 0..9 : digits = [la, lb, lc, ld];

% Constraints
constraint current_year - (la + lb + lc + ld) = (1000*la + 100*lb + 10*lc + ld);
constraint (la + lb + lc + ld) <= 100;

solve satisfy;