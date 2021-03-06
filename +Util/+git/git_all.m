function git_all(varargin)
% add and commit the entire directory structure to github
% Package: Util.git
% Description: 
% Input  : - 
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
% Output : - 
% License: GNU general public license version 3
%     By : Eran O. Ofek                    Mar 2017
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: Util.git.git_all
% Reliable: 
%--------------------------------------------------------------------------


DefV.BasePath             = {'~/matlab/fun/'};
DefV.ExtType              = {'m','mlx'};
DefV.Comment              = '';
DefV.Server               = 'https://github.com/EranOfek/try';
DefV.IsPushMaster         = true;
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

PWD = pwd;

Nbase = numel(InPar.BasePath);
Next  = numel(InPar.ExtType);
for Ibase=1:1:Nbase
    cd(InPar.BasePath{Ibase});
    for Iext=1:1:Next
        Dir = Util.IO.rdir(sprintf('*.%s',InPar.ExtType{Iext}));
        Nfiles = numel(Dir);
        for Ifiles=1:1:Nfiles
            Dir(Ifiles).folder
            Dir(Ifiles).name
            cd(Dir(Ifiles).folder);
            Str = sprintf('git add %s',Dir(Ifiles).name);
            system(Str);
        end
    end
end

% % add server
% Str = sprintf('git remote add orgin %s',InPar.Server);
% system(Str);
% 
% % commit
% Str = sprintf('git commit -m "%s"',InPar.Comment);
% system(Str);
% Str = sprintf('git commit -a');
% system(Str);
% 
% if (InPar.IsPush)
%     Str = sprintf('git push origin master');
%     system(Str);
% end

cd(PWD);
