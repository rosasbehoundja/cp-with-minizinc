% ----------
% An autobiographical number is a number N such that the first digit of N counts how many zeroes are in N,
% the second digit counts how many ones are in N and so on. In our example, 1210 has 1 zero, 2 ones, 1 two 
% and 0 threes.
%
% @author: Rosas Behoundja
% @doc: https://blog.tanyakhovanova.com/2007/12/autobiographical-numbers/
% @date: 08.06.2026
% ----------

include "globals.mzn";

% parameters
int : n; % number of digits of N

% decision variables
array[1..n] of var 0..9: digits;

% constraints

% By definition, the autobiographies can’t have more than 10 digits and less than 4 digits.
constraint n >= 4;
constraint n <= 10;

% The sum of the digits in an autobiography equals the number of the digits.
constraint sum(digits) = n;
constraint sum(i in 1..n)(digits[i] * (i - 1)) = n;

% Main constraint
constraint forall(i in 1..n) (
    digits[i] = sum(j in 1..n)(bool2int(digits[j] = i - 1))
);
                
solve satisfy;

output [show(digits)];