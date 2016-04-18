function  varargout = step(varargin)
% STEP - Computes and/or plots the step response of a sparse LTI system
%
% Syntax:
%       STEP(sys)
%       [h, t] = STEP(sys)
%       [h, t] = STEP(sys, t)
%       [h, t] = STEP(sys, t, opts)
%
% Description:
%       step(sys) plots the step response of the sparse LTI system sys
%
%       [h, t] = step(sys, t) computes the step response of the sparse LTI
%       system sys and returns the vectors h and t with the response and
%       the time series, respectively.
%
% Input Arguments:
%       *Required Input Arguments:*
%       -sys: an sss-object containing the LTI system
%       *Optional Input Arguments:*
%       -t:     vector of time values to plot at
%       -opts:  plot options, see <a href="matlab:help plot">PLOT</a>
%
% Output Arguments:
%       -h, t: vectors containing step response and time vector
%
% Examples:
%       The following code plots the step response of the benchmark
%       'CDplayer' (SSS, MIMO):
%
%> load CDplayer.mat
%> sys=sss(A,B,C);
%> step(sys);
%
% See Also:
%       residue, impulse
%
%------------------------------------------------------------------
% This file is part of <a href="matlab:docsearch sss">sss</a>, a Sparse State-Space and System Analysis
% Toolbox developed at the Chair of Automatic Control in collaboration
% with the Professur fuer Thermofluiddynamik, Technische Universitaet Muenchen.
% For updates and further information please visit <a href="https://www.rt.mw.tum.de/?sss">www.rt.mw.tum.de/?sss</a>
% For any suggestions, submission and/or bug reports, mail us at
%                   -> <a href="mailto:sss@rt.mw.tum.de">sss@rt.mw.tum.de</a> <-
%
% More Toolbox Info by searching <a href="matlab:docsearch sss">sss</a> in the Matlab Documentation
%
%------------------------------------------------------------------
% Authors:      Heiko Panzer, Sylvia Cremer, Jorge Luiz Moreira Silva
% Email:        <a href="mailto:sss@rt.mw.tum.de">sss@rt.mw.tum.de</a>
% Website:      <a href="https://www.rt.mw.tum.de/?sss">www.rt.mw.tum.de/?sss</a>
% Work Adress:  Technische Universitaet Muenchen
% Last Change:  10 Nov 2015
% Copyright (c) 2015 Chair of Automatic Control, TU Muenchen
%------------------------------------------------------------------

% Make sure the function is used in a correct way before running compts.
nSys = 0;
for iInp = 1:length(varargin)
    if isa(varargin{iInp},'sss') || isa(varargin{iInp},'ss')  ...
            || isa(varargin{iInp},'tf') || isa(varargin{iInp},'zpk') ...
            || isa(varargin{iInp},'frd') || isa(varargin{iInp},'idtf')...
            || isa(varargin{iInp},'idpoly') || isa(varargin{iInp},'idfrd') ...
            || isa(varargin{iInp},'idss')
        nSys = nSys+1;
    end
end
if nSys > 1 && nargout
    error('sss:step:RequiresSingleModelWithOutputArgs',...
        'The "step" command operates on a single model when used with output arguments.');
end

%% Parse inputs and options
Def.odeset = odeset;
Def.tolOutput = 1e-3; % Terminate if norm(y_-yFinal)/norm(yFinal)<tolOutput with yFinal = C*xFinal+D;
Def.tolState = 1e-3; % Terminate if norm(x-xFinal)/norm(xFinal)<tolState with xFinal = -(A\B);
Def.tf = 0; %return [h, t] instead of tf object as in bult-in case
Def.ode = 'ode45';
Def.nMin = 1000;

% create the options structure
if ~isempty(varargin) && isstruct(varargin{end})
    Opts = varargin{end};
    varargin = varargin(1:end-1);
end
if ~exist('Opts','var') || isempty(Opts)
    Opts = Def;
else
    Opts = parseOpts(Opts,Def);
end


% final Time
t = [];
tIndex = cellfun(@isfloat,varargin);
if ~isempty(tIndex) && nnz(tIndex)
    t = varargin{tIndex};
    varargin(tIndex)=[];
end

Tfinal = 0;
for i = 1:length(varargin)
    % Set name to input variable name if not specified
    if isprop(varargin{i},'Name')
        if isempty(varargin{i}.Name) % Cascaded if is necessary && does not work
            varargin{i}.Name = inputname(i);
        end
    end
    
    % Convert sss to frequency response data model
    if isa(varargin{i},'sss')
        [TF_,t_] = gettf(varargin{i}, t, Opts);
        varargin{i} = TF_;
    else
        varargin{i} = ss(varargin{i});
    end
    Tfinal = max(t_(end),Tfinal);
end
    
% Call ss/step
if nargout==1 && Opts.tf
    varargout{1} = TF_;
elseif nargout
    [varargout{1},varargout{2},varargout{3},varargout{4}] = step(varargin{:},Tfinal);
    if ~isempty(t)        
        varargout{1} = interp1(varargout{2},varargout{1},t,'spline');
        varargout{2} = t;
    end
else
    step(varargin{:},Tfinal);
end


end
function [TF,ti] = gettf(sys, t, Opts)

t = t(:);
if sys.n > Opts.nMin
    h = [];
    th = {};
    for i = 1:sys.m
        sys_ = truncate(sys,1:sys.p,i);
        [h_,th{i}] = stepLocal(sys_, t, Opts);
        h = [h h_];
    end
    
    tMin = max(cellfun(@min,th));
    tMax = min(cellfun(@max,th));
    tN = max(cellfun(@length,th));
    ti = linspace(tMin,tMax,tN)';
   
    for i = 1:size(h,1)
        for j = 1:size(h,2)
            h{i,j} = interp1(th{j},h{i,j},ti');
        end
    end
else
    [h_,ti] = step(ss(sys),t);
    h = {};
    for i = 1:size(h_,2)
        for j = 1:size(h_,3)
            h{i,j} = squeeze(h_(:,i,j))';
        end
    end
end

Ts = min(diff(ti));
h = cellfun(@(x) [x(1) diff(x)],h,'UniformOutput',false);

TF = filt(h,1,Ts,...
    'InputName',sys.InputName,'OutputName',sys.OutputName,...
    'Name',sys.Name);
end
function [h,te] = stepLocal(sys, t, Opts)
x0 = zeros(size(sys.x0));
optODE = Opts.odeset;
[A,B,C,D,E,~] = dssdata(sys);

if ~sys.isDescriptor
    odeFun = @(t,x) A*x+B;
else
    odeFun = @(t,x) E\(A*x+B);
end
if ~isempty(t)
    xFinal = [];
    yFinal = [];
    tSim = [t(1),mean(t),t(end)];
else
    xFinal = -(A\B);
    yFinal = C*xFinal+D;
    tSim = [0,inf];
    optODE.OutputFcn = @(t,x,flag) outputFcn(t,x,flag,C,D,xFinal...
        ,yFinal,Opts.tolOutput,Opts.tolState);
end
te = []; h = te;
optODE.Events = @(t,x) eventsFcnT(t,x,C,D);

switch Opts.ode
    case 'ode113'
        [~,~] = ode113(odeFun,tSim,x0,optODE);
    case 'ode15s'
        [~,~] = ode15s(odeFun,tSim,x0,optODE);
    case 'ode23'
        [~,~] = ode23(odeFun,tSim,x0,optODE);
    case 'ode45'
        [~,~] = ode45(odeFun,tSim,x0,optODE);
    otherwise
        error(['The ode solver ' Opts.ode ' is currently not implemented. '  ...
            'Implemented solvers are: ode113, ode15s, ode23, ode45'])
end


h = mat2cell(h,size(h,1),ones(1,size(h,2)));
h = h';
    function [value,isterminal,direction]  = eventsFcnT(t,x,C,D)
        value = 1;
        isterminal = 0;
        direction = [];
        y_ = full(C*x+D);
        h = [h; y_'];
        te = [te; t];
    end
end
function status = outputFcn(t,x,flag,C,D,xFinal,yFinal,tolOutput,tolState)
status = 0;
if isempty(x)
    return
end

x = x(:,end);
y_ = full(C*x+D);
if ~isempty(xFinal)
    y_ = full(C*x+D);
    if norm(y_-yFinal)/norm(yFinal)<tolOutput || ...
            norm(x-xFinal)/norm(xFinal)<tolState
        status = 1;
    end
end
end

