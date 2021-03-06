function [Res,SpecBB]=fit_bb(Spec,varargin)
%--------------------------------------------------------------------------
% fit_bb function                                                AstroSpec
% Description: Fit a black body spectrum to a list of spectral measurments,
%              spectrum or photometric measurments.
% Input  : - The spectral points to fit [Wavelength, Flux, [Err]].
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
%            'BadRanges' - Two column matrix of bad ranges to remove from
%                          spectrum before fitting. Line per bad range.
%                          This can be used to mask lines.
%                          Default is [].
%            'WaveUnits' - Wavelength units. Default is 'Ang'.
%                          See convert.units.m for options.
%            'IntUnits'  - Flux units. Default is 'erg*cm^-2*s^-1*Ang^-1'.
%                          See convert.flux.m for options.
%                          E.g., 'AB', 'STmag','mJy','ph/A',...
%            'Trange'    - Temperature range [K] in which to search for
%                          solution. Default is [500 5e6].
%            'Tpoint'    - Number of points in each search range.
%                          Default is 5.
%            'Thresh'    - Convergence threshold. Default is 0.001;
%            'ColW'      - Column index in spectrum input containing
%                          the wavelength. Default is 1.
%            'ColF'      - Column index in spectrum input containing
%                          the flux. Default is 2.
%            'ColE'      - Column index in spectrum input containing
%                          the error in flux. Default is 3.
%            'FitFun'    - Function for ratio calculation in initial
%                          iterative search. Default is @mean.
%            'Nsigma'    - Return the errors for Nsigma confidence
%                          interval. Default is 1.
%            'Wave'      - Vector of wavelength in which to calculate
%                          the best fit black-body spectrum.
%                          If empty then do not return the best fit
%                          spectrum. If 'same' then use the wavelength
%                          of the input spectrum.
%                          Wavelength in the same units as WaveUnits.
%                          Default is 'same'.
% Output : - A structure containing the best fit black body results.
%          - AstSpec class object containing the calculated best fit
%            black-body spectrum.
% License: GNU general public license version 3
% Tested : Matlab R2015b
%     By : Eran O. Ofek                    Feb 2016
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: [Res,SpecBB]=fit_bb([AS(1).Wave,AS(1).Int]);
%          plot(AS(1)); hold on; plot(SpecBB);
% Reliable: 2
%--------------------------------------------------------------------------

RAD = 180./pi;

DefV.BadRanges          = [];
DefV.WaveUnits          = 'Ang'; 
DefV.IntUnits           = 'erg*cm^-2*s^-1*Ang^-1';
DefV.Trange             = [500 5e6];
DefV.Tpoint             = 5;
DefV.Thresh             = 0.01;

DefV.ColW               = 1;
DefV.ColF               = 2;
DefV.ColE               = 3;
DefV.FitFun             = @mean;  % @median
DefV.Nsigma             = 1;      % number of sigmas for error calculation
DefV.Wave               = 'same';
%InPar = set_varargin_keyval(DefV,'n','use',varargin{:});
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


% check if Spec contains Errors - if not add equal weights
Nw  = size(Spec,1);
if (size(Spec,2)==2)
    Spec = [Spec, ones(Nw,1)];
end

% remove bad ranges
IndBad = Util.array.find_ranges(Spec(:,InPar.ColW),InPar.BadRanges);
Spec(IndBad,2) = NaN;
Spec = Spec(~isnan(Spec(:,2)),:);
Nw   = size(Spec,1);
Npar = 2;
Ndof = Nw - Npar;


switch lower(InPar.IntUnits)
    case {'erg*cm^-2*s^-1*ang^-1','cgs/a'}
        FluxUnits = 'cgs/A';
    case {'erg*cm^-2*s^-1*hz^-1','cgs/hz'}
        FluxUnits = 'cgs/Hz';
    case {'phot*cm^-2*s^-1*ang^-1','ph/a'}
        FluxUnits = 'ph/A';
    case {'phot*cm^-2*s^-1*hz^-1','ph/hz'}
        FluxUnits = 'ph/Hz';
    case 'mjy'
        FluxUnits = 'mJy';
    case 'ab'
        FluxUnits = 'AB';
    case 'stmag'
        FluxUnits = 'STmag';
    otherwise
        error('Unknown FluxUnits option');
end
        

WaveAng = convert.units(lower(InPar.WaveUnits),'ang').*Spec(:,InPar.ColW);

Cont = true;
VecChi2 = zeros(InPar.Tpoint,1);
Trange  = logspace(log10(InPar.Trange(1).*0.5),log10(InPar.Trange(2).*2),InPar.Tpoint).';
Iter    = 0;
while Cont
    % calculate chi^2 as a function of T in some range
    % this is required for robustness
    Iter = Iter + 1;
    for It=1:1:InPar.Tpoint
        %[~,~,BB_flam] = black_body(Trange(It),WaveAng);
        BB_flam = AstSpec.blackbody(Trange(It),WaveAng,'cgs/A');
        BB = convert.flux(BB_flam.Int,'cgs/A',FluxUnits,Spec(:,InPar.ColW),InPar.WaveUnits);
        Ratio = InPar.FitFun(Spec(:,InPar.ColF)./BB);
        Resid = Spec(:,2) - Ratio.*BB;
        VecChi2(It)  = sum((Resid./Spec(:,InPar.ColE)).^2);
    end
    
    TrangeRatio = Trange(2)./Trange(1);
    [~,MinInd] = min(VecChi2);
    BestT      = Trange(MinInd);
    TrangeOld  = Trange;
    Trange     = logspace(log10(BestT./TrangeRatio),log10(BestT.*TrangeRatio),InPar.Tpoint).';
    
    Cont = (TrangeRatio-1)>InPar.Thresh;
end
Chi2      = min(VecChi2);
NormErr   = Spec(:,InPar.ColE).*sqrt(Chi2./Ndof);

% final fit
Trange = TrangeOld;
Trange = [Trange(1).*[0.9;0.95]; Trange; Trange(end).*[1.05;1.1]];
for It=1:1:InPar.Tpoint+4
    %[~,~,BB_flam] = black_body(Trange(It),WaveAng);
    BB_flam = AstSpec.blackbody(Trange(It),WaveAng,'cgs/A');
    BB = convert.flux(BB_flam.Int,'cgs/A',FluxUnits,Spec(:,InPar.ColW),InPar.WaveUnits);
    %Ratio = InPar.FitFun(Spec(:,InPar.ColF)./BB);
    [Ratio,RatioErr] = lscov(BB,Spec(:,InPar.ColF),1./(NormErr.^2));
    Resid = Spec(:,2) - Ratio.*BB;
    VecChi2(It)  = sum((Resid./NormErr).^2);
end
[~,MinInd] = min(VecChi2);
BestT      = Trange(MinInd);

Res.BestT = BestT;
Res.Chi2  = Chi2;
Res.Ndof  = Ndof;
Res.Npar  = Npar;

% fit parabola to estimate errors
ProbSigma = 1-(1-normcdf(InPar.Nsigma,0,1)).*2;
Par = polyfit(Trange,VecChi2,2);
Par1 = Par;
Par1(3) = Par1(3) - Ndof - chi2cdf(ProbSigma,Npar);
Troots  = roots(Par1);

Res.Terr  = [BestT-min(Troots), max(Troots)-BestT];

% calculate radius / angular radius
Res.Ratio     = Ratio;
Res.RatioErr  = RatioErr;
Res.AngRad    = sqrt(Ratio).*RAD.*3600;   % [arcsec]
Res.AngRadErr = RatioErr./(2.*sqrt(Ratio)).*RAD.*3600.*InPar.Nsigma; % [arcsec]


if (nargout>1)
    if (ischar(InPar.Wave))
        if (strcmpi(InPar.Wave,'same'))
            InPar.Wave = Spec(:,InPar.ColW);
        else
            error('Unknown Wave option');
        end
    end
    
    WaveAng = convert.units(lower(InPar.WaveUnits),'ang').*InPar.Wave;
    %[~,~,BB_flam] = black_body(Trange(It),WaveAng);
    BB_flam = AstSpec.blackbody(Trange(It),WaveAng,'cgs/A');
    BB = convert.flux(BB_flam.Int,'cgs/A',FluxUnits,Spec(:,InPar.ColW),InPar.WaveUnits);
    
    
    SpecBB               = AstSpec;
    SpecBB.Wave          = InPar.Wave;
    SpecBB.Int           = Ratio.*BB;
    SpecBB.WaveUnits     = InPar.WaveUnits;
    SpecBB.IntUnits      = InPar.IntUnits;
    SpecBB.source        = 'black_body.m';
    SpecBB.z             = 0;
end


    
    


