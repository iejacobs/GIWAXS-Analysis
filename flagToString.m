function out = flagToString(xflag)
%FLAGTONAME Summary of this function goes here
%   Detailed explanation goes here
switch xflag
    case 1
        out = "q";
    case 2
        out = "Phi";
    case 3
        out = "q_z";
    case 4
        out = "q_x";
    case 5
        out = "q_y";
    case 6
        out = "q_r";
    case 7
        out = "2Theta";
    case 8
        out = "Alpha_f";
    case 9
        out = "Chi";
    case 10
        out = "x pixel";
    case 11
        out = "y pixel";
end
end

