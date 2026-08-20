function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  T(1)=exp(y(71));
  residual(1)=(T(1))-((params(36)*exp(y(70)*(1-params(37)))+1-params(36))^(1/(1-params(37))));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=T(1);
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
