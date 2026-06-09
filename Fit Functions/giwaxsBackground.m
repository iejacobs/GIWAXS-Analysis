function [bkg,expbkg,plbkg] = giwaxsBackground(x,b1,l,b2,k)
%GIWAXSBACKGROUND Exponential plus power law background for GIWAXS linecut
%fits
expbkg = b1.*exp(-x/l);
plbkg = b2.*x.^k;
bkg = expbkg + plbkg;
end

