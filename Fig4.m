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

do_manual_70s_path = 1;
pbar_70s   = 1.49;   % level of po during oil step: 100%
pbarpath_seventies = (readtable("./data_created/wtichanges_seventies.csv").WTIChange)./100;




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
%wtifutures_change = readtable('wtifutures_change.csv');
wtifutures_change = readtable('./data_created/wtifutures_exp_March.csv');

% -----------------------------
% Main oil-shock path
% -----------------------------

p_high = 0.51;    % oil level during high-oil phase: +40%
p_perm = 0.07;    % long-run temporarily elevated oil level: +10%
rho_g_path = 0.5;
X_high = 1;       % number of quarters oil stays at +40%
N_seventies = 4;
use_exact_futures_path = 1;


%caselab = {sprintf('Initial adjusted oil %.0f%%; shock path: +40%% for %d quarters, then return to SS', 100*p_init, X_high), ...
%           sprintf('Initial adjusted oil %.0f%%; shock path: +40%% for %d quarters, then plateau near +10%%', 100*p_init, X_high)};
caselab = {'2026 oil shock',  '1979-80 oil shock'};


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
    graphname_png = 'fig4';
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
set_param_value("rho_po", rho_g_path);


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

    % Plug in path of actual futures prices
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

res(1).oil.po   = 100 * oo_oil.endo_simul(row_po,   2:H+1)';
res(1).oil.y    = 100 * oo_oil.endo_simul(row_y,    2:H+1)';
res(1).oil.c    = 100 * oo_oil.endo_simul(row_c,    2:H+1)';
res(1).oil.inv  = 100 * oo_oil.endo_simul(row_inv,  2:H+1)';
res(1).oil.u    = 100 * oo_oil.endo_simul(row_u,    2:H+1)';
res(1).oil.pi   = 400 * oo_oil.endo_simul(row_pi,   2:H+1)';
res(1).oil.R    = 400 * oo_oil.endo_simul(row_R,    2:H+1)';
res(1).oil.n    = 100 * oo_oil.endo_simul(row_n,    2:H+1)';
res(1).oil.ygap = 100 * oo_oil.endo_simul(row_ygap, 2:H+1)';
res(1).oil.k    = 100 * oo_oil.endo_simul(row_k,    2:H+1)';


% Optional checks
disp('Target oil path versus realized model oil path, first H periods:')
disp(table((0:H-1)', 100*po_desired(1:H), res(1).oil.po, ...
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





% ============================================================
% 3. Repeated-surprise oil shock during runup, followed by 
%    perfect foresight during oil price decay
%
% Realized oil price is the same as the known long shock:
% po_t = pbar for the first N_long quarters, then no new shocks.
%
% But expectations are different:
% in the first quarter, agents initially expect 2 quarters of high oil;
% after that, each quarter agents believe the shock will stop
% after the current quarter.
% ============================================================

N = N_seventies;


%% Phase 1: Surprises during Runup

% Calibrate Decay to empricial prices
new_rho_po = 0.92;
set_param_value("rho_po", new_rho_po);
rho_po = new_rho_po;

% Reset model objects
oo_state = oo_base;
oo_state.endo_simul = endo_base;
oo_state.exo_simul  = exo_base;

surprise_path = struct();
surprise_path.po   = zeros(H,1);
surprise_path.y    = zeros(H,1);
surprise_path.inv  = zeros(H,1);
surprise_path.u    = zeros(H,1);
surprise_path.pi   = zeros(H,1);
surprise_path.R    = zeros(H,1);
surprise_path.n    = zeros(H,1);
surprise_path.ygap = zeros(H,1);
surprise_path.k    = zeros(H,1);
surprise_path.c    = zeros(H,1);

po_lag = 0;   % realized inherited oil-price state

for h = 1:H

    oo_tmp = oo_base;

    % Use previous realized endogenous values as new initial condition
    oo_tmp.endo_simul = endo_base;
    oo_tmp.endo_simul(:,1) = oo_state.endo_simul(:,1);

    % Reset exogenous path
    oo_tmp.exo_simul = exo_base;
    oo_tmp.exo_simul(:, idx_e_po) = 0;
    oo_tmp.exo_simul(:, idx_e_cp) = 0;


    if h <= N
        % Choose current innovation so that realized po_h = pbar:
        %   po_h = rho_po * po_{h-1} + e_po_h
        % therefore:
        %   e_po_h = pbar - rho_po * po_lag
        if do_manual_70s_path==1
            poil = pbarpath_seventies(h);
        else
            poil = pbar_70s;
        end
        e_now = poil - rho_po * po_lag;
    
        % Current-period innovation
        oo_tmp.exo_simul(2, idx_e_po) = e_now;
 
    
        % For h >= 2, no future oil innovations are added.
        % Agents believe the shock ends after the current quarter.

    end

    % Solve from this quarter onward
    [oo_sol, ~] = perfect_foresight_solver(M_, options_, oo_tmp);

    % Store only the realized first-period outcome
    surprise_path.po(h)   = 100 * oo_sol.endo_simul(row_po,   2);
    surprise_path.y(h)    = 100 * oo_sol.endo_simul(row_y,    2);
    surprise_path.inv(h)  = 100 * oo_sol.endo_simul(row_inv,  2);
    surprise_path.u(h)    = 100 * oo_sol.endo_simul(row_u,    2);
    surprise_path.pi(h)   = 400 * oo_sol.endo_simul(row_pi,   2);
    surprise_path.R(h)    = 400 * oo_sol.endo_simul(row_R,    2);
    surprise_path.n(h)    = 100 * oo_sol.endo_simul(row_n,    2);
    surprise_path.ygap(h) = 100 * oo_sol.endo_simul(row_ygap, 2);
    surprise_path.k(h)    = 100 * oo_sol.endo_simul(row_k,    2);
    surprise_path.c(h)    = 100 * oo_sol.endo_simul(row_c,    2);

    % Update realized oil-price state
    po_lag = oo_sol.endo_simul(row_po, 2);

    % Update endogenous state for next quarter
    oo_state.endo_simul(:,1) = oo_sol.endo_simul(:,2);

end


res.surprise = surprise_path;



% ============================================================
% Plot 2x3 figure: one shock only
% ============================================================

fig1 = figure('Color','w','Position',[100 100 1300 850]);
tl=tiledlayout(2,3);
tl.Padding = 'loose';


plotdata_2x3 = {
    res(1).oil.po,  res.surprise.po,    'A. Oil price',      'Percent dev. from steady state';
    res(1).oil.y,   res.surprise.y,     'B. Output',         'Percent dev. from steady state';
    res(1).oil.c,   res.surprise.c,     'C. Consumption',    'Percent dev. from steady state'
    res(1).oil.pi,  res.surprise.pi,    'D. Inflation',     'Annualized percentage points';
    res(1).oil.R,   res.surprise.R,     'E. Interest rate',  'Annualized percentage points';
    res(1).oil.inv, res.surprise.inv,   'F. Investment',     'Percent dev. from steady state';
    };


plotlims = {
    [0 120];
    [-14 0];
    [-14 0];
    [-0.5 2.5];
    [-0.5 3.0];
    [-14 0]
    };


for i = 1:6
    nexttile(i); hold on;

    plot(t+1, plotdata_2x3{i,1}, 'Linestyle', '-', 'LineWidth', 1, 'Color', '#EEA957') ;
    plot(t+1, plotdata_2x3{i,2}, 'Linestyle', '-', 'LineWidth', 1, 'Color',  "#8E0000");


    tit=title(plotdata_2x3{i,3}, 'FontSize', 8);
    yl=ylabel(lower(plotdata_2x3{i,4}), 'FontSize', 7);

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
    xticks(sort([1 currentticks]))


    % Label X-axis as calendar quarters (2026:Q1 etc.)
    %xl = xlabel("");
    %xticks(1:4:20);
    %xticklabels(datelabels(xticks));
    %xtickangle(0)
    %xl.Position(3) = xl.Position(3)*1.5



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

lg = legend(caselab, 'FontSize', 9);
lg.Layout.Tile = 'South';
lg.Box = "off";


% Plot empirical WTI prices in 1979-80
nexttile(1);
p1 = plot(1:20, pbarpath_seventies.*100, 'Color', '#042336', 'Linestyle', '--');
leg1 = legend(p1, "Historical real oil price change in 1979-84", 'FontSize', 9, 'Location', 'southoutside', 'Box', 'off');
ylim([0 135]);



sgtitle(titlename, ...
    'FontSize', 18, 'FontWeight', 'bold');

set(gcf,'Units','inches');
set(gcf,'Position',[1 1 12 8]);
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