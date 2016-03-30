function [y,x_,tx] = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
% simForwardEuler - Integrates sss model using forward (explicit) Euler
% 
% Syntax:
%       y = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
%       [y,x_] = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
%       [y,x_,tx] = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
%
% Description:
%       Integrates sss model using forward (explicit) Euler 
% 
% Input Arguments:       
%       -A,B,C,D,E:     state-space matrices
%       -u:             input vector/matrix with dimension Nsample x Ninput
%       -x:             initial state vector for time integration
%       -Ts:            sampling time
%       -Ts_sample:     sampling time for matrix of state-vectors
%       -isDescriptor:  isDescriptor-boolean
%
% Output Arguments:      
%       -y: output vector
%       -x_: matrix of state vectors
%       -tx: time vector for x_
%
% See Also: 
%       sim, simBackwardEuler, simRK4
%
% References:
%       * *[1] Gear (1971)*, Numerical Initial Value Problems in 
%       Ordinary Differential Equations.
%       * *[2] Shampine (1994)*, Numerical Solution of Ordinary Differential Equations, 
%       Chapman & Hall, New York.
%       * *[3] Shampine and Gordon (1975)*, Computer Solution of Ordinary Differential 
%       Equations: the Initial Value Problem, W. H. Freeman, San Francisco.
%
%------------------------------------------------------------------
% This file is part of <a href="matlab:docsearch sss">sss</a>, a Sparse State-Space and System Analysis 
% Toolbox developed at the Chair of Automatic Control in collaboration
% with the Chair of Thermofluid Dynamics, Technische Universitaet Muenchen. 
% For updates and further information please visit <a href="https://www.rt.mw.tum.de/">www.rt.mw.tum.de</a>
% For any suggestions, submission and/or bug reports, mail us at
%                   -> <a href="mailto:sssMOR@rt.mw.tum.de">sssMOR@rt.mw.tum.de</a> <-
%
% More Toolbox Info by searching <a href="matlab:docsearch sssMOR">sssMOR</a> in the Matlab Documentation
%
%------------------------------------------------------------------
% Authors:      Stefan Jaensch, Maria Cruz Varona 
% Email:        <a href="mailto:sssMOR@rt.mw.tum.de">sssMOR@rt.mw.tum.de</a>
% Website:      <a href="https://www.rt.mw.tum.de/">www.rt.mw.tum.de</a>
% Work Adress:  Technische Universitaet Muenchen
% Last Change:  05 Nov 2015
% Copyright (c) 2015 Chair of Automatic Control, TU Muenchen
%------------------------------------------------------------------

y = zeros(size(C,1),size(u,1));
if nargout == 1
    x_ = [];
    m=inf;
else
    m = round(Ts_sample/Ts);
    x_ = zeros(length(A),round(size(u,1)/m));    
    k = 1;
    index = [];
end

y(:,1) = C*x + D*u(1,:)';
ETsA = E+Ts*A; TsB = Ts*B;
if isDescriptor
    [L,U,p] = lu(E,'vector');
end

for i = 2:size(u,1)    
    if ~isDescriptor
        x = ETsA*x + TsB*u(i-1,:)';
    else
        x = ETsA*x + TsB*u(i-1,:)';
        x = U\(L\(x(p,:)));
    end
    y(:,i) = C*x + D*u(i,:)';
    if ~isempty(x_)
        if mod(i,m) == 0
            x_(:,k) = x;
            index = [index i];
            k = k+1;            
        end
    end
end
if m==inf
    x_ = x;
    index = size(u,1);
end
if nargout>1
    tx = index*Ts;
end