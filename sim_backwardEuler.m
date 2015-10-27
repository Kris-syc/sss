function [y,x_,index] = sim_backwardEuler(A,B,C,D,E,u,x,Ts,Ts_sample)
% Integrates sss model using backward Euler
% ------------------------------------------------------------------
% [y,x_,index] = RK4(A,B,C,D,E,u,x,Ts,Ts_sample,is_dae)
% Inputs:       * A,B,C,D,E: state space matrices
%               * u: input vector in [Nsample,Ninput]
%               * x: start vector for time integration
%               * Ts: Sampling time
%               * Ts_sample: Sampling time for matrix of state-vectors
%               * is_dae: is descriptor
% Outputs:      * y: output vector
%               * X: matrix of state vectors [Optional]
%               * index: time index for X  [Optional]
% ------------------------------------------------------------------
% This file is part of the MORLAB_GUI, a Model Order Reduction and
% System Analysis Toolbox developed at the
% Institute of Automatic Control, Technische Universitaet Muenchen
% For updates and further information please visit www.rt.mw.tum.de
% ------------------------------------------------------------------
% Authors:      Stefan Jaensch (jaensch@tfd.mw.tum.de)
% Last Change:
% ------------------------------------------------------------------
%
% see also: sss/sim, forwardEuler, RK4

y = zeros(size(C,1),size(u,1));
if nargout == 1
    x_ = [];
else
    m = round(Ts_sample/Ts);
    x_ = zeros(length(A),round(size(u,1)/m ));    
    k = 1;
    index = [];
end

% Edx = Ax+Bu
% E (x2-x1) = TsAx2+TsBu2
% (E-TsA)x2 = Ex1 + TsBu2
% x2 = (E-TsA)\ (Ex1 + TsBu2)



y(:,1) = C*x + D*u(1,:)';
ETsA = E-Ts*A; TsB = Ts*B;
[L,U,p] = lu(ETsA,'vector');
for i = 2:size(u,1)
%     x = ETsA\(E*x + TsB*u(i-1,:)');
    g = E*x + TsB*u(i-1,:)';
    x = U\(L\(g(p,:)));

    y(:,i) =C*x  + D*u(i,:)';
    if ~isempty(x_)
        if mod(i,m)==0
            x_(:,k) = x;
            index = [index i];
            k = k+1;            
        end
    end
end