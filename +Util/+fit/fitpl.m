function Res=fitpl(X,Y,Err,varargin)
%--------------------------------------------------------------------------
% fitpl function                                                    FitFun
% Description: Given a data [X,Y], Fit a power-law of the form
%              Y=A*(X+X0)^alpha. Where X0>0.
% Input  : - Vector of X.
%          - Vector of Y.
%          - Vector of error in Y. If scalar than will use this error
%            for all measurments. Default is 1.
%          * Arbitrary number of pairs of input arguments: ...,key,val,...
%            The following keywords are available:
%            'Option'    - A cell array of key,val to pass to optimset.
%                          Default is {'MaxIter',1000,'MaxFunEvals',1000,'TolX',1e-5,'TolFun',1e-5}
%            'GuessPar'  - Best guess for initial value of parameters
%                          [A, X0, alpha]. Default is [1 0 1].
%            'SetPar'    - A three element vector, of 1 or 0, that specify
%                          if each one of the free parameters A, X0, alpha
%                          will be set to a constant and will not be
%                          allowed to be changed. If the value is 1 then
%                          the parameter will be set as a free parameter.
%                          If the value is 0, then not a free parameter,
%                          and the value of the parameter will be obtained
%                          from the 'GuessPar' vector.
%                          Default is [1 1 1].
%            'Method'    - Sigma clipping method. See clip_resid.m for
%                          options. Default is 'StD.
%            'Mean'      - Sigma clipping mean method. See clip_resid.m for
%                          options. Default is 'Median'.
%            'Clip'      - Sigma clipping lower/upper clip values. See
%                          clip_resid.m for options. Default is empty
%                          matrix (i.e., no rejection).
%            'StdZ'      - Sigma clipping add epsilon parameter. Default
%                          is 'y'.
% Output : -
% Tested : Matlab 2011b
%     By : Eran O. Ofek                    Apr 2013
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: X = [1:1:100]'; Y = 5.*(X+13).^1.37+randn(size(X)).*0.01;
%          Res=fitpl(X,Y,0.01)
%          X = [1:1:100]'; Y = 2.*X.^1.5+randn(size(X)).*0.01;
%          Res=fitpl(X,Y,0.01,'SetPar',[1 0 1]);
%--------------------------------------------------------------------------

Def.Err = 1;
if (nargin==2),
    Err = Def.Err;
end

DefV.Option   = {'MaxIter',1000,'MaxFunEvals',1000,'TolX',1e-5,'TolFun',1e-5};
DefV.GuessPar = [1 0 1];
DefV.SetPar   = [1 1 1];
DefV.Method   = 'StD';
DefV.Mean     = 'Median';
DefV.Clip     = [];
DefV.StdZ     = 'y';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

Nm  = length(X);  % number of measurments
if (length(Err)==1),
    Err = Err.*ones(size(Nm));
end

Flag = InPar.SetPar;
ConstPar = InPar.GuessPar.*not(Flag);
Options = optimset(InPar.Option{:});
Chi2pl = @(Par) sum(( (Y - (Par(1).*Flag(1)+ConstPar(1)) .*(X+abs( Par(2).*Flag(2)+ConstPar(2) ) ).^( Par(3).*Flag(3)+ConstPar(3) ) )./Err).^2);

Res.Par     = fminsearch(Chi2pl,InPar.GuessPar,Options);
%Res.Par     = fminunc(Chi2pl,InPar.GuessPar,Options);

Res.Par(2)  = abs(Res.Par(2));
Res.Chi2    = Chi2pl(Res.Par);
H           = Util.fit.calc_hessian(Chi2pl,Res.Par,0.1.*ones(size(Res.Par)));
Res.Cov     = inv(0.5.*H);
Res.ParErr  = sqrt(diag(inv(0.5.*H)));
Res.Resid   = Y - Res.Par(1).*(X+Res.Par(2)).^(Res.Par(3));

    % A nested function
    %function [Chi2,Resid]=Chi2pl(Par)
    %    Resid = Y - Par(1).*(X-Par(2)).^Par(3);
    %    Chi2  = sum((Resid./Err).^2);
    %end    
   
end
