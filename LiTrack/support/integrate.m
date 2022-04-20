        function s = integrate(x,y,x1,x2)

%       s = integrate(x,y[,x1,x2]);
%
%       Approximate the integral of the function y(x) over x from x1 to 
%       x2.  The limits of integration are given by the optional inputs
%       x1 and x2.  If they are not given the integration will range from
%       x(1) to x(length(x)) (i.e. the whole range of the vector x).
%
%     INPUTS:   x:      The variable to integrate over (row or column
%                       vector of sequential data points)
%               y:      The function to integrate (row or column vector)
%               x1:     (Optional,DEF=x(1)) The integration starting point
%               x2:     (Optional,DEF=x(n)) The integration ending point

%===============================================================================

if any(diff(x)<0);
  error('x must be sequentially ordered data')
end
  
x = x(:);
y = y(:);

[ny,cy] = size(y);
[nx,cx] = size(x);

if (cx > 1) | (cy > 1)
  error('INTEGRATE only works for vectors')
end
if nx ~= ny
  error('Vectors must be the same length')
end

if ~exist('x2')
  i2 = nx;
  if ~exist('x1')
    i1 = 1;
  else
    [dum,i1] = min(abs(x-x1));
  end
else
  [dum,i1] = min(abs(x-x1));
  [dum,i2] = min(abs(x-x2));
end

dx = diff(x(i1:i2));
s = sum(dx.*y(i1:(i2-1)));
