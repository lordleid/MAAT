function [Section,FlagIn,CenterSection]=adaptive_section(ImSizeXY,PosXY,HalfSizeXY,MinDist,varargin)
% SHORT DESCRIPTION HERE
% Package: ImUtil
% Description: 
% Input  : - 
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
% Output : - 
% License: GNU general public license version 3
%     By : Eran O. Ofek                    Jul 2017
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: 
% Reliable: 
%--------------------------------------------------------------------------



DefV.Quantile             = [0.02 0.98];
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

DistFromX1 = PosXY(:,1) - 1;
DistFromX2 = ImSizeXY(:,1) - PosXY(:,1);
DistFromY1 = PosXY(:,2) - 1;
DistFromY2 = ImSizeXY(:,2) - PosXY(:,2);

X1q = round(quantile(DistFromX1,InPar.Quantile(1)));
X2q = round(quantile(DistFromX2,InPar.Quantile(1)));

Y1q = round(quantile(DistFromY1,InPar.Quantile(1)));
Y2q = round(quantile(DistFromY2,InPar.Quantile(1)));

if (X1q>=HalfSizeXY(1) && X2q>=HalfSizeXY(1))
    % no problem for X axis - object in center
    CenterX = HalfSizeXY(1);
    DX(1) = HalfSizeXY(1)+1;
    DX(2) = HalfSizeXY(1);
    
else
    if (X1q<HalfSizeXY(1))
        % shift X center to X1q value
        CenterX = X1q;
        DX(1)   = MinDist; %CenterX;
        DX(2)   = 2.*HalfSizeXY(1)+1-DX(1);
    else
        % shift X center to X2q value
        CenterX = X2q;
        DX(2)   = MinDist; %CenterX;
        DX(1)   = 2.*HalfSizeXY(1)+1-DX(2);
    end
end

if (Y1q>=HalfSizeXY(2) && Y2q>=HalfSizeXY(2))
    % no problem for Y axis - object in center
    CenterY = HalfSizeXY(2)+1;
    DY(1) = HalfSizeXY(2)+1;
    DY(2) = HalfSizeXY(2);
else
    if (Y1q<HalfSizeXY(2))
        % shift Y center to Y1q value
        CenterY = Y1q;
        DY(1)   = max(MinDist,CenterY);
        DY(2)   = 2.*HalfSizeXY(2)+1-DY(1);
    else
        % shift Y center to Y2q value
        CenterY = Y2q;
        DY(2)   = max(MinDist,CenterY);
        DY(1)   = 2.*HalfSizeXY(2)+1-DY(2);
    end
end


Section = [PosXY(:,1)-DX(1), PosXY(:,1)+DX(2), PosXY(:,2)-DY(1), PosXY(:,2)+DY(2)];

FlagIn = Section(:,1)>=1 & Section(:,2)<=ImSizeXY(:,1) & Section(:,3)>=1 & Section(:,4)<=ImSizeXY(:,2);

CenterSection = [CenterX, CenterY];
