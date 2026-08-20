function [T_order, T] = dynamic_g1_tt(y, x, params, steady_state, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = oil_nonlinear_kstickyEPF_export3_sf.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
T_order = 1;
if size(T, 1) < 48
    T = [T; NaN(48 - size(T, 1), 1)];
end
T(21) = (-(params(13)*exp(y(1))))/(1-params(13));
T(22) = getPowerDeriv(T(3),(-params(2)),1);
T(23) = exp(y(37))/(1-params(13));
T(24) = T(5)*(T(5)-1)*params(1)*params(5)*(-exp(y(74)+y(87)-y(51)-y(38)));
T(25) = (-(exp(y(46)*params(39))*T(24)));
T(26) = (-(exp(y(55))*((-(T(1)*(-exp(y(41)-y(5)))*2*(exp(y(41)-y(5))-1)))-(params(33)*(exp(y(41)-y(5))-1)*(-exp(y(41)-y(5)))+exp(y(41)-y(5))*params(33)*(-exp(y(41)-y(5)))))));
T(27) = exp(y(55))*((-(T(1)*exp(y(41)-y(5))*2*(exp(y(41)-y(5))-1)))-(exp(y(41)-y(5))*params(33)*(exp(y(41)-y(5))-1)+exp(y(41)-y(5))*exp(y(41)-y(5))*params(33)));
T(28) = (-exp(y(77)-y(41)))*2*exp(y(77)-y(41));
T(29) = exp(y(77)-y(41))*2*exp(y(77)-y(41));
T(30) = T(10)*(T(10)-1)*params(1)*params(4)*(-exp(y(87)-y(51)+y(78)-y(42)));
T(31) = (-(exp(y(45)*params(38))*T(30)));
T(32) = params(4)*(exp(y(45)-params(38)*y(9))-1)*exp(y(45)-params(38)*y(9))*(-params(38))+exp(y(45)-params(38)*y(9))*params(4)*exp(y(45)-params(38)*y(9))*(-params(38));
T(33) = (-(exp(y(42))*params(23)*params(4)/2*exp(y(45))*2*(exp(y(45))-1)));
T(34) = params(1)*params(4)*exp(y(87)-y(51)+y(78)-y(42))*(T(10)-1)*T(10)*(-params(38))+T(10)*params(1)*params(4)*exp(y(87)-y(51)+y(78)-y(42))*T(10)*(-params(38));
T(35) = exp(y(45)*params(38))*T(34)+T(11)*params(38)*exp(y(45)*params(38));
T(36) = (-(exp(y(45)*params(38))*(T(11)+T(10)*params(1)*params(4)*exp(y(87)-y(51)+y(78)-y(42))*T(10))));
T(37) = params(5)*(exp(y(46)-params(39)*y(10))-1)*exp(y(46)-params(39)*y(10))*(-params(39))+exp(y(46)-params(39)*y(10))*params(5)*exp(y(46)-params(39)*y(10))*(-params(39));
T(38) = params(1)*params(5)*exp(y(74)+y(87)-y(51)-y(38))*(T(5)-1)*T(5)*(-params(39))+T(5)*params(1)*params(5)*exp(y(74)+y(87)-y(51)-y(38))*T(5)*(-params(39));
T(39) = exp(y(46)*params(39))*T(38)+T(6)*params(39)*exp(y(46)*params(39));
T(40) = (-(exp(y(46)*params(39))*(T(6)+T(5)*params(1)*params(5)*exp(y(74)+y(87)-y(51)-y(38))*T(5))));
T(41) = (-(params(13)*exp(y(20))))/(1-params(13));
T(42) = getPowerDeriv(T(14),(-params(2)),1);
T(43) = exp(y(56))/(1-params(13));
T(44) = (-(exp(y(68))*((-(T(1)*(-exp(y(60)-y(24)))*2*(exp(y(60)-y(24))-1)))-(params(33)*(exp(y(60)-y(24))-1)*(-exp(y(60)-y(24)))+exp(y(60)-y(24))*params(33)*(-exp(y(60)-y(24)))))));
T(45) = exp(y(68))*((-(T(1)*exp(y(60)-y(24))*2*(exp(y(60)-y(24))-1)))-(exp(y(60)-y(24))*params(33)*(exp(y(60)-y(24))-1)+exp(y(60)-y(24))*params(33)*exp(y(60)-y(24))));
T(46) = (-exp(y(96)-y(60)))*2*exp(y(96)-y(60));
T(47) = exp(y(96)-y(60))*2*exp(y(96)-y(60));
T(48) = getPowerDeriv(params(36)*exp(y(70)*(1-params(37)))+1-params(36),1/(1-params(37)),1);
end
