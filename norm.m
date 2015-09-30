function [nrm, varargout] = norm(sys, varargin)
% Computes the p-norm of an LTI system
% ------------------------------------------------------------------
% [nrm, H_inf_peakfreq] = norm(sys, p)
% Inputs:       * sys: an sss-object containing the LTI system
%    [optional] * p: 2 for H_2-norm or inf for H_inf-norm
% Outputs:      * nrm: value of norm
%    [H_inf]    * H_inf_peakfreq: peak frequency of magnitude
% ------------------------------------------------------------------
% This file is part of the MORLAB_GUI, a Model Order Reduction and
% System Analysis Toolbox developed at the
% Institute of Automatic Control, Technische Universitaet Muenchen
% For updates and further information please visit www.rt.mw.tum.de
% ------------------------------------------------------------------
% Authors:      Heiko Panzer (heiko@mytum.de), Sylvia Cremer, Rudy Eid
% Last Change:  03 Feb 2011
% ------------------------------------------------------------------

p=2;    % default: H_2
if nargin>1
    if strcmp(class(varargin{1}), 'double')
        p=varargin{1};
    end
    if strcmp(varargin{1},'inf')
        p=inf;
    end
end

if isinf(p)
    % H_inf-norm
    if isempty(sys.H_inf_norm)
        mag = bode(sys); %#ok<NASGU>
        if nargout>1
            varargout{1}=sys.H_inf_peakfreq;
        end
        if inputname(1)
            assignin('caller', inputname(1), sys);
        end
    end
    nrm=sys.H_inf_norm; 
elseif p==2
    % H_2-norm
    if ~isempty(sys.H_2_norm)
        nrm=sys.H_2_norm;
        return
    end
    % wenn D ~=0 ist H2 norm unendlich gro�
    if any(any(sys.D))
        nrm=inf;
        sys.H_2_norm=inf;
        return
    end

    % see if a Gramian or its Cholesky factor is already available
    if isempty(sys.ConGramChol)
        if isempty(sys.ObsGramChol)
            if isempty(sys.ConGram)
                if isempty(sys.ObsGram)
                    % No, it is not. Solve Lyapunov equation.
                    if sys.is_dae
                        %mit E^-1 durchmultipliziert
                    %     S = lyapchol(sys.A,sys.B,sys.E);
                    %     R = lyapchol(transpose(E\A),C');
                        %Zustandstrafo
                        try
                            try
                                sys.ConGramChol = lyapchol(sys.A,sys.B,sys.E); % P=S'*S3
                                nrm=norm(sys.ConGramChol*sys.C','fro');
                                if ~isreal(nrm)
                                    error('Gramian must be positive definite');
                                end
                            catch ex3 %#ok<NASGU>
                                P = lyapchol(sys.A',sys.C',sys.E');
                                nrm=norm(P*sys.B,'fro');
                            end
                        catch ex
                            warning(ex.identifier, 'Error solving Lyapunov equation. Trying without Cholesky factorization...')
                            try
                                try
                                    X = lyap(sys.A, sys.B*sys.B', [], sys.E);
                                    nrm=sqrt(sys.C*X*sys.C');
                                    if ~isreal(nrm)
                                        error('Gramian must be positive definite');
                                    end
                                catch ex3 %#ok<NASGU>
                                    Y = lyap(sys.A', sys.C'*sys.C, [], sys.E');
                                    nrm=sqrt(sys.B'*Y*sys.B);
                                end
                            catch ex2
                                warning(ex2.message, 'Error solving Lyapunov equation. Premultiplying by E^(-1)...')
                                tmp = sys.E\sys.B;
                                X = lyap(sys.E\sys.A, tmp*tmp');
                                nrm=sqrt(sys.C*X*sys.C');
                            end
                            return
                        end
                    else
                        try
                            sys.ConGramChol = lyapchol(sys.A,sys.B); % P = R'*R
                            nrm=norm(sys.ConGramChol*sys.C','fro');
                        catch ex
                            warning(ex.message, 'Error solving Lyapunov equation. Trying without Cholesky factorization...')
                            sys.ConGram = lyap(sys.A, sys.B*sys.B');                
                            nrm=sqrt(norm(sys.C*sys.ConGram*sys.C'));
                        end
                        
                    end
                else
                    nrm=sqrt(norm(sys.B'*sys.ObsGram*sys.B));
                end
            else
                nrm=sqrt(norm(sys.C*sys.ConGram*sys.C'));
            end
        else
            nrm=norm(sys.ObsGramChol*sys.B, 'fro');
        end
    else
        nrm=norm(sys.ConGramChol*sys.C','fro');
    end
    % L=R'*R;
    % nrm = sqrt(trace(sys.C*L*transpose(sys.C)));
    
    sys.H_2_norm=nrm;
    if inputname(1)
        assignin('caller', inputname(1), sys);
    end
else
    error(['H_' num2str(p) '-norm not implemented.'])
end
