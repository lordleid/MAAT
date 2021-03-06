function [IsFlat,Res]=isflat(Sim,varargin)
%--------------------------------------------------------------------------
% isflat function                                              class/@HEAD
% Description: Check if HEAD/SIM objects are flat images.
%              The program can look for flat images in a set of SIM or HEAD
%              objects, using header keyword or/and file name. It also
%              check if the images are not saturated, and if the images
%              are similar (in difference or ratio) to a template image.
% Input  : - An HEAD object or a SIM object. For HEAD objects can look
%            for flat images only based on header keywords.
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
%            'TypeKeyVal' - The value of the IMTYPE like keyword in
%                           the header in case of a flat image.
%                           Either a string or a cell array of strings
%                           (i.e., multiple options).
%                           Default is {'flat','flats','Flat','FLAT','DomeFlat','SkyFlat'}.
%            'TypeKeyDic' - IMTYPE keyword names. If empty use the istype.m
%                           default which is:
%                           {'TYPE','IMTYPE','OBSTYPE','IMGTYP','IMGTYPE'}.
%                           Default is empty.
%            'FileNameStr'- Optional search for flat images based on file
%                           name. This is a substring that if contained
%                           in the file name then the image is a flat.
%                           If empty then do not use this option.
%                           Default is empty.
%            'SatLevel'   - Detector saturation level above which flat
%                           images are declared to be bad.
%                           This is either a numberic value or a string
%                           or a cell array of string of header keyword
%                           names containing the saturation level.
%                           Default is {'SATURAT','SATLEVEL'}.
%                           If keyword is not found then set saturation
%                           level to Inf. If empty then ignore saturation.
%            'StdFun'     - Function to use for the calculation of the
%                           global std of a SIM object {@std | @rstd}.
%                           Default is @rstd (slower than @std).
%            'Template'   - A matrix or a SIM image containing a template
%                           image which will be compared with each input
%                           image.
%                           If empty then do not use template search.
%                           Default is empty.
%            'TemplateType'- The comparison with the template can either
%                           done by difference ('diff') or by ratio
%                           ('ratio'). Default is 'ratio'.
%            'TemplateNoise'- The image is a possible flat image if the
%                           global std of the comparison with the template
%                           is smaller than this value (in the native units
%                           of the image). Default is 3000.
%            'CombType'   - The function tha will be used to combine all
%                           the flat search criteria {@all|@any}.
%                           Default is @all (i.e., requires that all the
%                           criteria are fullfilled).
%                           However, only active searches are being
%                           combined. For example, if 'Template' is empty
%                           then its results (false) will not be combined.
%            'SelectMethod'- Method by which to select the best keyword
%                           value. See getkey_fromlist.m for details.
%                           Default is 'first'.
% Output : - A vector of logical flags indicating if each image is a
%            candidate flat image, based on the combined criteria.
%          - A structure array with additional information.
%            The following fields are available:
%            .IsFlatKey - IsFlat based on IMTYPE header keyword
%            .IsFlatFN  - IsFlat based on file name.
%            .IsFlatNotSat - IsFlat based on non saturated images.
%            .IsFlatTempStd - IsFlat based on comparison with template.
% License: GNU general public license version 3
% Tested : Matlab R2015b
%     By : Eran O. Ofek                    Apr 2016
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: [IsFlat,R]=isflat(S);
% Reliable: 2
%--------------------------------------------------------------------------


ImageField         = 'Im';
ImageFileNameField = 'ImageFileName';


DefV.TypeKeyVal         = {'flat','flats','Flat','FLAT','DomeFlat','SkyFlat','domeflat','FLATFIELD'};
DefV.TypeKeyDic         = [];    % if empty use istype default.
DefV.FileNameStr        = [];    % e.g.., 'Flat' - if empty do not use file name
%DefV.RN                 = {'READNOI','READNOIS','RON'};  % if empty do not use   % [e-]
%DefV.Nrn                = 2;
DefV.StdFun             = @rstd;
% DefV.GAIN               = {'GAIN'};
% DefV.DefGAIN            = 1;
DefV.SatLevel           = {'SATURAT','SATLEVEL'};
DefV.Template           = [];    % either SIM or a matrix
DefV.TemplateType       = 'ratio';
DefV.TemplateNoise      = 3000;     % [ADU or ratio]
DefV.CombType           = @all;   % @all | @any
DefV.SelectMethod       = 'first';
if (numel(varargin)>0)
    %InPar = set_varargin_keyval(DefV,'n','use',varargin{:});
    InPar = InArg.populate_keyval(DefV,varargin,mfilename);
else
    InPar = DefV;
end



if (~isempty(InPar.Template))
    if (isnumeric(InPar.Template))
        Template = SIM;
        Template.(ImageField) = InPar.Template;
    elseif (SIM.issim(InPar.Template))
        Template = InPar.Template;
    else
        error('Unknown Template format');
    end
end

% treat the input in case its an HEAD object
% Select flat images based on image TYPE keywords
IsFlatKey = istype(Sim,InPar.TypeKeyVal,InPar.TypeKeyDic);
IsFlat    = IsFlatKey;

% treat the input in case its a SIM object
IsFlatFN      = false(numel(IsFlat),1);
IsFlatNotSat  = false(numel(IsFlat),1);
IsFlatTempStd = false(numel(IsFlat),1);
if (SIM.issim(Sim))
    % select flat images based on file name
    if (~isempty(InPar.FileNameStr))
        % do not use file name
        IsFlatFN = ~Util.cell.isempty_cell(strfind({Sim.(ImageFileNameField)}.',InPar.FileNameStr));
        
        IsFlat   = InPar.CombType([IsFlat,IsFlatFN],2);
    end
    
    % select non saturated images
    if (~isempty(InPar.SatLevel))
        % get saturation level
        SatLevel = cell2mat(getkey_fromlist(Sim,InPar.SatLevel,InPar.SelectMethod));
        if (any(isnan(SatLevel)))
            warning('Some/all of the Saturation levels are NaN - set NaN to Inf');
            SatLevel(isnan(SatLevel)) = Inf;
        end
        %MaxVal = max(Sim);
        %if it takes the max then all the images appear to be saturated because of some pixels.
        MaxVal = nanmedian(Sim); % Na'ama, 20180515
        
        IsFlatNotSat = MaxVal(:) < SatLevel;
        
        IsFlat   = InPar.CombType([IsFlat,IsFlatNotSat],2); 
    end
    
    % select images based on similarity to template
    if (~isempty(InPar.Template))
        switch lower(InPar.TemplateType)
            case 'diff'
                StdTempResid   = InPar.StdFun(Sim - Template);
            case 'ratio'
                StdTempResid   = InPar.StdFun(Sim./Template);
            otherwise
                error('Unknown TemplateType option');
        end
        IsFlatTempStd  = StdTempResid<InPar.TemplateNoise;
        
        IsFlat   = InPar.CombType([IsFlat,IsFlatTempStd],2); 
    end
        
end


Res.IsFlatKey     = IsFlatKey;
Res.IsFlatFN      = IsFlatFN;
Res.IsFlatNotSat  = IsFlatNotSat;
Res.IsFlatTempStd = IsFlatTempStd;


