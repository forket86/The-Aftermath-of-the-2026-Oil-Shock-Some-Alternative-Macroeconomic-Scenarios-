function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 20
    T = [T; NaN(20 - size(T, 1), 1)];
end
T(1) = params(33)/2;
T(2) = params(15)/2;
T(3) = (exp(y(37))-params(13)*exp(y(1)))/(1-params(13));
T(4) = exp(y(46)-params(39)*y(10))*params(5)*(exp(y(46)-params(39)*y(10))-1);
T(5) = exp(y(82)-y(46)*params(39));
T(6) = T(5)*params(1)*params(5)*exp(y(74)+y(87)-y(51)-y(38))*(T(5)-1);
T(7) = T(6)*exp(y(46)*params(39));
T(8) = exp(y(42))*params(23)*params(4)/2*(exp(y(45))-1)^2;
T(9) = exp(y(45)-params(38)*y(9))*params(4)*(exp(y(45)-params(38)*y(9))-1);
T(10) = exp(y(81)-y(45)*params(38));
T(11) = T(10)*params(1)*params(4)*exp(y(87)-y(51)+y(78)-y(42))*(T(10)-1);
T(12) = T(11)*exp(y(45)*params(38));
T(13) = exp((1-params(9))*(y(45)*params(10)+y(69)*params(11)+params(14)*params(12)*y(62)));
T(14) = (exp(y(56))-params(13)*exp(y(20)))/(1-params(13));
T(15) = exp(y(77)-y(41))^2;
T(16) = exp(y(96)-y(60))^2;
T(17) = 1-T(1)*(exp(y(41)-y(5))-1)^2;
T(18) = params(1)*exp(y(91)+y(87)-y(51))*params(33)*(exp(y(77)-y(41))-1);
T(19) = 1-T(1)*(exp(y(60)-y(24))-1)^2;
T(20) = params(1)*exp(y(104)+y(100)-y(64))*params(33)*(exp(y(96)-y(60))-1);
end
