function [InAstC]=coo_inimage(Sim,Coo,varargin)
%--------------------------------------------------------------------------
% coo_inimage function                                          class/@SIM
% Description: Given a SIM images and a list of coordinates. Check if each
%              coordinate is contained within the images boundries.
%              Also calculate the distance of each point to the image edge.
% Input  : - A SIM object of images. The SIM is used for the WCS in the
%            image headers.
%          - Either a two column matrix of coordinates,
%            or an AstCat object with coordinates.
%            If multiple AstCat objects are supplied than each object will
%            be compared with each SIM image.
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
%            'ColNames' - Column names in the input catalog (second input
%                         argument) containing the RA/Dec or X/Y columns.
%                         Default is {'RA','Dec'}.
%            'ColUnits' - Units of columns in catalog. Default is 'rad'.
%            'CooType'  - Catalog coordinates type 'plane'|'sphere'.
%                         Default is 'sphere'.
% Output : - An AstCat object (catalog per SIM element) with a catalog
%            with 4 columns [Flag, DistEdge, DistCenter, PACenter].
%            One row, per row in the input catalog.
%            Flag is 1 if coordinate is within image, otherwise 0.
% License: GNU general public license version 3
% Tested : Matlab R2015b
%     By : Eran O. Ofek                    Mar 2016
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: In=coo_imimage(Sim,[167 34]./RAD);
% Reliable: 2
%--------------------------------------------------------------------------

ImageField         = 'Im';
CatField           = 'Cat';


DefV.ColNames          = {'RA','Dec'};
DefV.ColUnits          = 'rad';
DefV.CooType           = 'sphere';  % 'sphere' | 'plane'
%InPar = set_varargin_keyval(DefV,'n','use',varargin{:});
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


Nsim = numel(Sim);
if (~AstCat.isastcat(Coo))
    % convert Coo matrix to AstCat
    AstC            = AstCat;
    AstC.(CatField) = Coo;
    InPar.ColNames  = DefV.ColNames;
    AstC.ColCell    = InPar.ColNames;
    AstC            = colcell2col(AstC);
else
    AstC = Coo;
end
Ncat = numel(AstC);


if ~(Ncat==1 || Ncat==Nsim)
    error('Number of elements in catalog must be 1 or like SIM size');
end

InAstC = AstCat(size(Sim));
for Isim=1:1:Nsim
    Icat = min(Isim,Ncat);
    
    ColInd = colname2ind(AstC(Icat),InPar.ColNames);
    
    SizeIm = size(Sim(Isim).(ImageField));
    % compare Sim(Isim) with AstC(Icat)
    switch lower(InPar.CooType)
        case 'plane'
            % Coo is in planar coordinates
            XY = AstC(Icat).(CatField)(:,ColInd);
           
        case 'sphere'
            % Coo is in spherical coordinates
            
            % Convert [RA,Dec] to pixel coordinates
            if (isempty(InPar.ColUnits))
                ColUnits = AstC(Icat).ColUnits{ColInd(1)};
            else
                ColUnits = InPar.ColUnits;
            end
            if (iscell(ColUnits))
                ColUnits = ColUnits{1};
            end
            ConvFactor = convert.angular(ColUnits,'rad');
            if (isempty(AstC(Icat).(CatField)))
                XY = zeros(0,2);
            else
                [X,Y] = coo2xy(Sim(Isim),...
                               AstC(Icat).(CatField)(:,ColInd(1)).*ConvFactor,...
                               AstC(Icat).(CatField)(:,ColInd(2)).*ConvFactor);
                XY = [X,Y];
            end
        otherwise
            error('Unknown CooType option');
    end
    
                        
    % Flag indicating if coordinate is within image boundries
    Flag = XY(:,1) >= 1         & ...
           XY(:,1) <= SizeIm(2) & ...
           XY(:,2) >= 1         & ...
           XY(:,2) <= SizeIm(1);

    % Dist of coordinates from image center [pix]
    [Dist,PA] = Util.Geom.plane_dist(SizeIm(2).*0.5, SizeIm(1).*0.5, ...
                           XY(:,1), XY(:,2));

    % Minimum distance of coordinates from image edge [pix]
    DistEdge = min([abs(XY(:,1)-1),...
                    abs(XY(:,1)-SizeIm(2)),...
                    abs(XY(:,2)-1),...
                    abs(XY(:,2)-SizeIm(1))],[],2);


    InAstC(Isim).(CatField) = [Flag, DistEdge, Dist, PA];
    InAstC(Isim).ColCell    = {'InImageFlag','DistEdge','DistCenter','PACenter'};
    InAstC(Isim)            = colcell2col(InAstC(Isim));
    InAstC(Isim).ColUnits   = {'','pix','pix','rad'};
    InAstC(Isim).Source     = 'coo_inimage.m';
    
end


    
