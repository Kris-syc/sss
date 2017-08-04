function [y,x_,tx] = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
% simForwardEuler - Integrates sss model using forward (explicit) Euler
% 
% Syntax:
%       y           = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
%       [y,x_]      = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
%       [y,x_,tx]   = simForwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor)
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
% Authors:      Stefan Jaensch, Maria Cruz Varona, Alessandro Castagnotto
% Email:        <a href="mailto:sssMOR@rt.mw.tum.de">sssMOR@rt.mw.tum.de</a>
% Website:      <a href="https://www.rt.mw.tum.de/">www.rt.mw.tum.de</a>
% Work Adress:  Technische Universitaet Muenchen
% Last Change:  04 Aug 2017
% Copyright (c) 2015-2017 Chair of Automatic Control, TU Muenchen
%------------------------------------------------------------------

%% Initialize variables using common function for all simulation methods
%  Note: using one common simulation function having the methods as nested
%  functions would be much better. Due to historical reasons, the
%  simulation functions not have their present form. Later releases may
%  include some significant restructuring. 

argin = {A,B,C,D,E,u,x,Ts,Ts_sample,isDescriptor};

[y,x_,m,k,index,L,U,p] = simInit(argin{:},nargin==1); %common function

%% Run simulation

ETsA = E+Ts*A; TsB = Ts*B;
for i = 2:size(u,1)    
    if ~isDescriptor
        x = ETsA*x + TsB*u(i-1,:)';
    else
        x = ETsA*x + TsB*u(i-1,:)';
        x = U\(L\(x(p,:)));
    end
    [y,x_,k,index] = simUpdate(y,x_,k,index,x,u,i,m,C,D); %common function
end
tx = (index-1)*Ts;
