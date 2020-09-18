function [TorF, vstr, rdate] = have_feature_opti_clp()
%HAVE_FEATURE_OPTI_CLP  Detect availability/version info for OPTI_CLP
%
%   Used by HAVE_FEATURE.

%   MP-Opt-Model
%   Copyright (c) 2004-2020, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MP-Opt-Model.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mp-opt-model for more info.

TorF = exist('opti_clp', 'file') == 2 && exist('clp', 'file') == 3;
vstr = '';
rdate = '';
if TorF
    str = evalc('clp');
    pat = 'CLP: COIN-OR Linear Programming \[v([^\s,]+), Built ([^\],])+(,[^\]]*)*\]';  %% OPTI, Giorgetti/Currie
    [s,e,tE,m,t] = regexp(str, pat);
    if ~isempty(t)
        vstr = t{1}{1};
        rdate = datestr(t{1}{2}, 'dd-mmm-yyyy');
    end
end
