classdef mp_idx_manager < handle
%MP_IDX_MANAGER  MATPOWER Index Manager abstract class
%
%   A MATPOWER Index Manager object can be used to manage the indexing of
%   various named and indexed blocks of various set types, such as variables,
%   constraints, etc. This class helps keep track of the ordering and
%   indexing of the various blocks as they are added to the object.
%
%   The types of named sets to be managed by the class are defined by the
%   DEF_SET_TYPES method, which assigns a struct to the 'set_types' field.
%
%   E.g.
%       function obj = def_set_types(obj)
%           obj.set_types = struct(...
%                   'var', 'variable', ...
%                   'lin', 'linear constraint' ...
%               );
%       end
%
%   The INIT_SET_TYPES method initializes the structures needed to track
%   the ordering and  indexing of each set type and can be overridden to
%   initialize any additional data to be stored with each block of each
%   set type.


%       init_indexed_name
%
%   Return the number of elements of any given set type, optionally for a
%   single named block:
%       getN
%
%   Return index structure for each set type:
%       get_idx
%
%   Retreive user data in the model object:
%       get_userdata
%
%   Display the object (called automatically when you omit the semicolon
%   at the command-line):
%       display
%
%   Return the value of an individual field:
%       get
%
%   Indentify variable, constraint or cost row indices:
%       describe_idx
%
%   The following is the structure of the data in the OPF model object.
%   Each field of .idx or .data is a struct whose field names are the names
%   of the corresponding blocks of vars, constraints or costs (found in
%   order in the corresponding .order field). The description next to these
%   fields gives the meaning of the value for each named sub-field.
%   E.g. om.var.data.v0.Pg contains a vector of initial values for the 'Pg'
%   block of variables.
%
%   om
%       .var        - data for optimization variable sets that make up
%                     the full optimization variable x
%           .idx
%               .i1 - starting index within x
%               .iN - ending index within x
%               .N  - number of elements in this variable set
%           .N      - total number of elements in x
%           .NS     - number of variable sets or named blocks
%           .data   - bounds and initial value data
%           .order  - struct array of names/indices for variable
%                     blocks in the order they appear in x
%               .name   - name of the block, e.g. Pg
%               .idx    - indices for name, {2,3} => Pg(2,3)
%       .userdata   - any user defined data
%           .(user defined fields)

%   MATPOWER
%   Copyright (c) 2008-2020, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://matpower.org for more info.

%    es = struct();

    properties
        userdata = [];
        set_types = [];
    end     %% properties
    
    methods
        %% constructor
        function om = mp_idx_manager(s)
            if nargin > 0
                if isa(s, 'mp_idx_manager')
                    %% this copy constructor will not be inheritable under
                    %% Octave until the fix has been included for:
                    %%      https://savannah.gnu.org/bugs/?52614
                    if have_fcn('octave')
                        s1 = warning('query', 'Octave:classdef-to-struct');
                        warning('off', 'Octave:classdef-to-struct');
                    end
                    props = fieldnames(s);
                    if have_fcn('octave')
                        warning(s1.state, 'Octave:classdef-to-struct');
                    end
                    for k = 1:length(props)
                        om.(props{k}) = s.(props{k});
                    end
                elseif isstruct(s)
                    props = fieldnames(om);
                    for k = 1:length(props)
                        if isfield(s, props{k})
                            om.(props{k}) = s.(props{k});
                        end
                    end
                else
                    error('@opt_model/opt_model: input must be a ''opt_model'' object or a struct');
                end
            end
            
            om.def_set_types();
%             if isempty(om.????) %% skip if constructed from existing object
%                 om.init_set_types();%% Octave 5.2 requires this be called from
%                                     %% be called from the sub-class
%                                     %% constructor, since it alters fields of
%                                     %% an object not yet fully constructed.
%                                     %% Since been fixed:
%                                     %%   https://savannah.gnu.org/bugs/?52614
%             end
        end

        function om = init_set_types(om)
            %% base data struct for each type
            ds = struct( ...
                'idx', struct( ...
                    'i1', struct(), ...
                    'iN', struct(), ...
                    'N', struct() ), ...
                'N', 0, ...
                'NS', 0, ...
                'order', struct( ...
                    'name', [], ...
                    'idx', [] ), ...
                'data', struct() );

            %% initialize each (set_type) field with base data structure
            for f = fieldnames(om.set_types)'
                om.(f{1}) = ds;
            end
        end

        function new_om = copy(om)
            %% make shallow copy of object
            new_om = eval(class(om));  %% create new object
            if have_fcn('octave')
                s1 = warning('query', 'Octave:classdef-to-struct');
                warning('off', 'Octave:classdef-to-struct');
            end
            props = fieldnames(om);
            if have_fcn('octave')
                warning(s1.state, 'Octave:classdef-to-struct');
            end
            for k = 1:length(props)
                new_om.(props{k}) = om.(props{k});
            end
        end

        function display_set(om, stype, sname)
            if nargin < 3
                sname = stype;
            end
            st = om.(stype);    %% data for set type of interest
            if st.NS
                fmt = '%-26s %6s %8s %8s %8s\n';
                fprintf(fmt, sname, 'name', 'i1', 'iN', 'N');
                fprintf(fmt, repmat('=', 1, length(sname)), '------', '-----', '-----', '------');
                idx = st.idx;
                fmt = '%10d:%22s %8d %8d %8d\n';
                for k = 1:st.NS
                    name = st.order(k).name;
                    if isempty(st.order(k).idx)
                        fprintf(fmt, k, name, idx.i1.(name), idx.iN.(name), idx.N.(name));
                    else
                        vsidx = st.order(k).idx;
                        str = '%d'; for m = 2:length(vsidx), str = [str ',%d']; end
                        s = substruct('.', name, '()', vsidx);
                        nname = sprintf(['%s(' str, ')'], name, vsidx{:});
                        fprintf(fmt, k, nname, ...
                                subsref(idx.i1, s), subsref(idx.iN, s), subsref(idx.N, s));
                    end
                end
                fmt = sprintf('%%10d = %%s.NS%%%dd = %%s.N\\n\\n', 35-length(stype));
                fprintf(fmt, st.NS, stype, st.N, stype);
            else
                fprintf('%-26s  :  <none>\n', sname);
            end
        end
    end     %% methods
end         %% classdef