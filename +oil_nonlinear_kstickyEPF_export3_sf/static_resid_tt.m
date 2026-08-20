function [T_order, T] = static_resid_tt(y, x, params, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 4
    T = [T; NaN(4 - size(T, 1), 1)];
end
T(1) = (exp(y(1))-exp(y(1))*params(13))/(1-params(13));
T(2) = exp(y(6))*params(23)*params(4)/2*(exp(y(9))-1)^2;
T(3) = exp((1-params(9))*(y(9)*params(10)+y(33)*params(11)+params(14)*params(12)*y(26)));
T(4) = (exp(y(20))-params(13)*exp(y(20)))/(1-params(13));
end
