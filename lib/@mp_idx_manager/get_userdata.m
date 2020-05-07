function rv = get_userdata(obj, name)
%GET_USERDATA  Used to retrieve values of user data.
%
%   VAL = OBJ.GET_USERDATA(NAME) returns the value specified by the given name
%   or an empty matrix if userdata with NAME does not exist.
%
%   This function allows the user to retrieve any arbitrary data that was
%   saved in the object for later use. Data for a given NAME is saved by
%   assigning it to OBJ.userdata.(NAME).
%
%   This can be useful, for example, when using a user function to add
%   variables or constraints, etc. Suppose some special indexing is
%   constructed when adding some variables or constraints. This indexing data
%   can be stored and used later to "unpack" the results of the solved case.
%
%   See also OPT_MODEL.

%   MP-Opt-Model
%   Copyright (c) 2008-2020, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MP-Opt-Model.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://matpower.org for more info.

if isfield(obj.userdata, name)
    rv = obj.userdata.(name);
else
    rv = [];
end