function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(44)=x(1);
  y(43)=y(44)+y(7);
  y(70)=params(20)*y(34)+x(2);
  y(72)=params(21)*y(36)+x(3);
end
