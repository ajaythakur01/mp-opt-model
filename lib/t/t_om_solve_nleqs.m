function t_om_solve_nleqs(quiet)
%T_OM_SOLVE_NLEQS  Tests of NLEQ solvers via OM.SOLVE().

%   MP-Opt-Model
%   Copyright (c) 2010-2020, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MP-Opt-Model.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mp-opt-model for more info.

if nargin < 1
    quiet = 0;
end

if have_fcn('matlab')
    %%  alg         name        check       opts
    cfg = {
        {'DEFAULT', 'default',  []          []  },
        {'NEWTON',  'Newton',   [],         []  },
        {'FSOLVE',  'fsolve-1', 'fsolve',   []  },
        {'FSOLVE',  'fsolve-2', 'fsolve',   struct('Algorithm', 'trust-region-dogleg')  },
        {'FSOLVE',  'fsolve-3', 'fsolve',   struct('Algorithm', 'trust-region-reflective')  },
        {'FSOLVE',  'fsolve-4', 'fsolve',   struct('Algorithm', 'levenberg-marquardt')      },
    };
else    %% octave
    %%  alg         name        check       opts
    cfg = {
        {'DEFAULT', 'default',  []          []  },
        {'NEWTON',  'Newton',   [],         []  },
        {'FSOLVE',  'fsolve', 'fsolve',   []  },
    };
end

n = 5;

t_begin(n*length(cfg), quiet);

for k = 1:length(cfg)
    alg   = cfg{k}{1};
    name  = cfg{k}{2};
    check = cfg{k}{3};
    opts  = cfg{k}{4};
    if ~isempty(check) && ~have_fcn(check)
        t_skip(n, sprintf('%s not installed', name));
    else
        opt = struct('verbose', 0, 'alg', alg, 'tol', 1e-10);
        switch alg
            case {'DEFAULT', 'NEWTON'}
            case 'FSOLVE'
                opt.fsolve_opt = opts;
        end

t = sprintf('%s - 2-d function : ', name);
x0 = [-1;0];
om = opt_model;
om.add_var('x', 2, x0);
om.add_nln_constraint('f', 2, 1, @f1, []);
[x, f, e, out, J] = om.solve(opt);
t_is(e, 1, 12, [t 'success']);
t_is(x, [-3; 4], 8, [t 'x']);
t_is(f, 0, 10, [t 'f']);

t = sprintf('%s - 2-d function (max_it) : ', name);
opt.max_it = 3;
[x, f, e, out] = om.solve(opt);
t_is(e, 0, 12, [t 'no success']);
t_ok(out.iterations == 3 || out.iterations == 4, [t 'iterations']);

    end
end

t_end;


%% 2-d problem with 2 solutions
%% from https://www.chilimath.com/lessons/advanced-algebra/systems-non-linear-equations/
function [f, J] = f1(x)
f = [  x(1)   + x(2) - 1;
      -x(1)^2 + x(2) + 5    ];
if nargout > 1
    J = [1 1; -2*x(1) 1];
end
