%**
%*  Cryptarithmetic puzzle
%**

include "alldifferent.mzn";

% Parameters
var 0..9 : A;
var 0..9 : B;
var 0..9 : C;
var 0..9 : D;
var 0..9 : E;

% Decisions variables
array[1..5] of var 0..9 : letters = [A, B, C, D, E];

% Constraints
constraint alldifferent(letters);
constraint A != 0;
constraint E != 0;

% The arithmetic sum ABCDE * 4 = EDCBA
constraint (10000*A + 1000*B + 100*C + 10*D + E) * 4 = (10000*E + 1000*D + 100*C + 10*B + A);
% constraint (39999*A + 3990*B + 300*C - 960*D - 9996*E) = 0;

solve satisfy;

output [
  "  ", show(A), show(B), show(C), show(D), show(E), "\n",
  "x     4\n",
  "-------\n",
  "  ", show(E), show(D), show(C), show(B), show(A)
];