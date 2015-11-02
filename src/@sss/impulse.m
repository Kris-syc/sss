function  [h, t] = impulse(sys, varargin)
% Computes and/or plots the impulse response of a sparse LTI system
% ------------------------------------------------------------------
% [h, t] = impulse(sys, varargin)
% Inputs:       * sys: an sss-object containing the LTI system
%    [optional] * vector of time values to plot at
%               * plot options. see <a href="matlab:help plot">PLOT</a>
% Outputs:      * h, t: vectors containing impulse response and time vector
% ------------------------------------------------------------------
% This file is part of the MORLAB_GUI, a Model Order Reduction and
% System Analysis Toolbox developed at the
% Institute of Automatic Control, Technische Universitaet Muenchen
% For updates and further information please visit www.rt.mw.tum.de
% ------------------------------------------------------------------
% Authors:      Heiko Panzer (heiko@mytum.de), Sylvia Cremer
% Last Change:  02 Dec 2011
% ------------------------------------------------------------------

% are poles and residues already available?
if ~isempty(sys.poles) && ~isempty(sys.residues)
    p=sys.poles;
    res=sys.residues;
else
    [res,p]=residue(sys);
    % store system to caller workspace
    if inputname(1)
        assignin('caller', inputname(1), sys);
    end
end

options=varargin;
if nargin>1 && strcmp(class(options{1}), 'double')
    t=varargin{1};
    options(1)=[];
end

% is time vector given?
if exist('t', 'var') && ~isempty(t)
    % calculate impulse response
    h=cellfun(@(x) sum((diag(x)*conj(exp(t'*p))'),1),res,'UniformOutput',false);
    h=cellfun(@real,h,'UniformOutput',false);
    
else
    % no, retrieve time values automatically
    
    % is decayTime already available?
    if ~isempty(sys.decayTime)
        tmax = sys.decayTime;
    else
        tmax = decay_time(sys);
        % store system to caller workspace
        if inputname(1)
            assignin('caller', inputname(1), sys);
        end        
    end
    delta = tmax/999;
    t = 0:delta:tmax;

    % calculate impulse response
%     cellfun(@(x) sum((diag(x)*conj(exp(t'*p))'),1),res,'UniformOutput',false);
    h=cellfun(@(x)   sum(diag(x)*transpose(exp(t'*p)),1),res,'UniformOutput',false);
    h=cellfun(@real,h,'UniformOutput',false);

    % increase resolution as long as rel. step size is too large
    ex=1;
    while 1
        refine=0;
        for i=1:sys.p
            for j=1:sys.m
                m=h{i,j};
                for k=2:length(m)-1
                    if abs(abs(m(k)) - abs(m(k+1)))/(abs(m(k)) + abs(m(k+1))) > 0.5
                        delta=delta/2;
                        t=0:delta:tmax;
                        t_temp=t(2:2:end);
                        temp=cellfun(@(x) sum((diag(x)*conj(exp(t_temp'*p))'),1),res,'UniformOutput',false);
                        temp=cellfun(@real,temp,'UniformOutput',false);
                        h=cellfun(@(x,y) [reshape([x(1:length(x)-1); y],1,2*length(x)-2),x(end)],h,temp,'UniformOutput',false);
                        refine=1;
                        break
                    end
                end
                if refine
                    break
                end
            end
            if refine
                break
            end
        end
        if ~refine
            break
        end
        ex=ex+1;
        if ex==5 
            break
        end
    end
end

if nargout>0
    return
end

% --------------- PLOT ---------------

% set random color if figure is not empty
fig_handle=gcf;
if isempty(options)
    if ~isempty(get(fig_handle, 'Children'))
        c=rand(3,1); c=c/norm(c);
        options = {'Color', c};
    end
end

axes_handle=zeros(sys.p,sys.m);
for i=1:sys.p
    for j=1:sys.m
        axes_handle(i,j)=subplot(sys.p,sys.m,(j-1)*sys.p+i);
        hold on;
        
        if j==1 && sys.p>1
            y_lab=sprintf('To Out(%i)',ceil(i/2));
            ylabel(y_lab)
        end
        if i==1 && sys.m>1
            x_lab=sprintf('From In(%i)',j);
            title(x_lab)
        end
        
        plot(t, h{i,j}, options{:});
        mx=max(h{i,j}); mn=min(h{i,j});
        if mx==0 && mn==0
            mx=1; mn=-1;
        end
        set(gca, 'XLim', [0 max(t)], 'YLim', [mn-(mx-mn)/20, mx+(mx-mn)/20]);

        ylabel('Impulse response g(t)') 
        xlabel('Time t') 
        
    end
end

% avoid output
clear h t


    