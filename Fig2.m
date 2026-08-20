clear;
clc;
close all;


AleDirectory=0;
if AleDirectory==1
    addpath('/Applications/Dynare/7.0-arm64/matlab');
else
    addpath('C:\dynare\7.0\matlab')
end


% -----------------------------
% User choices
% -----------------------------
modname = 'oil_nonlinear_kstickyEPF_export3_sf';
casename  = "Baseline"; % Options: "Baseline", "High Eta_E"

H      = 21;      % quarters to plot
T      = 500;     % PF simulation horizon
printfigs = 1;

% -----------------------------
% Warm-up choices
% -----------------------------
do_warmup = 0;

p_init = 0.0;   % oil level before the main shock.
% p_init = 0.00 gives the original SS case.
% p_init = 0.20 means oil has been around +20%.

T_warm = 300;     % length of warm-up phase
T_warm_return_start = 250;
% far-end return in warm-up, only to keep terminal condition clean.
% The main experiment uses the economy around the high-oil
% region of the warm-up before the artificial return matters.

% Read in empirical oil price data
%wtifutures_change = readtable('./data_created/wtifutures_change.csv');
wtifutures_change = readtable('./data_created/wtifutures_exp_March.csv');

% -----------------------------
% Main oil-shock path
% -----------------------------

p_high = 0.51;    % oil level during high-oil phase: +40%
cases(1).p_perm = 0.0;    % long-run return to SS oil level
cases(2).p_perm = 0.07;    % long-run temporarily elevated oil level: +10%
cases(1).rho_g_path = 0.75;
cases(2).rho_g_path = 0.8;
X_high = 1;       % number of quarters oil stays at +40%
use_exact_futures_path = 1;

% -----------------------------
% Senate-balking option
% -----------------------------
do_senate_balks = 1;


% -----------------------------
% Surprises option
% -----------------------------
do_full_surprises = 1;



% Scenario:
% Q1-Q4 2026: oil price remains at EO March value.
% In Q1, Q2, Q3 agents expect reversion after the current quarter.
% In Q4 agents correctly anticipate return to new steady state from 2027Q1.
p_eomarch = wtifutures_change.mean_wtifutures_change(1)/100;    % EO March oil level
p_eoq2 = wtifutures_change.mean_wtifutures_change(2)/100; % EO Q2 oil level



p_newss_senate   = 0.00;    % new steady state / plateau level
p_newss_surprises = 0.00;
N_senate_high    = 4;       % Q1-Q4 2026 remain at EO March level
rho_g_path_senate = 0.85;
rho_g_path_surprises = 0.7; 



%caselab = {sprintf('Initial adjusted oil %.0f%%; shock path: +40%% for %d quarters, then return to SS', 100*p_init, X_high), ...
%           sprintf('Initial adjusted oil %.0f%%; shock path: +40%% for %d quarters, then plateau near +10%%', 100*p_init, X_high)};
caselab = {sprintf('Oil price returns to steady state'), ...
    sprintf('Early resolution')};

if do_senate_balks == 1
    caselab = [caselab, {sprintf('Disruption continues')}];
end

if do_full_surprises == 1
    caselab = [caselab, 'Disruption continues, rolling surprises'];
end

% Very distant return to the original steady state
T_return_start = 400;   % quarter when oil starts reverting from +10% to 0
use_nat = 0;
foldername = 'plateau_vs_SS';
run_name = '';

if casename == "Baseline"
    eta_e_val = 0.5;
    %titlename = sprintf('Perfect Foresight, 4-quarter Oil Price Shock');
    titlename = '';
    graphname = 'OilShock_4q_returnSS_vs_plateau10';
    graphname_png = 'fig2';
    dynamicplotlims = 1;

elseif casename == "High Eta_E"
    eta_e_val = 1.01;
    titlename = sprintf('Perfect Foresight Oil Shock: High Oil-Energy Elasticity, \\eta_e = %.1f', ...
        eta_e_val);
    graphname = [run_name '_high_eta_e'];
    dynamicplotlims = 1;

elseif casename == "Eta_E 2.0"
    eta_e_val = 2.0;
    titlename = sprintf('Oil Shock: High Oil-Energy Elasticity, \\eta_e = %.1f', ...
        eta_e_val);
    graphname = [run_name '_eta_e_2'];
    dynamicplotlims = 1;

else
    disp("Failed to specify case.")
    return
end





% -----------------------------
% Run Dynare
% -----------------------------
dynare(modname, 'noclearall');
global M_ oo_ options_


Mbase   = M_;
oobase  = oo_;
optbase = options_;


res = struct();

for i = 1:numel(cases)

    p_perm = cases(i).p_perm;

    % Reset model objects
    M_ = Mbase;
    oo_ = oobase;
    options_ = optbase;

    t = 0:H-1;

    % -----------------------------
    % Read persistence parameter
    % -----------------------------
    idx_rho_po = find(strcmp(cellstr(M_.param_names), 'rho_po'));
    rho_po     = M_.params(idx_rho_po);

    % -----------------------------
    % Setup PF objects for main experiment
    % -----------------------------
    options_.periods = T;
    oo_ = perfect_foresight_setup(M_, options_, oo_);

    oo_base   = oo_;
    endo_base = oo_.endo_simul;
    exo_base  = oo_.exo_simul;

    % -----------------------------
    % Set Parameter cases
    % -----------------------------
    set_param_value("use_nat", use_nat);
    set_param_value("eta_e", eta_e_val);
    set_param_value("rho_po", cases(i).rho_g_path);
    


    % -----------------------------
    % Variable indices
    % -----------------------------
    idx_e_po = find(strcmp(cellstr(M_.exo_names), 'e_po'));
    idx_e_cp = find(strcmp(cellstr(M_.exo_names), 'e_cp'));

    row_po   = find(strcmp(cellstr(M_.endo_names), 'po'));
    row_y    = find(strcmp(cellstr(M_.endo_names), 'y'));
    row_inv  = find(strcmp(cellstr(M_.endo_names), 'inv'));
    row_u    = find(strcmp(cellstr(M_.endo_names), 'u'));
    row_pi   = find(strcmp(cellstr(M_.endo_names), 'pi'));
    row_R    = find(strcmp(cellstr(M_.endo_names), 'R'));
    row_n    = find(strcmp(cellstr(M_.endo_names), 'n'));
    row_ygap = find(strcmp(cellstr(M_.endo_names), 'ygap'));
    row_k    = find(strcmp(cellstr(M_.endo_names), 'k'));
    row_c    = find(strcmp(cellstr(M_.endo_names), 'c'));


    % ============================================================
    % Optional warm-up phase
    %
    % Purpose:
    %   Construct an initial condition in which the whole economy has already
    %   adjusted to an elevated oil level p_init.
    %
    % Interpretation:
    %   If p_init = 0, this should reproduce the original initial steady state.
    %
    % Note:
    %   Since po_t = rho_po * po_{t-1} + e_po_t, keeping po = p_init requires
    %   e_po = (1-rho_po)*p_init each period.
    %
    % Implementation:
    %   We build a long path where oil is held near p_init, then very far in
    %   the future it returns to zero so that the PF terminal condition remains
    %   the original steady state.
    % ============================================================

    initial_endo_for_main = endo_base(:,1);

    if do_warmup == 1 && abs(p_init) > 1e-12

        % Temporarily change PF horizon for warm-up
        options_warm = options_;
        options_warm.periods = T_warm;

        oo_warm = perfect_foresight_setup(M_, options_warm, oo_);

        endo_warm_base = oo_warm.endo_simul;
        exo_warm_base  = oo_warm.exo_simul;

        % Build desired warm-up oil path
        po_warm_desired = zeros(T_warm,1);

        for tt = 1:T_warm

            if tt <= T_warm_return_start

                % Keep oil elevated during the economically relevant warm-up region.
                po_warm_desired(tt) = p_init;

            else

                % Far in the future, return to original steady state.
                po_warm_desired(tt) = rho_po^(tt - T_warm_return_start) * p_init;

            end

        end

        % Terminal exactly back at original steady state.
        po_warm_desired(end) = 0;

        % Convert warm-up desired po path into innovations.
        e_po_warm_path = zeros(T_warm,1);

        po_lag_warm = 0;
        for tt = 1:T_warm
            e_po_warm_path(tt) = po_warm_desired(tt) - rho_po * po_lag_warm;
            po_lag_warm = po_warm_desired(tt);
        end

        % Set up warm-up simulation.
        oo_warm.endo_simul = endo_warm_base;
        oo_warm.exo_simul  = exo_warm_base;

        oo_warm.exo_simul(:, idx_e_po) = 0;
        oo_warm.exo_simul(:, idx_e_cp) = 0;

        oo_warm.exo_simul(2:T_warm+1, idx_e_po) = e_po_warm_path;

        % Terminal condition: original steady state.
        oo_warm.endo_simul(row_po, end) = 0;
        oo_warm.exo_simul(end, idx_e_po) = 0;
        oo_warm.exo_simul(end, idx_e_cp) = 0;

        % Solve warm-up path.
        [oo_warm_sol, ~] = perfect_foresight_solver(M_, options_warm, oo_warm);

        % Use the last high-oil adjusted point before the artificial far-future return.
        % Since po is kept at p_init up to T_warm_return_start, this point is an
        % approximation to the economy adjusted to p_init.
        warm_pick = T_warm_return_start;

        initial_endo_for_main = oo_warm_sol.endo_simul(:, warm_pick + 1);

        fprintf('\nWarm-up completed.\n');
        fprintf('Using warm-up period %d as initial condition for main experiment.\n', warm_pick);
        fprintf('Warm-up oil state at selected point: %.4f, or %.2f%%.\n\n', ...
            oo_warm_sol.endo_simul(row_po, warm_pick + 1), ...
            100*oo_warm_sol.endo_simul(row_po, warm_pick + 1));

    else

        fprintf('\nWarm-up skipped or p_init = 0. Using original steady-state initial condition.\n\n');

    end


    % ============================================================
    % Build desired main oil-price path
    %
    % Desired path:
    %
    % 0. Initial condition comes from either:
    %       - original steady state, if p_init = 0 or do_warmup = 0;
    %       - warm-up adjusted state, if p_init ~= 0 and do_warmup = 1.
    %
    % 1. po_t = p_high for t = 1,...,X_high.
    %
    % 2. After that, po_t converges toward p_perm:
    %
    %       po_t = p_perm + rho_po^(t-X_high) * (p_high - p_perm)
    %
    % 3. It stays close to p_perm for a very long time.
    %
    % 4. At T_return_start, it starts reverting back to 0, so that the
    %    perfect-foresight problem is eventually consistent with the
    %    original terminal steady state.
    % ============================================================

    po_desired = zeros(T,1);

    if use_exact_futures_path==0

        for tt = 1:T
            if tt <= X_high
                po_desired(tt) = p_high;
            elseif tt <= T_return_start
                po_desired(tt) = p_perm + rho_po^(tt - X_high) * (p_high - p_perm);
            else
                po_at_return_start = p_perm + rho_po^(T_return_start - X_high) * (p_high - p_perm);
                po_desired(tt) = rho_po^(tt - T_return_start) * po_at_return_start;
            end
        end
    else

        % Plug in path of actual futures prices. P_oil returns to 0
        % gradually after 20q
        for tt = 1:T
            futurespath_end = numel(wtifutures_change.mean_wtifutures_change);

            if tt <= futurespath_end
                po_desired(tt) = wtifutures_change.mean_wtifutures_change(tt)./100;
            else
                po_at_futures_end = wtifutures_change.mean_wtifutures_change(end)./100;
                po_desired(tt) = rho_po^(tt - futurespath_end) * po_at_futures_end;
            end
        end
    end

    po_desired(end) = 0;




    % ============================================================
    % Convert desired main po path into required innovation path e_po
    %
    % Important:
    %   The lagged oil state for the first period is the oil state from the
    %   initial endogenous vector. If warm-up is active, this is approximately
    %   p_init. If p_init = 0, it is zero.
    % ============================================================

    e_po_path = zeros(T,1);

    po_lag = initial_endo_for_main(row_po);
    for tt = 1:T
        e_po_path(tt) = po_desired(tt) - rho_po * po_lag;
        po_lag = po_desired(tt);
    end


    % ============================================================
    % Solve main perfect-foresight path
    % ============================================================

    oo_ = oo_base;
    oo_.endo_simul = endo_base;
    oo_.exo_simul  = exo_base;

    oo_.exo_simul(:, idx_e_po) = 0;
    oo_.exo_simul(:, idx_e_cp) = 0;

    % Initial condition from either original SS or warm-up adjusted economy.
    oo_.endo_simul(:,1) = initial_endo_for_main;

    % Set oil innovation path.
    oo_.exo_simul(2:T+1, idx_e_po) = e_po_path;

    % Terminal condition: original steady state.
    oo_.endo_simul(row_po, end) = 0;
    oo_.exo_simul(end, idx_e_po) = 0;
    oo_.exo_simul(end, idx_e_cp) = 0;

    % Solve.
    [oo_oil, ~] = perfect_foresight_solver(M_, options_, oo_);


    % ============================================================
    % Store results
    % ============================================================

    res(i).oil.po   = 100 * oo_oil.endo_simul(row_po,   2:H+1)';
    res(i).oil.y    = 100 * oo_oil.endo_simul(row_y,    2:H+1)';
    res(i).oil.c    = 100 * oo_oil.endo_simul(row_c,    2:H+1)';
    res(i).oil.inv  = 100 * oo_oil.endo_simul(row_inv,  2:H+1)';
    res(i).oil.u    = 100 * oo_oil.endo_simul(row_u,    2:H+1)';
    res(i).oil.pi   = 400 * oo_oil.endo_simul(row_pi,   2:H+1)';
    res(i).oil.R    = 400 * oo_oil.endo_simul(row_R,    2:H+1)';
    res(i).oil.n    = 100 * oo_oil.endo_simul(row_n,    2:H+1)';
    res(i).oil.ygap = 100 * oo_oil.endo_simul(row_ygap, 2:H+1)';
    res(i).oil.k    = 100 * oo_oil.endo_simul(row_k,    2:H+1)';


    % Optional checks
    disp('Target oil path versus realized model oil path, first H periods:')
    disp(table((0:H-1)', 100*po_desired(1:H), res(i).oil.po, ...
        'VariableNames', {'Quarter','Target_po_percent','Realized_po_percent'}))

    disp('Initial endogenous states used in main experiment:')
    disp(table( ...
        ["po"; "y"; "c"; "inv"; "u"; "pi"; "R"; "n"; "ygap"; "k"], ...
        100 * [ ...
        initial_endo_for_main(row_po);
        initial_endo_for_main(row_y);
        initial_endo_for_main(row_c);
        initial_endo_for_main(row_inv);
        initial_endo_for_main(row_u);
        initial_endo_for_main(row_pi);
        initial_endo_for_main(row_R);
        initial_endo_for_main(row_n);
        initial_endo_for_main(row_ygap);
        initial_endo_for_main(row_k) ...
        ], ...
        'VariableNames', {'Variable','InitialValue_percent_or_pp'}))
end


% ============================================================
% Senate-balking scenario: anticipated Q1-Q2 high oil, then MIT surprises
%
% Realized path:
%   Q1-Q4 2026: po = p_eomarch
%   2027Q1 onward: po reverts toward p_newss_senate using rho_po
%
% Expectations:
%   Q1: oil is high today, and agents correctly expect it to remain
%       at the EO March level also in Q2. They expect reversion toward
%       p_newss_senate to begin in Q3.
%
%   Q2: no surprise. Oil is high as previously expected. Agents now
%       expect reversion toward p_newss_senate to begin in Q3.
%
%   Q3: surprise. Oil remains at the EO March level instead of reverting.
%       Agents again expect reversion toward p_newss_senate to begin
%       next quarter.
%
%   Q4: surprise again. Oil remains at the EO March level. Agents now
%       correctly anticipate that reversion toward p_newss_senate begins
%       in 2027Q1.
%
% Implementation:
%   The scenario is solved as a rolling sequence of perfect-foresight
%   MIT paths. At each date, only the first simulated quarter is kept;
%   the realized state is then updated before solving the next path.
% ============================================================
if do_senate_balks == 1

    % Store as third case
    i_senate = numel(cases) + 1;

    % Reset model objects
    M_ = Mbase;
    oo_ = oobase;
    options_ = optbase;

    t = 0:H-1;

    % -----------------------------
    % Read persistence parameter
    % -----------------------------
    idx_rho_po = find(strcmp(cellstr(M_.param_names), 'rho_po'));
    rho_po     = M_.params(idx_rho_po);

    % -----------------------------
    % Setup PF objects
    % -----------------------------
    options_.periods = T;
    oo_ = perfect_foresight_setup(M_, options_, oo_);

    oo_base   = oo_;
    endo_base = oo_.endo_simul;
    exo_base  = oo_.exo_simul;

    % -----------------------------
    % Set Parameter cases
    % -----------------------------
    set_param_value("use_nat", use_nat);
    set_param_value("eta_e", eta_e_val);
    set_param_value("rho_po", rho_g_path_senate);

    % -----------------------------
    % Variable indices
    % -----------------------------
    idx_e_po = find(strcmp(cellstr(M_.exo_names), 'e_po'));
    idx_e_cp = find(strcmp(cellstr(M_.exo_names), 'e_cp'));

    row_po   = find(strcmp(cellstr(M_.endo_names), 'po'));
    row_y    = find(strcmp(cellstr(M_.endo_names), 'y'));
    row_inv  = find(strcmp(cellstr(M_.endo_names), 'inv'));
    row_u    = find(strcmp(cellstr(M_.endo_names), 'u'));
    row_pi   = find(strcmp(cellstr(M_.endo_names), 'pi'));
    row_R    = find(strcmp(cellstr(M_.endo_names), 'R'));
    row_n    = find(strcmp(cellstr(M_.endo_names), 'n'));
    row_ygap = find(strcmp(cellstr(M_.endo_names), 'ygap'));
    row_k    = find(strcmp(cellstr(M_.endo_names), 'k'));
    row_c    = find(strcmp(cellstr(M_.endo_names), 'c'));

    % -----------------------------
    % Initial condition
    % -----------------------------
    % Minimal-change version: use original steady-state initial condition.
    % If you later want this combined with the warm-up, this block can be
    % extended to reuse the warm-up initial condition.
    initial_endo_for_senate = endo_base(:,1);

    oo_state = oo_base;
    oo_state.endo_simul = endo_base;
    oo_state.exo_simul  = exo_base;
    oo_state.endo_simul(:,1) = initial_endo_for_senate;

    po_lag = initial_endo_for_senate(row_po);

    % Storage
    res(i_senate).oil.po   = zeros(H,1);
    res(i_senate).oil.y    = zeros(H,1);
    res(i_senate).oil.c    = zeros(H,1);
    res(i_senate).oil.inv  = zeros(H,1);
    res(i_senate).oil.u    = zeros(H,1);
    res(i_senate).oil.pi   = zeros(H,1);
    res(i_senate).oil.R    = zeros(H,1);
    res(i_senate).oil.n    = zeros(H,1);
    res(i_senate).oil.ygap = zeros(H,1);
    res(i_senate).oil.k    = zeros(H,1);

    po_realized_senate = zeros(H,1);

    for h = 1:H

        % ------------------------------------------------------------
        % Build agents' perceived oil path from current quarter onward
        % ------------------------------------------------------------

        po_expected = zeros(T,1);

        if h <= N_senate_high


            if h == 1  % In Q1, Agents expect the price of oil to decline steadily

                if use_exact_futures_path==1
                    % Plug in path of actual futures prices
                    for tt = 1:T
                        futurespath_end = numel(wtifutures_change.mean_wtifutures_change);
            
                        if tt <= futurespath_end
                            po_expected(tt) = wtifutures_change.mean_wtifutures_change(tt)./100;
                        else
                            po_at_futures_end = wtifutures_change.mean_wtifutures_change(end)./100;
                            po_expected(tt) = rho_po^(tt - futurespath_end) * po_at_futures_end;
                        end
                    end
                    po_expected(end) = 0;
                else
    
                    % Q1, Q3-Q4 2026: current realized oil is at EO March level.
                    po_expected(1) = p_eomarch;
    
                    % Q1 information set:
                    % agents correctly expect oil to decline to the 
                    % observed Q2 level. Reversion toward the new steady state starts
                    % using rho_po from Q3 in their expectations.
                    po_expected(2) = p_eoq2;
    
                    for tt = 3:T_return_start
                        po_expected(tt) = p_newss_senate ...
                            + rho_po^(tt-2) * (p_eoq2 - p_newss_senate);
                    end
                end


            elseif h == 2 % Q2: no surprise: oil is at expected Q2 level. Agents expect continued reversion
                          % starting in Q3.

                if use_exact_futures_path==1
                    % Plug in path of actual futures prices
                    for tt = 1:T
                        futurespath_end = numel(wtifutures_change.mean_wtifutures_change);
            
                        if tt <= futurespath_end
                            po_expected(tt) = wtifutures_change.mean_wtifutures_change(tt)./100;
                        else
                            po_at_futures_end = wtifutures_change.mean_wtifutures_change(end)./100;
                            po_expected(tt) = rho_po^(tt - futurespath_end) * po_at_futures_end;
                        end
                    end
                    po_expected = [po_expected(2:end); 0];

                else % Decay from Q2 realized level using rho_po
                    po_expected(1) = p_eoq2;
    
                    for tt = 2:T_return_start
                        po_expected(tt) = p_newss_senate ...
                            + rho_po^(tt-1) * (p_eoq2 - p_newss_senate);
                    end
                end


            else
                
                % Q1, Q3-Q4 2026: current realized oil is at EO March level.
                po_expected(1) = p_eomarch;

            
                % Q3 information set:
                % surprise: oil is still high. Agents expect reversion starting in Q4.
                %
                % Q4 information set:
                % surprise again, but now agents correctly anticipate reversion
                % starting in 2027Q1.
                for tt = 2:T_return_start
                    po_expected(tt) = p_newss_senate ...
                        + rho_po^(tt-1) * (p_eomarch - p_newss_senate);
                end

            end

        else

            % From 2027Q1 onward, there are no more surprises.
            % Oil actually reverts toward the new steady state using rho_po.
            po_expected(1) = p_newss_senate ...
                + rho_po * (po_lag - p_newss_senate);

            for tt = 2:T_return_start
                po_expected(tt) = p_newss_senate ...
                    + rho_po^(tt-1) * (po_expected(1) - p_newss_senate);
            end

        end

        % Far-distant technical return to original steady state, as in the
        % baseline code. This keeps the terminal condition clean.
        for tt = T_return_start:T
            po_at_return_start = po_expected(T_return_start);
            po_expected(tt) = rho_po^(tt - T_return_start) * po_at_return_start;
        end

        po_expected(end) = 0;

        % ------------------------------------------------------------
        % Convert perceived po path into required innovation path e_po
        % ------------------------------------------------------------

        e_po_path = zeros(T,1);

        po_lag_tmp = po_lag;
        for tt = 1:T
            e_po_path(tt) = po_expected(tt) - rho_po * po_lag_tmp;
            po_lag_tmp = po_expected(tt);
        end

        % ------------------------------------------------------------
        % Solve perfect-foresight path from current realized state
        % ------------------------------------------------------------

        oo_tmp = oo_base;
        oo_tmp.endo_simul = endo_base;
        oo_tmp.exo_simul  = exo_base;

        % Inherited endogenous state
        oo_tmp.endo_simul(:,1) = oo_state.endo_simul(:,1);

        % Reset shocks
        oo_tmp.exo_simul(:, idx_e_po) = 0;
        oo_tmp.exo_simul(:, idx_e_cp) = 0;

        % Set perceived oil innovation path
        oo_tmp.exo_simul(2:T+1, idx_e_po) = e_po_path;

        % Terminal condition: original steady state
        oo_tmp.endo_simul(row_po, end) = 0;
        oo_tmp.exo_simul(end, idx_e_po) = 0;
        oo_tmp.exo_simul(end, idx_e_cp) = 0;

        % Solve
        [oo_sol, ~] = perfect_foresight_solver(M_, options_, oo_tmp);

        % ------------------------------------------------------------
        % Store only current realized quarter
        % ------------------------------------------------------------

        res(i_senate).oil.po(h)   = 100 * oo_sol.endo_simul(row_po,   2);
        res(i_senate).oil.y(h)    = 100 * oo_sol.endo_simul(row_y,    2);
        res(i_senate).oil.c(h)    = 100 * oo_sol.endo_simul(row_c,    2);
        res(i_senate).oil.inv(h)  = 100 * oo_sol.endo_simul(row_inv,  2);
        res(i_senate).oil.u(h)    = 100 * oo_sol.endo_simul(row_u,    2);
        res(i_senate).oil.pi(h)   = 400 * oo_sol.endo_simul(row_pi,   2);
        res(i_senate).oil.R(h)    = 400 * oo_sol.endo_simul(row_R,    2);
        res(i_senate).oil.n(h)    = 100 * oo_sol.endo_simul(row_n,    2);
        res(i_senate).oil.ygap(h) = 100 * oo_sol.endo_simul(row_ygap, 2);
        res(i_senate).oil.k(h)    = 100 * oo_sol.endo_simul(row_k,    2);

        po_realized_senate(h) = oo_sol.endo_simul(row_po, 2);

        % ------------------------------------------------------------
        % Update realized state for next quarter
        % ------------------------------------------------------------

        oo_state.endo_simul(:,1) = oo_sol.endo_simul(:,2);
        po_lag = oo_sol.endo_simul(row_po, 2);

    end


    % Optional check
    disp('Senate-balking realized oil path, first H periods:')
    disp(table((0:H-1)', 100*po_realized_senate(1:H), res(i_senate).oil.po, ...
        'VariableNames', {'Quarter','Realized_po_state_percent','Stored_po_percent'}))

end



% ============================================================
% Full Surprises scenario:
%
% Realized path:
% - Same as senate balks
%
% Expectations:
% - Agents expect a gradual reversion in each quarter
%
% Implementation:
%   The scenario is solved as a rolling sequence of perfect-foresight
%   MIT paths. At each date, only the first simulated quarter is kept;
%   the realized state is then updated before solving the next path.
% ============================================================
if do_full_surprises == 1

    % Store as third case
    i_surprises = numel(cases) + do_senate_balks + 1;

    % Reset model objects
    M_ = Mbase;
    oo_ = oobase;
    options_ = optbase;

    t = 0:H-1;

    % -----------------------------
    % Read persistence parameter
    % -----------------------------
    idx_rho_po = find(strcmp(cellstr(M_.param_names), 'rho_po'));
    rho_po     = M_.params(idx_rho_po);

    % -----------------------------
    % Setup PF objects
    % -----------------------------
    options_.periods = T;
    oo_ = perfect_foresight_setup(M_, options_, oo_);

    oo_base   = oo_;
    endo_base = oo_.endo_simul;
    exo_base  = oo_.exo_simul;

    % -----------------------------
    % Set Parameter cases
    % -----------------------------
    set_param_value("use_nat", use_nat);
    set_param_value("eta_e", eta_e_val);
    set_param_value("rho_po", rho_g_path_surprises);

    % -----------------------------
    % Variable indices
    % -----------------------------
    idx_e_po = find(strcmp(cellstr(M_.exo_names), 'e_po'));
    idx_e_cp = find(strcmp(cellstr(M_.exo_names), 'e_cp'));

    row_po   = find(strcmp(cellstr(M_.endo_names), 'po'));
    row_y    = find(strcmp(cellstr(M_.endo_names), 'y'));
    row_inv  = find(strcmp(cellstr(M_.endo_names), 'inv'));
    row_u    = find(strcmp(cellstr(M_.endo_names), 'u'));
    row_pi   = find(strcmp(cellstr(M_.endo_names), 'pi'));
    row_R    = find(strcmp(cellstr(M_.endo_names), 'R'));
    row_n    = find(strcmp(cellstr(M_.endo_names), 'n'));
    row_ygap = find(strcmp(cellstr(M_.endo_names), 'ygap'));
    row_k    = find(strcmp(cellstr(M_.endo_names), 'k'));
    row_c    = find(strcmp(cellstr(M_.endo_names), 'c'));

    % -----------------------------
    % Initial condition
    % -----------------------------
    % Minimal-change version: use original steady-state initial condition.
    % If you later want this combined with the warm-up, this block can be
    % extended to reuse the warm-up initial condition.
    initial_endo_for_surprises = endo_base(:,1);

    oo_state = oo_base;
    oo_state.endo_simul = endo_base;
    oo_state.exo_simul  = exo_base;
    oo_state.endo_simul(:,1) = initial_endo_for_surprises;

    po_lag = initial_endo_for_surprises(row_po);

    % Storage
    res(i_surprises).oil.po   = zeros(H,1);
    res(i_surprises).oil.y    = zeros(H,1);
    res(i_surprises).oil.c    = zeros(H,1);
    res(i_surprises).oil.inv  = zeros(H,1);
    res(i_surprises).oil.u    = zeros(H,1);
    res(i_surprises).oil.pi   = zeros(H,1);
    res(i_surprises).oil.R    = zeros(H,1);
    res(i_surprises).oil.n    = zeros(H,1);
    res(i_surprises).oil.ygap = zeros(H,1);
    res(i_surprises).oil.k    = zeros(H,1);

    po_realized_surprises = zeros(H,1);

    for h = 1:H

        % ------------------------------------------------------------
        % Build agents' perceived oil path from current quarter onward
        % ------------------------------------------------------------

        po_expected = zeros(T,1);

        if h <= N_senate_high

            if h == 1  % In Q1, Agents expect the price of oil to decline steadily

                    % Q1, Q3-Q4 2026: current realized oil is at EO March level.
                    po_expected(1) = p_eomarch;
    
                    for tt = 2:T_return_start
                        po_expected(tt) = p_newss_surprises ...
                            + rho_po^(tt-1) * (p_eomarch - p_newss_surprises);
                    end
                
              


            elseif h == 2 % Q2: no surprise: oil is at expected Q2 level. Agents expect continued reversion
                          % starting in Q3.

                 % Decay from Q2 realized level using rho_po_surprises
                    po_expected(1) = p_eoq2;
    
                    for tt = 2:T_return_start
                        po_expected(tt) = p_newss_surprises ...
                            + rho_po^(tt-1) * (p_eoq2 - p_newss_surprises);
                    end

            else
                
                % Q1, Q3-Q4 2026: current realized oil is at EO March
                % level. Expectations include decline at rho_g_surprises
                po_expected(1) = p_eomarch;

                for tt = 2:T_return_start
                    po_expected(tt) = p_newss_surprises ...
                        + rho_po^(tt-1) * (p_eomarch - p_newss_surprises);
                end

                if h == 4
                    po_expected_q4 = po_expected; % Diagnostic
                end

            end

        else

            % From 2027Q1 onward, the price of oil is decaying more slowly
            % than expected. 
            % Oil is expected to revert toward the new steady state using
            % rho_po_surprises
            % Oil actually reverts toward the new steady state using rho_po_senate.
            po_expected(1) = p_newss_surprises ...
                + rho_g_path_senate * (po_lag - p_newss_surprises);

            for tt = 2:T_return_start
                po_expected(tt) = p_newss_surprises ...
                    + rho_po^(tt-1) * (po_expected(1) - p_newss_surprises);
            end

        end

        % Far-distant technical return to original steady state, as in the
        % baseline code. This keeps the terminal condition clean.
        for tt = T_return_start:T
            po_at_return_start = po_expected(T_return_start);
            po_expected(tt) = rho_po^(tt - T_return_start) * po_at_return_start;
        end

        po_expected(end) = 0;


        % ------------------------------------------------------------
        % Convert perceived po path into required innovation path e_po
        % ------------------------------------------------------------

        e_po_path = zeros(T,1);

        po_lag_tmp = po_lag;
        for tt = 1:T
            e_po_path(tt) = po_expected(tt) - rho_po * po_lag_tmp;
            po_lag_tmp = po_expected(tt);
        end

        % ------------------------------------------------------------
        % Solve perfect-foresight path from current realized state
        % ------------------------------------------------------------

        oo_tmp = oo_base;
        oo_tmp.endo_simul = endo_base;
        oo_tmp.exo_simul  = exo_base;

        % Inherited endogenous state
        oo_tmp.endo_simul(:,1) = oo_state.endo_simul(:,1);

        % Reset shocks
        oo_tmp.exo_simul(:, idx_e_po) = 0;
        oo_tmp.exo_simul(:, idx_e_cp) = 0;

        % Set perceived oil innovation path
        oo_tmp.exo_simul(2:T+1, idx_e_po) = e_po_path;

        % Terminal condition: original steady state
        oo_tmp.endo_simul(row_po, end) = 0;
        oo_tmp.exo_simul(end, idx_e_po) = 0;
        oo_tmp.exo_simul(end, idx_e_cp) = 0;

        % Solve
        [oo_sol, ~] = perfect_foresight_solver(M_, options_, oo_tmp);

        % ------------------------------------------------------------
        % Store only current realized quarter
        % ------------------------------------------------------------

        res(i_surprises).oil.po(h)   = 100 * oo_sol.endo_simul(row_po,   2);
        res(i_surprises).oil.y(h)    = 100 * oo_sol.endo_simul(row_y,    2);
        res(i_surprises).oil.c(h)    = 100 * oo_sol.endo_simul(row_c,    2);
        res(i_surprises).oil.inv(h)  = 100 * oo_sol.endo_simul(row_inv,  2);
        res(i_surprises).oil.u(h)    = 100 * oo_sol.endo_simul(row_u,    2);
        res(i_surprises).oil.pi(h)   = 400 * oo_sol.endo_simul(row_pi,   2);
        res(i_surprises).oil.R(h)    = 400 * oo_sol.endo_simul(row_R,    2);
        res(i_surprises).oil.n(h)    = 100 * oo_sol.endo_simul(row_n,    2);
        res(i_surprises).oil.ygap(h) = 100 * oo_sol.endo_simul(row_ygap, 2);
        res(i_surprises).oil.k(h)    = 100 * oo_sol.endo_simul(row_k,    2);

        po_realized_surprises(h) = oo_sol.endo_simul(row_po, 2);

        % ------------------------------------------------------------
        % Update realized state for next quarter
        % ------------------------------------------------------------

        oo_state.endo_simul(:,1) = oo_sol.endo_simul(:,2);
        po_lag = oo_sol.endo_simul(row_po, 2);

    end


    % Optional check
    disp('Senate-balking realized oil path, first H periods:')
    disp(table((0:H-1)', 100*po_realized_surprises(1:H), res(i_surprises).oil.po, ...
        'VariableNames', {'Quarter','Realized_po_state_percent','Stored_po_percent'}))

end



% ============================================================
% Plot 2x3 figure: one shock only
% ============================================================

% Convert X-Axis Labels to FL format
datesplot = datetime(2026, 03, 31) + calquarters(0:20);
datelabels = strcat(string(year(datesplot)), ":Q", string(quarter(datesplot)));

fig1 = figure('Color','w','Position',[100 100 1300 850]);
tiledlayout(2,3);

if do_senate_balks == 1

    if do_full_surprises == 1

        plotdata_2x3 = {
            res(1).oil.po,     res(2).oil.po,      res(3).oil.po,   res(4).oil.po,      'A. Oil price',      'Percent dev. from steady state';
            res(1).oil.y,      res(2).oil.y,       res(3).oil.y,    res(4).oil.y,       'B. Output',         'Percent dev. from steady state';
            res(1).oil.c,      res(2).oil.c,       res(3).oil.c,    res(4).oil.c,       'C. Consumption',    'Percent dev. from steady state'
            res(1).oil.pi,     res(2).oil.pi,      res(3).oil.pi,   res(4).oil.pi,      'D. Inflation',     'Annualized percentage points';
            res(1).oil.R,      res(2).oil.R,       res(3).oil.R,    res(4).oil.R,       'E. Interest rate',  'Annualized percentage points';
            res(1).oil.inv,    res(2).oil.inv,     res(3).oil.inv,  res(4).oil.inv,     'F. Investment',     'Percent dev. from steady state';
            };

    else
        plotdata_2x3 = {
            res(1).oil.po,     res(2).oil.po,      res(3).oil.po,      'A. Oil price',      'Percent dev. from steady state';
            res(1).oil.y,      res(2).oil.y,       res(3).oil.y,       'B. Output',         'Percent dev. from steady state';
            res(1).oil.c,      res(2).oil.c,       res(3).oil.c,       'C. Consumption',    'Percent dev. from steady state'
            res(1).oil.pi,     res(2).oil.pi,      res(3).oil.pi,      'D. Inflation',     'Annualized percentage points';
            res(1).oil.R,      res(2).oil.R,       res(3).oil.R,       'E. Interest rate',  'Annualized percentage points';
            res(1).oil.inv,    res(2).oil.inv,     res(3).oil.inv,     'F. Investment',     'Percent dev. from steady state';
            };

    end


else

    plotdata_2x3 = {
        res(1).oil.po,     res(2).oil.po,      'A. Oil price',      'Percent dev. from steady state';
        res(1).oil.y,      res(2).oil.y,       'B. Output',         'Percent dev. from steady state';
        res(1).oil.c,      res(2).oil.c,       'C. Consumption',    'Percent dev. from steady state'
        res(1).oil.pi,     res(2).oil.pi,      'D. Inflation',     'Annualized percentage points';
        res(1).oil.R,      res(2).oil.R,       'E. Interest rate',  'Annualized percentage points';
        res(1).oil.inv,    res(2).oil.inv,     'F. Investment',     'Percent dev. from steady state';
        };

end

% Save output numbers (fig2)
%towrite = table(plotdata_2x3{2, 2:4}, 'VariableNames', {'Early resolution', 'Disruption Continues', 'Disruption Continues: rolling surprises'});
%towrite.Date = datelabels';
%towrite = movevars(towrite, "Date", "Before", "Early resolution");
%writetable(towrite, ...
%           'fig2_output.csv', 'WriteVariableNames', true)

plotlims = {
    [0 60];
    [-5.0 0.5];
    [-5.0 0.5];
    [-0.4 1.2];
    [-0.2 1.6];
    [-5.0 0.5]
    };


for i = 1:6
    nexttile(i); hold on;

    %plot(t+1, plotdata_2x3{i,1}, 'Linestyle', '-', 'LineWidth', 1, 'Color', "#8E0000") ;
    plot(t+1, plotdata_2x3{i,2}, 'Linestyle', '-', 'LineWidth', 1, 'Color', '#EEA957' );

    if do_senate_balks == 1
        if do_full_surprises == 1
            plot(t+1, plotdata_2x3{i,3}, 'Linestyle', '-', 'LineWidth', 1, 'Color', "#3E89E1" );
            plot(t+1, plotdata_2x3{i,4}, 'Linestyle', '--', 'LineWidth', 1, 'Color', "#839974" );
            tit=title(plotdata_2x3{i,5}, 'FontSize', 8);
            yl=ylabel(lower(plotdata_2x3{i,6}), 'FontSize', 7);
        else
            plot(t+1, plotdata_2x3{i,3}, 'Linestyle', '-', 'LineWidth', 1, 'Color', "#3E89E1" );
            tit=title(plotdata_2x3{i,4}, 'FontSize', 8);
            yl=ylabel(lower(plotdata_2x3{i,5}), 'FontSize', 7);            
        end

    else
        tit=title(plotdata_2x3{i,3}, 'FontSize', 8);
        yl=ylabel(lower(plotdata_2x3{i,4}), 'FontSize', 7);
    end

    if dynamicplotlims == 0
        ylim(plotlims{i});
    end



    yline(0,'k-');
    %grid on;
    box off;

    % Label X-axis as model quarters (1:H-1)
    xlabel('quarter', 'FontSize', 7);
    xlim([1 H-1]);
    currentticks = xticks;
    xticks(sort([1 currentticks]));

    % Label X-axis as calendar quarters (2026:Q1 etc.)
    %xlabel("")
    %xticks(1:4:20);
    %xticklabels(datelabels(xticks));
    %xtickangle(0)

    cyticks = yticks;
    yticklabels(compose('%.1f', cyticks));


    % Position ylab above axis
    set(yl, 'Units', 'normalized', 'Position', [0 1.02], 'Rotation', 0, 'HorizontalAlignment', 'left')
    set(tit, 'Units', 'normalized', 'Position', [0 1.06], 'Rotation', 0, 'HorizontalAlignment', 'left')

    ax = gca;
    ax.LineWidth = 1;
    ax.FontSize = 7;
    set(gca, 'FontName', 'Arial')

end

lg = legend(caselab(2:end), 'FontSize', 9);
lg.Layout.Tile = 'South';
lg.Box = "off";

% Plot Market-Expected Oil Price in Panel 1 (From data)
%nexttile(1)
%l1 = plot(wtifutures_change.modelquarter(1:20), wtifutures_change.mean_wtifutures_change(1:20), 'Color', '#839974', 'LineWidth', 0.5, 'LineStyle', '--');
%legend(l1, 'Futures price change', 'Location', 'southoutside', 'box', 'off', 'FontSize', 7)



sgtitle(titlename, ...
    'FontSize', 18, 'FontWeight', 'bold');


set(gcf,'Units','inches');
set(gcf,'Position',[1 1 8 6]);
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperUnits', 'normalized');
set(gcf, 'PaperPosition', [0 0 1 1]);

if printfigs == 1
    if ~exist('./figures_png', 'dir')
        mkdir('./figures_png');
    end
    print(gcf, ['./figures_png/' graphname_png '.png'], '-dpng')
end


% Disp Parameter vals
table(M_.params, M_.param_names)