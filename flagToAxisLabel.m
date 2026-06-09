function out = flagToAxisLabel(xflag)
%FLAGTONAME Summary of this function goes here
%   Detailed explanation goes here
switch xflag
    case 1
        out = "q (A^{-1})";
    case 2
        out = "\Phi (degree)";
    case 3
        out = "q_z (A^{-1})";
    case 4
        out = "q_x (A^{-1})";
    case 5
        out = "q_y (A^{-1})";
    case 6
        out = "q_r (A^{-1})";
    case 7
        out = "2\Theta (degree)";
    case 8
        out = "\alpha_f (degree)";
    case 9
        out = "\Chi (degree)";
    case 10
        out = "x pixel";
    case 11
        out = "y pixel";
end
end

