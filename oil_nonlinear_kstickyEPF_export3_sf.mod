// ============================================================
// ai_growth_oil_util_nonlinear_rotembergP_rotembergW_MIT.mod
// Fully nonlinear version in exp()-form
// Variables are log deviations from steady state
// Minimal extension: convex capital adjustment costs
// Minimal energy extension: CES energy price index pe
// Minimal nominal-rigidity extension: price and wage indexation
// Minimal oil-exporter extension: reduced-form oil rebate
// Minimal labor-market friction extension: convex hiring costs
// When iota_p = 0 and iota_w = 0, the model nests the no-indexation version
// When psi_n = 0, the model nests the no-hiring-cost version
// ============================================================

var
    c n u k inv y a g
    pi piw R
    mc w rk lambda uc
    wstar muw
    q
    cn nn un kn invn yn rn rkn lambdan ucn wn mcn
    qn
    ygap
    po
    pe
    cp
;

varexo
    gexo
    e_po
    e_cp
    eR
;

parameters
    beta sigma varphi
    phiP phiW epsilon
    theta_w eps_w
    rho_R phi_pi phi_x phi_r
    hab use_nat
    psi_n
    nbar
    alpha_u
    zeta
    delta
    rho_po rho_cp
    mcss yss css wss rkss lambdass
    s_c s_i
    xi_k
    kappa_p kappa_w
    phiI
    target_oil_share_out target_energy_share_out
    omega_o
    eta_e
    iota_p iota_w
    s_oilnet
;

// -------------------------
// Calibration
// -------------------------
beta    = 0.99;
sigma   = 1.0;
varphi  = 0.5; 

phiP    = 50.0;
epsilon = 6.0;

theta_w = 0.75;
eps_w   = 6.0;

rho_R   = 0.7;
phi_pi  = 2.0;
phi_x   = 0.5;
phi_r   = 1.0;

hab     = 0.75;
use_nat = 0.0;
psi_n   = 0.0;

nbar    = 0.33;
alpha_u = 0.4;
delta   = 0.025;
rho_po  = 0.85;
rho_cp  = 0.5;

phiI    = 2.0;

// Energy block (shares as a function of GDP)
target_oil_share_out    = 0.025;
target_energy_share_out = 0.056;

omega_o = target_oil_share_out / target_energy_share_out;
eta_e   = 0.5; // Elasticity of substitution between oil and other forms of energy

// Indexation
iota_p  = 0.5;
iota_w  = 0.5;

// Reduced-form oil export rebate
// Start small: 0.005, 0.01, 0.02
s_oilnet = 0.0015;

// -------------------------
// Steady-state objects
// -------------------------
mcss = (epsilon-1)/epsilon;
zeta = alpha_u * mcss / target_energy_share_out;
rkss = 1/beta - 1 + delta;
yss  = rkss/(mcss*alpha_u);
s_i  = delta/yss;
s_c  = 1 - s_i - target_energy_share_out;
css  = yss - delta - target_energy_share_out*yss;
wss  = mcss*(1-alpha_u)*yss/nbar;
lambdass = (1-beta*hab)*(css*(1-hab))^(-sigma);
xi_k = beta*rkss;

kappa_p = (epsilon-1)/phiP;
kappa_w = (1-theta_w)*(1-beta*theta_w)/(theta_w*(1+eps_w*varphi));

// choose Rotemberg wage cost to match the linear wage-PC slope
phiW = (eps_w-1)/kappa_w;

model;

// --------------------------------------------------
// Exogenous processes
// --------------------------------------------------
g = gexo;
a = a(-1) + g;

po = rho_po*po(-1) + e_po;
cp = rho_cp*cp(-1) + e_cp;

// --------------------------------------------------
// Energy price index
// Alternative energy price is fixed at 1 in consumption goods
// po is the log deviation of the oil price from steady state
// pe is the log deviation of the CES energy price index
// --------------------------------------------------
exp(pe) = (omega_o*exp((1-eta_e)*po) + (1-omega_o))^(1/(1-eta_e));

// --------------------------------------------------
// Sticky-price, sticky-wage economy
// --------------------------------------------------

// Investment adjustment cost terms
# xI   = exp(inv - inv(-1));
# SI   = (phiI/2)*(xI - 1)^2;
# dSI  = phiI*(xI - 1);
# xI1  = exp(inv(+1) - inv);
# dSI1 = phiI*(xI1 - 1);

// Labor hiring adjustment cost terms
# N     = nbar*exp(n);
# Nlag  = nbar*exp(n(-1));
# Nlead = nbar*exp(n(+1));
# HN    = (psi_n/2)*(N - Nlag)^2;

// Marginal utility with external habit
exp(uc) = ((exp(c) - hab*exp(c(-1)))/(1-hab))^(-sigma);

// Habit-adjusted multiplier
exp(lambda) = (exp(uc) - beta*hab*exp(uc(+1)))/(1-beta*hab);

// Bond Euler
exp(lambda) = exp(lambda(+1) + R - pi(+1));

// q-Euler for installed capital
exp(q + lambda) = beta*exp(lambda(+1))*(rkss*exp(rk(+1)) + (1-delta)*exp(q(+1)));

// Investment FOC
1 = exp(q)*(1 - SI - xI*dSI)
    + beta*exp(lambda(+1)-lambda + q(+1))*dSI1*xI1^2;

// Capital accumulation
exp(k) = (1-delta)*exp(k(-1)) + delta*(1 - SI)*exp(inv);

// Production
y = a + alpha_u*(u + k(-1)) + (1-alpha_u)*n;

// Labor demand / wage from firm side with hiring adjustment costs
wss*exp(w) =
    wss*exp(mc + y - n)
    - psi_n*(N - Nlag)
    + beta*exp(lambda(+1)-lambda)*psi_n*(Nlead - N);

// Rental rate of capital
rk = mc + y - k(-1);

// Utilization FOC: energy price index with capital scaling
pe = mc + y - k(-1) - zeta*u;

// Household labor supply / target real wage
wstar = varphi*n - lambda;

// Wage markup gap
muw = w - wstar;

// Rotemberg wage Phillips curve with backward indexation
0 = (1-eps_w)
    + (eps_w-1)*exp(wstar - w)
    - phiW*(exp(piw - iota_w*piw(-1)) - 1)*exp(piw - iota_w*piw(-1))*exp(iota_w*piw(-1))
    + beta*phiW*exp(lambda(+1)-lambda + n(+1)-n)
        *(exp(piw(+1) - iota_w*piw) - 1)*exp(piw(+1) - iota_w*piw)*exp(iota_w*piw);

// Real wage identity
w = w(-1) + piw - pi;

// Resource constraint with oil-export rebate, energy expenditure, and hiring costs
yss*exp(y) + yss*s_oilnet*(exp(po)-1) = css*exp(c)
                                        + delta*exp(inv)
                                        + yss*target_energy_share_out*exp(mc + y)
                                        + HN
                                        + (phiP/2)*(exp(pi)-1)^2 * yss*exp(y);

// Rotemberg price Phillips curve with backward indexation
0 = (1-epsilon)
    + (epsilon-1)*exp(mc)
    - phiP*(exp(pi - iota_p*pi(-1)) - 1)*exp(pi - iota_p*pi(-1))*exp(iota_p*pi(-1))
    + beta*phiP*exp(lambda(+1)-lambda + y(+1)-y)
        *(exp(pi(+1) - iota_p*pi) - 1)*exp(pi(+1) - iota_p*pi)*exp(iota_p*pi)
    + cp;

// Output gap
ygap = y - yn;

// Taylor rule for gross nominal rate deviation
exp(R) = exp(rho_R*R(-1))
         * exp((1-rho_R)*(phi_pi*pi + phi_x*ygap + use_nat*phi_r*rn))
         * exp(eR);

// --------------------------------------------------
// Natural economy
// --------------------------------------------------

// Natural investment adjustment cost terms
# xI_nat   = exp(invn - invn(-1));
# SI_nat   = (phiI/2)*(xI_nat - 1)^2;
# dSI_nat  = phiI*(xI_nat - 1);
# xI1_nat  = exp(invn(+1) - invn);
# dSI1_nat = phiI*(xI1_nat - 1);

// Natural labor hiring adjustment cost terms
# N_nat     = nbar*exp(nn);
# Nlag_nat  = nbar*exp(nn(-1));
# Nlead_nat = nbar*exp(nn(+1));
# HN_nat    = (psi_n/2)*(N_nat - Nlag_nat)^2;

// Natural marginal utility
exp(ucn) = ((exp(cn) - hab*exp(cn(-1)))/(1-hab))^(-sigma);

// Natural multiplier
exp(lambdan) = (exp(ucn) - beta*hab*exp(ucn(+1)))/(1-beta*hab);

// Natural real rate
rn = lambdan - lambdan(+1);

// Natural q-Euler
exp(qn + lambdan) = beta*exp(lambdan(+1))*(rkss*exp(rkn(+1)) + (1-delta)*exp(qn(+1)));

// Natural investment FOC
1 = exp(qn)*(1 - SI_nat - xI_nat*dSI_nat)
    + beta*exp(lambdan(+1)-lambdan + qn(+1))*dSI1_nat*xI1_nat^2;

// Natural capital accumulation
exp(kn) = (1-delta)*exp(kn(-1)) + delta*(1 - SI_nat)*exp(invn);

// Natural output
yn = a + alpha_u*(un + kn(-1)) + (1-alpha_u)*nn;

// Natural marginal cost
mcn = 0;

// Natural wage from firm side with hiring adjustment costs
wss*exp(wn) =
    wss*exp(mcn + yn - nn)
    - psi_n*(N_nat - Nlag_nat)
    + beta*exp(lambdan(+1)-lambdan)*psi_n*(Nlead_nat - N_nat);

// Natural rental rate
rkn = mcn + yn - kn(-1);

// Natural utilization: same energy price index, with capital scaling
pe = mcn + yn - kn(-1) - zeta*un;

// Natural labor supply
wn = varphi*nn - lambdan;

// Natural resource constraint with oil-export rebate, energy expenditure, and hiring costs
yss*exp(yn) + yss*s_oilnet*(exp(po)-1) = css*exp(cn)
                                         + delta*exp(invn)
                                         + yss*target_energy_share_out*exp(mcn + yn)
                                         + HN_nat;

end;

initval;
c = 0; n = 0; u = 0; k = 0; inv = 0; y = 0; a = 0; g = 0;
pi = 0; piw = 0; R = 0; mc = 0; w = 0; rk = 0; lambda = 0; uc = 0;
wstar = 0; muw = 0; q = 0;
cn = 0; nn = 0; un = 0; kn = 0; invn = 0; yn = 0; rn = 0; rkn = 0;
lambdan = 0; ucn = 0; wn = 0; mcn = 0; qn = 0;
ygap = 0; po = 0; pe = 0; cp = 0;
e_po = 0; e_cp = 0; eR = 0; gexo = 0;
end;

endval;
c = 0; n = 0; u = 0; k = 0; inv = 0; y = 0; a = 0; g = 0;
pi = 0; piw = 0; R = 0; mc = 0; w = 0; rk = 0; lambda = 0; uc = 0;
wstar = 0; muw = 0; q = 0;
cn = 0; nn = 0; un = 0; kn = 0; invn = 0; yn = 0; rn = 0; rkn = 0;
lambdan = 0; ucn = 0; wn = 0; mcn = 0; qn = 0;
ygap = 0; po = 0; pe = 0; cp = 0;
e_po = 0; e_cp = 0; eR = 0; gexo = 0;
end;

resid;
steady;
check;