function [T_order, T] = dynamic_g2_tt(y, x, params, steady_state, T_order, T)
if T_order >= 2
    return
end
[T_order, T] = oil_nonlinear_kstickyEPF_export3_sf.dynamic_g1_tt(y, x, params, steady_state, T_order, T);
T_order = 2;
if size(T, 1) < 56
    T = [T; NaN(56 - size(T, 1), 1)];
end
T(49) = getPowerDeriv(T(3),(-params(2)),2);
T(50) = (-(T(1)*(exp(y(41)-y(5))*2*(exp(y(41)-y(5))-1)+(-exp(y(41)-y(5)))*2*(-exp(y(41)-y(5))))));
T(51) = (-(T(1)*((-exp(y(41)-y(5)))*2*(exp(y(41)-y(5))-1)+(-exp(y(41)-y(5)))*2*exp(y(41)-y(5)))));
T(52) = (-(T(24)*params(39)*exp(y(46)*params(39))+exp(y(46)*params(39))*((T(5)-1)*params(1)*params(5)*(-exp(y(74)+y(87)-y(51)-y(38)))*T(5)*(-params(39))+T(5)*params(1)*params(5)*(-exp(y(74)+y(87)-y(51)-y(38)))*T(5)*(-params(39)))));
T(53) = (-(T(30)*params(38)*exp(y(45)*params(38))+exp(y(45)*params(38))*((T(10)-1)*params(1)*params(4)*(-exp(y(87)-y(51)+y(78)-y(42)))*T(10)*(-params(38))+T(10)*params(1)*params(4)*(-exp(y(87)-y(51)+y(78)-y(42)))*T(10)*(-params(38)))));
T(54) = getPowerDeriv(T(14),(-params(2)),2);
T(55) = (-(T(1)*(exp(y(60)-y(24))*2*(exp(y(60)-y(24))-1)+(-exp(y(60)-y(24)))*2*(-exp(y(60)-y(24))))));
T(56) = (-(T(1)*((-exp(y(60)-y(24)))*2*(exp(y(60)-y(24))-1)+(-exp(y(60)-y(24)))*2*exp(y(60)-y(24)))));
end
