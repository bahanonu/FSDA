function [mdr,Un,BB,Bols,S2,Exflag] = FSRtsmdr(y,bsb,varargin)
%FSRtsmdr computes minimum deletion residual for time series models in each step of the search
%
%<a href="matlab: docsearchFS('FSRtsmdr')">Link to the help function</a>
%
% Required input arguments:
%
%    y:         Response variable. Vector. Response variable, specified as
%               a vector of length n, where n is the number of
%               observations. Each entry in y is the response for the
%               corresponding row of X.
%               Missing values (NaN's) and infinite values (Inf's) are
%               allowed, since observations (rows) with missing or infinite
%               values will automatically be excluded from the
%               computations.
%  X :          Predictor variables. Matrix. Matrix of explanatory
%               variables (also called 'regressors') of dimension n x (p-1)
%               where p denotes the number of explanatory variables
%               including the intercept.
%               Rows of X represent observations, and columns represent
%               variables. By default, there is a constant term in the
%               model, unless you explicitly remove it using input option
%               intercept, so do not include a column of 1s in X. Missing
%               values (NaN's) and infinite values (Inf's) are allowed,
%               since observations (rows) with missing or infinite values
%               will automatically be excluded from the computations.
%  bsb     :    list of units forming the initial subset. Vector. If bsb=0
%               (default) then the procedure starts with p units randomly
%               chosen else if bsb is not 0 the search will start with
%               m0=length(bsb)
%
% Optional input arguments:
%
%  init :       Search initialization. Scalar.
%               It specifies the point where to initialize the search and
%               start monitoring required diagnostics. If it is not
%               specified it is set equal to:
%                   p+1, if the sample size is smaller than 40;
%                   min(3*p+1,floor(0.5*(n+p+1))), otherwise.
%               Example - 'init',100 starts monitoring from step m=100
%               Data Types - double
%  intercept :  Indicator for constant term. Scalar. If 1, a model with
%               constant term will be fitted (default), else no constant
%               term will be included.
%               Example - 'intercept',1
%               Data Types - double
%  plots :      Plot on the screen. Scalar. If equal to one a plot of
%               minimum deletion residual appears  on the screen with 1%,
%               50% and 99% confidence bands else (default) no plot is
%               shown.
%               Example - 'plots',1
%               Data Types - double
%               Remark: the plot which is produced is very simple. In order
%               to control a series of options in this plot and in order to
%               connect it dynamically to the other forward plots it is
%               necessary to use function mdrplot.
%  nocheck:     Check input arguments. Scalar. If nocheck is equal to 1 no check is performed on
%               matrix y and matrix X. Notice that y and X are left
%               unchanged. In other words the additioanl column of ones for
%               the intercept is not added. As default nocheck=0. The
%               controls on h, alpha and nsamp still remain
%               Example - 'nocheck',1
%               Data Types - double
%  msg  :       Level of output to display. Scalar. It controls whether to
%               display or not messages about great interchange on the
%               screen If msg==1 (default)
%               messages are displayed on the screen
%               else no message is displayed on the screen
%               Example - 'msg',1
%               Data Types - double
%  constr :     Constrained search. Vector. r x 1 vector which contains the list of units which are
%               forced to join the search in the last r steps. The default
%               is constr=''.  No constraint is imposed
%               Example - 'constr',[1:10] forces the first 10 units to join
%               the subset in the last 10 steps
%               Data Types - double
% bsbmfullrank :What to do in case subset at step m (say bsbm) produces a
%               non singular X. Scalar.
%               This options controls what to do when rank(X(bsbm,:)) is
%               smaller then number of explanatory variables.
%               If bsbmfullrank = 1 (default is 1) these units (whose number
%               is say mnofullrank) are constrained to enter the search in
%               the final n-mnofullrank steps else the search continues
%               using as estimate of beta at step m the estimate of beta
%               found in the previous step.
%               Example - 'bsbmfullrank',1
%               Data Types - double
%   bsbsteps :  Save the units forming subsets. Vector. It specifies for
%               which steps of the fwd search it
%               is necessary to save the units forming subsets. If bsbsteps
%               is 0 we store the units forming subset in all steps. The
%               default is store the units forming subset in all steps if
%               n<=5000, else to store the units forming subset at steps
%               init and steps which are multiple of 100. For example, as
%               default, if n=753 and init=6,
%               units forming subset are stored for
%               m=init, 100, 200, 300, 400, 500 and 600.
%               Example - 'bsbsteps',[100 200] stores the unis forming
%               subset in steps 100 and 200.
%               Data Types - double
%  Remark:      The user should only give the input arguments that have to
%               change their default value.
%               The name of the input arguments needs to be followed by
%               their value. The order of the input arguments is of no
%               importance.
%
%               Missing values (NaN's) and infinite values (Inf's) are
%               allowed, since observations (rows) with missing or infinite
%               values will automatically be excluded from the
%               computations. y can be both a row of column vector.
%
% Output:
%
%  mdr:          n -init x 2 matrix which contains the monitoring of minimum
%               deletion residual at each step of the forward search.
%               1st col = fwd search index (from init to n-1).
%               2nd col = minimum deletion residual.
%               REMARK: if in a certain step of the search matrix is
%               singular, this procedure checks ohw many observations
%               produce a singular matrix. In this case mdr is a column
%               vector which contains the list of units for which matrix X
%               is non singular.
%  Un:          Units included in each step. Matrix.
%               (n-init) x 11 Matrix which contains the unit(s) included
%               in the subset at each step of the search.
%               REMARK: in every step the new subset is compared with the
%               old subset. Un contains the unit(s) present in the new
%               subset but not in the old one.
%               Un(1,2) for example contains the unit included in step
%               init+1.
%               Un(end,2) contains the units included in the final step
%               of the search.
%  BB:          Units belonging to subset in each step. Matrix.
%               n x (n-init+1) or n-by-length(bsbsteps) matrix (depending on input
%               option bsbsteps) which contains information about the units
%               belonging to the subset at each step of the forward search.
%               BB has the following structure
%               1-st row has number 1 in correspondence of the steps in
%                   which unit 1 is included inside subset and a missing
%                   value for the other steps
%               ......
%               (n-1)-th row has number n-1 in correspondence of the steps in
%                   which unit n-1 is included inside subset and a missing
%                   value for the other steps
%               n-th row has number n in correspondence of the steps in
%                   which unit n is included inside subset and a missing
%                   value for the other steps
%               The size of matrix BB is n x (n-init+1) if option input
%               bsbsteps is 0 else the size is n-by-length(bsbsteps).
%  Bols:        OLS coefficents. Matrix.
%               (n-init+1) x (p+1) matrix containing the monitoring of
%               estimated beta coefficients in each step of the forward
%               search.
%  S2:          S2 and R2. Matrix.
%               (n-init+1) x 3 matrix containing the monitoring of S2 (2nd
%               column)and R2 (third column) in each step of the forward
%               search.
%
% See also: FSR, FSReda
%
% References:
%
% Atkinson, A.C. and Riani, M. (2000), "Robust Diagnostic Regression
% Analysis", Springer Verlag, New York.
% Atkinson, A.C. and Riani, M. (2006), Distribution theory and
% simulations for tests of outliers in regression, "Journal of
% Computational and Graphical Statistics", Vol. 15, pp. 460-476.
% Riani, M. and Atkinson, A.C. (2007), Fast calibrations of the forward
% search for testing multiple outliers in regression, "Advances in Data
% Analysis and Classification", Vol. 1, pp. 123-141.
%
% Copyright 2008-2018.
% Written by FSDA team
%
%
%<a href="matlab: docsearchFS('FSRmdr')">Link to the help function</a>
%
%$LastChangedDate:: 2018-06-21 15:29:09 #$: Date of the last commit

% Examples:

%{
    % FSRmdr with all default options.
    % Compute minimum deletion residual.
    % Monitor minimum deletion residual in each step of the forward search.
    % Common part to all examples: load fishery dataset.
     load('fishery');
     y=fishery.data(:,2);
     X=fishery.data(:,1);
     % Find starting subset
     [out]=LXS(y,X,'nsamp',10000);
     [mdr] = FSRmdr(y,X,out.bs);
     plot(mdr(:,1),mdr(:,2))
     title('Monitoring of minimum deletion residual')
%}

%{
    % FSRmdr with optional arguments.
    % Choose step to start monitoring.
    % Compute minimum deletion residual and start monitoring it from step
    % 60.
     load('fishery');
     y=fishery.data(:,2);
     X=fishery.data(:,1);
     % Find starting subset
     [out]=LXS(y,X,'nsamp',10000);
    [mdr] = FSRmdr(y,X,out.bs,'init',60);
%}

%{
    % Analyze units entering the search in the final steps.
    % Compute minimum deletion residual and analyze the units entering
    % subset in each step of the fwd search (matrix Un).  As is well known,
    % the FS provides an ordering of the data from those most in agreement
    % with a suggested model (which enter the first steps) to those least in
    % agreement with it (which are included in the final steps).
     load('fishery');
     y=fishery.data(:,2);
     X=fishery.data(:,1);
     % Find starting subset
     [out]=LXS(y,X,'nsamp',10000);
    [mdr,Un] = FSRmdr(y,X,out.bs);
%}





%% Input parameters checking

% Set up values for default model
modeldef          = struct;
modeldef.trend    = 1;
modeldef.s        = 12;       % monthly time series
modeldef.seasonal = [];
modeldef.X        = [];       % no explanatory variables
modeldef.posLS   = [];       % no level shift
modeldef.B        = [];        % empty initial parameter values
nocheck           = false;
% StartDate         = '';

%% User options

n=length(y);
initdef=floor(0.5*(n+1));

% Default for vector bsbsteps which indicates for which steps of the fwd
% search units forming subset have to be saved
if n<=5000
    bsbstepdef = 0;
else
    iniseq=100:100:100*floor(n/100);
    iniseq=iniseq(iniseq>initdef);
    bsbstepdef = [initdef iniseq];
end

options=struct('model',modeldef,'init',initdef,'plots',0,'nocheck',0,'msg',1,...
    'constr','','bsbmfullrank',1,'bsbsteps',bsbstepdef);

UserOptions=varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
        error('FSDA:FSRtsmdr:WrongInputOpt','Number of supplied options is invalid. Probably values for some parameters are missing.');
    end
    % Check if user options are valid options
    chkoptions(options,UserOptions)
end


if nargin<2
    error('FSDA:FSRtsmdr:missingInputs','Initial subset is missing');
end
%init1=options.init;
if nargin >2
    
    % Write in structure 'options' the options chosen by the user
    for i=1:2:length(varargin)
        options.(varargin{i})=varargin{i+1};
    end
end

plots=options.plots;
% And check if the optional user parameters are reasonable.

% Default values for the optional parameters are set inside structure
% 'options'
if ~isequal(options.model,modeldef)
    fld=fieldnames(options.model);
    
    if nocheck == false
        % Check if user options inside options.model are valid options
        chkoptions(modeldef,fld)
    end
    for i=1:length(fld)
        modeldef.(fld{i})=options.model.(fld{i});
    end
    
end

model = modeldef;

% Get model parameters
trend    = model.trend;       % get kind of  trend
s        = model.s;           % get periodicity of time series
seasonal = model.seasonal;    % get number of harmonics

if isfield(model,'posLS') && ~isempty(model.posLS)
    lshift   = model.posLS;
    posLS =lshift;
else
    lshift=0;
end

n=length(y);
T = n;

% seq is the vector which will contain linear time trend
seq   = (1:T)';
one   = ones(T,1);

% Construct the matrices which are fixed in each step of the minimization
% procedure
Seq = [one seq seq.^2 seq.^3];

% Define matrix which contains linear quadratic of cubic trend
Xtrend = Seq(:,1:trend+1);

ntrend = size(Xtrend,2);

% seasonal component
if seasonal >0
    sstring=num2str(seasonal);
    if seasonal>100
        varampl=str2double(sstring(1));
        seasonal=str2double(sstring(2:3));
    else
        varampl=0;
    end
    
    if seasonal < 1 || seasonal >floor(s/2)
        error('FSDA:FSRtsmdr:WrongInput',['Seasonal component must be an integer between 1 and ' num2str(floor(s/2))])
    end
    
    Xseaso=zeros(T,seasonal*2);
    for j=1:seasonal
        Xseaso(:,2*j-1:2*j)=[cos(j*2*pi*seq/s) sin(j*2*pi*seq/s)];
    end
    % Remark: when s is even the sine term disapperas for j=s/2 and so the
    % maximum number of trigonometric terms is s-1
    if seasonal==(s/2)
        Xseaso=Xseaso(:,1:end-1);
    end
    nseaso=size(Xseaso,2);
else
    Xseaso=[];
    nseaso=0;
    varampl=0;
end

X=model.X;
isemptyX=isempty(X);
if isemptyX
    % nexpl = number of potential explanatory variables
    nexpl=0;
else
    nexpl=size(X,2);
end

% Define the explanatory variable associated to the level shift component
if lshift>0
    % Xlshift = explanatory variable associated with
    % level shift Xlshift is 0 up to lsh-1 and 1 from
    % lsh to T
    Xlshift= [zeros(posLS-1,1);ones(T-posLS+1,1)];
else
    Xlshift =[];
end


% Construct matrix X (called Xsel) which contains the linear part of the model
if seasonal==0
    if isemptyX
        Xsel=Xtrend;
    else
        Xsel=[Xtrend X];
    end
else
    
    if isemptyX
        Xsel=[Xtrend Xseaso];
    else
        Xsel= [Xtrend Xseaso X];
    end
    % zero for varampl is automatically included because b0 is
    % initialized as a vector of zeroes b0=[b0;zeros(varampl,1)];
end

if lshift>0
    Xsel=[Xsel Xlshift];
end


% pini = number of parameters in the linear model without level shifts nor
% varying amplitude
% ntrend = number of trend parameters,
% nseaso = number of parameters associated with the harmonics,
% nexpl = number of explanatory variables,
% 1 parameter for fixed level shift position
pini=ntrend+nseaso+nexpl+(lshift>0);

% p = total number of parameters in the model
% nini +
% varampl = number of parameters involving time varying trend,
p=pini+varampl;

% indexes of linear part of seasonal component
if seasonal <6
    indlinsc=(trend+2):(trend+1+seasonal*2);
else
    indlinsc=(trend+2):(trend+1+seasonal*2-1);
end

otherind=setdiff(1:p,indlinsc);
% if lshift>0
%     otherind=otherind(1:end-1);
% end

if bsb==0
    Ra=1; nwhile=1;
    sizRandomSubsets=max([p+1 round(n/4)]);
    while and(Ra,nwhile<100)
        bsb=randsample(n,sizRandomSubsets);
        bsbini=bsb;
        Xb=Xsel(bsb,:);
        Ra=(rank(Xb)<size(Xb,2));
        nwhile=nwhile+1;
    end
    if nwhile==100
        warning('FSDA:FSRtsmdr:NoFullRank','Unable to randomly sample full rank matrix');
    end
    yb=y(bsb);
else
    yb=y(bsb);
end

ini0=length(bsb);

% check init
init1=options.init;
if  init1 <p+1
    fprintf(['Attention : init1 should be larger than p. \n',...
        'It is set to p+1.']);
    init1=p+1;
elseif init1<ini0
    fprintf(['Attention : init1 should be >= length of supplied subset. \n',...
        'It is set equal to ' num2str(length(bsb)) ]);
    init1=ini0;
elseif init1>=n
    fprintf(['Attention : init1 should be smaller than n. \n',...
        'It is set to n-1.']);
    init1=n-1;
end

% If model contains a field named B than use the first column of this field
% as initial parameter value, else use OLS estimate based on linear part of
% the model
if isfield(model,'B') && ~isempty(model.B)
    b=model.B(:,1); % get initial estimate of parameter values
else
    
    % initial value of parameter estimates is based on subset 
    b=Xsel(bsb,:)\y(bsb);
    if varampl>0
        if lshift>0
            b=[b(1:end-1); 0.01*zeros(varampl,1); b(end)];
            
        else
            b=[b; 0.01*zeros(varampl,1)];
        end
    end
end
% posvarampl = position of non linear term of time varying seasonal
% component inside b
posvarampl=p-varampl+1:p;
posvarampl=posvarampl-(lshift>0);

bprevious=b;

msg=options.msg;
constr=options.constr;
bsbmfullrank=options.bsbmfullrank;
bsbsteps=options.bsbsteps;


%% Initialise key matrices

% sequence from 1 to n.
seq=(1:n)';

% the set complementary to bsb.
ncl=setdiff(seq,bsb);

% The second column of matrix R will contain the residuals at each step
% of the search
r=[seq zeros(n,1)];

% If n is very large (>500), the step of the search is printed every 500 step
% seq500 is linked to printing
seq500=500*(1:1:ceil(n/500));

% Matrix Bols will contain the beta coefficients in each step of the fwd
% search. The first column of Bols contains the fwd search index
Bols=[(init1:n)' NaN(n-init1+1,p)];     %initial value of beta coefficients is set to NaN

% S2 = (n-init1+1) x 3 matrix which will contain:
% 1st col = fwd search index
% 2nd col = S2= \sum e_i^2 / (m-p)
% 3rd col = R^2
S2=[(init1:n)' NaN(n-init1+1,2)];        %initial value of S2 (R2) is set to NaN

% mdr = (n-init1-1) x 2 matrix which will contain min deletion residual
% among nobsb r_i^*
mdr=[(init1:n-1)'  NaN(n-init1,1)];      %initial value of mdr is set to NaN

% Matrix BB will contain the units forming subset in each step (or in
% selected steps) of the forward search. The first column contains
% information about units forming subset at step init1.
if bsbsteps == 0
    bsbsteps=init1:n;
    BB = NaN(n,n-init1+1);
else
    % The number of columns of matrix BB is equal to the number of steps
    % for which bsbsteps is greater or equal than init1
    bsbsteps=bsbsteps(bsbsteps>=init1);
    BB = NaN(n,length(bsbsteps));
    %   BB = NaN(n, sum(bsbsteps>=init1));
end

% ij = index which is linked with the columns of matrix BB. During the
% search every time a subset is stored inside matrix BB ij increases by one
ij=1;


%  Un is a Matrix whose 2nd column:11th col contains the unit(s) just
%  included.
Un = cat(2 , (init1+1:n)' , NaN(n-init1,10));

% Initialize matrix which stores in each step the integer identifying the
% reason why the algorithm terminated
Exflag=[(ini0:n)',ones(n-ini0+1,1)];

Xb=Xsel(bsb,:);

% MaxIter=[];
MaxIter=1000;

DisplayLevel='';
nlinfitOptions=statset('Display',DisplayLevel,'MaxIter',MaxIter,'TolX',1e-7);

warning('off','stats:nlinfit:Overparameterized');
warning('off','stats:nlinfit:IterationLimitExceeded');
warning('off','stats:nlinfit:IllConditionedJacobian')
warning('off','MATLAB:rankDeficientMatrix')
%% Start of the forward search
if rank(zscore(Xb(:,2:end)))<pini-1
    warning('FSDA:FSRtsmdr:NoFullRank','Supplied initial subset does not produce full rank matrix');
    warning('FSDA:FSRtsmdr:NoFullRank','FS loop will not be performed');
    mdr=NaN;
    % FS loop will not be performed
else
    
    for mm=ini0:n
        oldbsb=bsb;
        
        % if n>5000 show every 500 steps the fwd search index
        if msg==1 && n>5000
            if length(intersect(mm,seq500))==1
                disp(['m=' int2str(mm)]);
            end
        end
        
        % Note that Xsel is the X matrix of the linearized version if the
        % model is non linear (that is it contains time varying amplitude)
        NoRankProblem=( rank(zscore(Xsel(bsb,2:end))) == size(Xsel,2)-1 );
        
        if NoRankProblem  % rank is ok
            
            % find estimate of beta and residuals
            if varampl==0  % In this case the model is linear
                % Function lik constructs fitted values and residual sum of
                % squares
                betaout = Xsel(bsb,:) \ y(bsb);
                % update fitted values
                yhat = Xsel * betaout;
                
                s2=sum((y(bsb)-yhat(bsb)).^2)/(mm-size(Xsel,2));
                invXX=inv(Xsel'*Xsel);
                
            else % model is non linear because there is time varying amplitude in seasonal component
                Xtrendf=Xtrend(bsb,:);
                Xseasof=Xseaso(bsb,:);
                if ~isempty(X)
                    Xf=X(bsb,:);
                end
                Seqf=Seq(bsb,:);
                yf=y(bsb);
                
                if lshift>0
                    Xlshiftf=Xlshift(bsb);
                end
                
                iterALS=0;
                while iterALS < 2
                    %   [b,exitflag,iter]=ALS(y,b,10000,1e-7);
                    [betaout,~,~,covB,s2,~]  = nlinfit(Xtrendf,yf,@likyhat,b,'options',nlinfitOptions);
                    % Note that MSE*inv(J'*J) = covB
                    [~,ID] = lastwarn;
                    
                    if iterALS == 0 && ~isempty(lastwarn) && ~strcmp(ID,'stats:nlinfit:IllConditionedJacobian')
                        lastwarn('')
                        % ID='';
                        % [b,exitflag,iter]=ALS(y,b,10000,1e-7);
                        [b,exitflag,iter]=ALS(y,b,10000,1e-7);
                        iterALS=iterALS+1;
                    else
                        iterALS=2;
                    end
                end
                
                %                 [b,exitflag,iter]=ALS(y,b,10000,1e-7);
                %                 [betaout,~,~,covB,s2,~]  = nlinfit(Xtrendf,yf,@likyhat,b,'options',nlinfitOptions);
                
                
                % Note that MSE*inv(J'*J) = covB
                [~,ID] = lastwarn;
                
                if ~isempty(lastwarn) && strcmp(ID,'stats:nlinfit:ModelConstantWRTParam')
                    betaout=bprevious;
                end
                
                if ~isempty(lastwarn) && ~strcmp(ID,'stats:nlinfit:IllConditionedJacobian')
                    Exflag(mm-ini0+1,2)=0;
                end
                % clear "last warning"
                lastwarn('')
                
                invXX=covB/s2;
                
                % Now compute vector yhat for all the observations
                % using input  vector betaout
                bsb=seq;
                yhat=lik(betaout);
               
                
                % yhatb = fitted values for the units belonging to subset
                yhatb=yhat(oldbsb);
                resBSB=yb-yhatb;
                s2=resBSB'*resBSB/(mm-p);
                
                % Xsel always has n rows and p columns and is referred to
                % all the units (this is the linearized version of matrix
                % X)
                fdiffstep=[];
                Xsel = getjacobianFS(betaout,fdiffstep,@lik,yhat);
            end
  
            % Check whether the estimate of b which has come out is
            % reasonable. An estimate of b is called unreasonable if
            % max(yhat)>2*max(y)  and min(yhat)<0.5*min(y)
            % Make sure that the coefficients of posvarampl are set to 0 if
            % they are greater than a certain threshold
            if max(abs(betaout(posvarampl)))>10
                betaout(posvarampl)=0;
            end
            
            if max(yhat)>2*max(y) && min(yhat)<0.5*min(y)
                b=bprevious;
            else
                b=betaout;
            end
            
            % Store correctly computed b for the case of rank problem
            bprevious=b;
        else   % number of independent columns is smaller than number of parameters
            if bsbmfullrank
                Xb=Xsel(bsb,:);
                Xbx=Xb;
                nclx=ncl;
                bsbx=zeros(n,1);
                bsbx(1:mm)=bsb;
                norank=1;
                while norank ==1
                    
                    norank=1;
                    % Increase the size of the subset by one unit iteratively until you
                    % obtain a full rank matrix
                    for i=1:length(nclx)
                        Xbb=[Xbx;Xsel(nclx(i),:)];
                        if length(nclx)==1
                            norank=0;
                            break
                        end
                        if rank(zscore(Xbb(:,2:end))) == size(Xbb,2)-1
                            norank=0;
                            break
                        else
                            bsbx(1:size(Xbb,1))=[bsbx(1:size(Xbb,1)-1);nclx(i)];
                            Xbx=Xsel(bsbx(1:size(Xbb,1)),:);
                            nclx=setdiff(seq,bsbx(1:size(Xbb,1)));
                            norank=1;
                            break
                        end
                    end
                end
                % check how many observations produce a singular X matrix
                bsbsing=bsbx(1:size(Xbb,1)-1);
                
                if msg==1
                    warning('FSDA:FSRtsmdr','Rank problem in step %d:',mm);
                    disp('Observations')
                    disp(bsbsing')
                    disp('produce a singular matrix')
                end
                mdr=bsbsing;
                Un=NaN;
                BB=NaN;
                Bols=NaN;
                S2=NaN;
                return
                
            else
                disp(['Matrix without full rank at step m=' num2str(mm)])
                disp('Estimate of \beta which is used is based on previous step with full rank')
                b=blast;
                % disp([mm b'])
            end
        end
        
        
        e=y-yhat;  % e = vector of residuals for all units using b estimated using subset
        r(:,2)=e.^2;
        
        if mm>=init1
            % Store units belonging to the subset
            if intersect(mm,bsbsteps)==mm
                BB(oldbsb,ij)=oldbsb;
                ij=ij+1;
            end
            
            if NoRankProblem
                % Store beta coefficients if there is no rank problem
                Bols(mm-init1+1,2:p+1)=b';
                S2(mm-init1+1,2)=s2;
                % Store R2
                S2(mm-init1+1,3)=1-s2/var(yb);
                
                if mm<n
                    
                    % Take minimum deletion residual among noBSB
                    % hi (the leverage for the units not belonging to the
                    % subset) is defined as follows
                    % hi=diag(X(ncl,:)*inv(Xb'*Xb)*(X(ncl,:))');
                    
                    % Take units not belonging to bsb
                    Xncl = Xsel(ncl,:);
                    
                    hi = sum((Xncl*invXX).*Xncl,2);
                    % hi=sum((Xncl/mAm).*Xncl,2);
                    
                    ord = [(r(ncl,2)./(1+hi)) e(ncl)];
                    
                    % Store minimum deletion residual in matrix mdr
                    selmdr=sortrows(ord,1);
                    if S2(mm-init1+1,2)==0
                        warning('FSDA:FSRtsmdr:ZeroS2','Value of S2 at step %d is zero, mdr is NaN',mm-init1+1);
                    else
                        mdr(mm-init1+1,2)=sqrt(selmdr(1,1)/S2(mm-init1+1,2));
                    end
                end  %if mm<n
            end   %~RankProblem
        end     %mm>=init1
        
        if mm<n
            
            % order the r_i
            
            % units inside vector constr are forced to join the search in
            % the final k steps
            if ~isempty(constr) && mm<n-length(constr)
                r(constr,2)=Inf;
            end
            ord=sortrows(r,2);
            
            % bsb= units forming the new  subset
            bsb=ord(1:(mm+1),1);
            
            yb=y(bsb);    % subset of y
            
            if mm>=init1
                unit=setdiff(bsb,oldbsb);
                
                % If the interchange involves more than 10 units, store only the
                % first 10.
                if length(unit)<=10
                    Un(mm-init1+1,2:(length(unit)+1))=unit;
                else
                    if msg==1
                        disp(['Warning: interchange greater than 10 when m=' int2str(mm)]);
                        disp(['Number of units which entered=' int2str(length(unit))]);
                        Un(mm-init1+1,2:end)=unit(1:10);
                    end
                end
            end
            
            if mm < n-1
                if ~isempty(constr) && mm<n-length(constr)-1
                    % disp(mm)
                    ncl=ord(mm+2:n,1);    % ncl= units forming the new noclean
                    ncl=setdiff(ncl,constr);
                else
                    ncl=ord(mm+2:n,1);    % ncl= units forming the new noclean
                end
                
            end
        end   % if mm<n
    end  % for mm=ini0:n loop
    
    % Plot minimum deletion residual with 1%, 50% and 99% envelopes
    if plots==1
        quant=[0.01;0.5;0.99];
        % Compute theoretical envelops for minimum deletion residual based on all
        % the observations for the above quantiles.
        [gmin] = FSRenvmdr(n,p,'prob',quant,'init',init1);
        plot(mdr(:,1),mdr(:,2));
        
        % Superimpose 1%, 99%, 99.9% envelopes based on all the observations
        lwdenv=2;
        % Superimpose 50% envelope
        line(gmin(:,1),gmin(:,3),'LineWidth',lwdenv,'LineStyle','--','Color','g','tag','env');
        % Superimpose 1% and 99% envelope
        line(gmin(:,1),gmin(:,2),'LineWidth',lwdenv,'LineStyle','--','Color',[0.2 0.8 0.4],'tag','env');
        line(gmin(:,1),gmin(:,4),'LineWidth',lwdenv,'LineStyle','--','Color',[0.2 0.8 0.4],'tag','env');
        
        xlabel('Subset size m');
        ylabel('Monitoring of minimum deletion residual');
    end
    
end % rank check


% likyhat computes fitted values using vector of regression coefficients
% beta0. Note that matrices Xtrendf, Xseasof, Seqf, Xf contain n-k rows.
% This function is called in the very last step of the procedure when
% routine nlinfit is invoked. Please, note the difference beween likyhat
% and lik
    function objyhat=likyhat(beta0,Xtrendf)
        
        yhattrend=Xtrendf*beta0(1:trend+1);
        
        npar=trend+1;
        
        if seasonal >0
            if seasonal<s/2
                yhatseaso=Xseasof*beta0(npar+1:npar+seasonal*2);
                npar=npar+seasonal*2;
            else
                yhatseaso=Xseasof*beta0(npar+1:npar+seasonal*2-1);
                npar=npar+seasonal*2-1;
            end
            
            if varampl>0
                Xtre=1+Seqf(:,2:varampl+1)*beta0((npar+1+nexpl):(npar+varampl+nexpl));
                yhatseaso=Xtre.*yhatseaso;
                npar=npar+varampl;
            end
        end
        
        if isemptyX
            yhatX=0;
        else
            % Note the order of coefficients is trend, linear part of
            % seasonal component, expl variables, non linear part of
            % seasonal component, level shift
            yhatX=Xf(:,:)*beta0(npar+1-varampl:npar+nexpl-varampl);
            npar=npar+nexpl;
        end
        
        if lshift >0
            %  \beta_(npar+1)* I(t \geq \beta_(npar+2)) where beta_(npar+1)
            %  is a real number and \beta_(npar+2) is a integer which
            %  denotes the period in which level shift shows up
            
            yhatlshift=beta0(npar+1)*Xlshiftf;
        else
            yhatlshift=0;
        end
        
        % objhat = fitted values from trend (yhattrend), (time varying) seasonal
        % (yhatseaso), explanatory variables (yhatX) and level shift
        % component (yhatlshift)
        objyhat=yhattrend+yhatseaso+yhatX+yhatlshift;
    end

    function yhat=lik(beta0)
        
        yhattrend=Xtrend(bsb,:)*beta0(1:trend+1);
        npar=trend+1;
        
        if seasonal >0
            if seasonal<s/2
                yhatseaso=Xseaso(bsb,:)*beta0(npar+1:npar+seasonal*2);
                npar=npar+seasonal*2;
            else
                yhatseaso=Xseaso(bsb,:)*beta0(npar+1:npar+seasonal*2-1);
                npar=npar+seasonal*2-1;
            end
            
            if varampl>0
                Xtre=1+Seq(bsb,2:varampl+1)*beta0((npar+1+nexpl):(npar+varampl+nexpl));
                yhatseaso=Xtre.*yhatseaso;
                npar=npar+varampl;
            end
        end
        
        if isemptyX
            yhatX=0;
        else
            % Note the order of coefficients is trend, linear part of
            % seasonal component, expl variables, non linear part of
            % seasonal component, level shift
            yhatX=X(bsb,:)*beta0(npar+1-varampl:npar+nexpl-varampl);
            npar=npar+nexpl;
        end
        
        if lshift >0
            %  \beta_(npar+1)* I(t \geq \beta_(npar+2)) where beta_(npar+1)
            %  is a real number and \beta_(npar+2) is a integer which
            %  denotes the period in which level shift shows up
            yhatlshift=beta0(npar+1)*Xlshift(bsb);
        else
            yhatlshift=0;
        end
        
        % Fitted values from trend (yhattrend), (time varying) seasonal
        % (yhatseaso), explanatory variables (yhatX) and level shift
        % component (yhatlshift)
        yhat=yhattrend+yhatseaso+yhatX+yhatlshift;
        
    end

    function J = getjacobianFS(beta,fdiffstep,modelFS,yfit)
        function yplus = call_model_nested(betaNew)
            yplus = modelFS(betaNew);
        end
        J = statjacobianFS(@call_model_nested, beta, fdiffstep, yfit);
    end % function getjacobian

    function J = statjacobianFS(func, theta, DerivStep, y0)
        %STATJACOBIAN Estimate the Jacobian of a function
        
        % J is a matrix with one row per observation and one column per model
        % parameter. J(i,j) is an estimate of the derivative of the i'th
        % observation with respect to the j'th parameter.
        
        % For performance reasons, very little error checking is done on the input
        % arguments. This function makes the following assumptions about inputs:
        %
        % * func is the model function and is a valid function handle that accepts
        %   a single input argument of the same size as theta.
        % * theta is vector or matrix of parameter values. If a matrix, each row
        %   represents a different group or observation (see "Grouping Note" below)
        %   and each column represents a different model parameter.
        % * DerivStep (optional) controls the finite differencing step size. It may
        %   be empty, scalar, or a vector of positive numbers with the number of
        %   elements equal to the number model parameters.
        % * y0 (optional) is the model function evaluated at theta. A value of []
        %   is equivalent to omitting the argument and results in the model being
        %   evaluated one additional time.
        %
        % Example 1: NLINFIT
        %   NLINFIT is used to estimate the parameters b(1) and b(2) for the model
        %   @(b,T) b(1)*sin(b(2)*T), given data at T=1:5. NLINFIT needs the
        %   Jacobian of the model function with respect to b(1) and b(2) at each T.
        %   To do this, it constructs a new function handle that is only a function
        %   of b and that "burns-in" the value of T (e.g. model2 = @(b) model1(b,T)).
        %   It then calls STATJACOBIAN with the new function handle to obtain a
        %   matrix J, where J(i,j) is an estimate of the derivative of the model
        %   with respect to the j'th parameter evaluated at T(i) and b.
        %
        % Example 2: NLMEFIT or NLMEFITSA with group-specific parameters
        %   NLMEFIT requires the Jacobian of the model function with respect to two
        %   parameters evaluated at group-specific values. (Group-specific
        %   parameters can arise, for example, from using the default FEConstDesign
        %   and REConstDesign options.) NLMEFIT calls STATJACOBIAN passing in a
        %   matrix of parameter values theta, with one row per group, where
        %   theta(i,j) represents a parameter value for i'th group and j'th
        %   parameter. STATJACOBIAN returns a matrix J, where J(i,j) is an estimate
        %   of the derivative of the model with respect to the j'th parameter,
        %   evaluated for observation i with parameter values theta(rowIdx(i),:),
        %   which are the parameter values for the observation's group.
        %
        % Example 3: NLMEFIT with observation-specific parameters
        %   NLMEFIT requires the Jacobian of the model function with respect to two
        %   parameters evaluated at observation-specific values. (Observation-
        %   specific parameters can arise, for example, from using the FEObsDesign
        %   or REObsDesign options.) NLMEFIT calls STATJACOBIAN passing in a matrix
        %   of parameter values theta, with one row per observation, where
        %   theta(i,j) represents a parameter value for the i'th observation and
        %   j'th parameter. In this case, rowIdx is 1:N, where N is the number of
        %   observations. STATJACOBIAN returns a matrix J, where J(i,j) is an
        %   estimate of the derivative of the model with respect to the j'th
        %   parameter, evaluated for observation i with parameter values
        %   theta(i,:), which are the parameter values for the observation.
        
        % Use the appropriate class for variables.
        classname = class(theta);
        
        % Handle optional arguments, starting with y0 since it will be needed to
        % determine the appropriate size for a default groups.
        if nargin < 4 || isempty(y0)
            y0 = func(theta);
        end
        
        % When there is only one group, ensure that theta is a row vector so
        % that vectoriation works properly. Also ensure that the underlying
        % function is called with an input with the original size of theta.
        thetaOriginalSize = size(theta);
        theta = reshape(theta, 1, []);
        
        func = @(theta) func(reshape(theta, thetaOriginalSize));
        
        % All observations belong to a single group; scalar expansion allows us
        % to vectorize using a scalar index.
        rowIdx = 1;
        
        [numThetaRows, numParams] = size(theta);
        
        if nargin < 3 || isempty(DerivStep)
            % Best practice for forward/backward differences:
            DerivStep = repmat(sqrt(eps(classname)), 1, numParams);
            % However, NLINFIT's default is eps^(1/3).
        elseif isscalar(DerivStep)
            DerivStep = repmat(DerivStep, 1, numParams);
        end
        
        delta = zeros(numThetaRows, numParams, classname);
        J = zeros(numel(y0), numParams, classname);
        for ii = 1:numParams
            % Calculate delta(:,ii), but remember to set it back to 0 at the end of the loop.
            delta(:,ii) = DerivStep(ii) * theta(:,ii);
            deltaZero = delta(:,ii) == 0;
            if any(deltaZero)
                % Use the norm as the "scale", or 1 if the norm is 0.
                nTheta = sqrt(sum(theta(deltaZero,:).^2, 2));
                delta(deltaZero,ii) = DerivStep(ii) * (nTheta + (nTheta==0));
            end
            thetaNew = theta + delta;
            yplus = func(thetaNew);
            dy = yplus(:) - y0(:);
            J(:,ii) = dy./delta(rowIdx,ii);
            delta(:,ii) = 0;
        end
    end


% ALS computes Alternating Least Squares estimate of beta starting from
% vector beta0. The rows which are used are those specified in global
% variable bsb
    function [newbeta,exitflag,iter]=ALS(y,beta0,maxiterALS,maxtolALS)
        
        
        iter        = 0;
        betadiff    = 9999;
        newbeta=beta0;
        oldbeta=beta0;
        % exitflag = flag which informs about convergence. exitflag =0
        % implies normal convergence, else no convergence has been obtained
        exitflag=0;
        
        while ( (betadiff > maxtolALS) && (iter < maxiterALS) )
            iter = iter + 1;
            
            % b2378 estimate of linear part of seasonal component
            b2378=newbeta(indlinsc);
            % at= yhatseaso = fitted values for linear part of seasonal
            % component
            at=Xseaso(bsb,:)*b2378;
            
            % OLS to estimate coefficients of trend + expl variables + non lin coeff of
            % seasonal + coefficient of fixed level shift
            % trlshift is the matrix of explanatory variables
            if isemptyX
                if lshift>0
                    tr_expl_nls_lshift=[Xtrend(bsb,:) bsxfun(@times,at,Seq(bsb,2:varampl+1)) Xlshift(bsb)];
                else
                    tr_expl_nls_lshift=[Xtrend(bsb,:) bsxfun(@times,at,Seq(bsb,2:varampl+1))];
                end
            else
                if lshift>0
                    tr_expl_nls_lshift=[Xtrend(bsb,:) X(bsb,:) bsxfun(@times,at,Seq(bsb,2:varampl+1)) Xlshift(bsb)];
                else
                    tr_expl_nls_lshift=[Xtrend(bsb,:) X(bsb,:) bsxfun(@times,at,Seq(bsb,2:varampl+1))];
                end
            end
            % b0145 = coefficients of intercept trend + expl var + non
            % linear part of seasonal component + level shift
            b0145=tr_expl_nls_lshift\(y(bsb)-at) ;
            
            % Now find new coefficients of linear part of seasonal
            % component in the regression of y-trend-expl-lsihft versus
            % vector which contains non linear part of seasonal component
            % which multiplies each column of matrix Xseaso (linear part of
            % seasonal component)
            yhatnlseaso=Seq(bsb,1)+ Seq(bsb,2:varampl+1)*b0145((trend+2+nexpl):(trend+2+nexpl+varampl-1));
            if isemptyX
                if lshift>0
                    b2378=bsxfun(@times,yhatnlseaso,Xseaso(bsb,:))...
                        \(y(bsb)-Xtrend(bsb,:)*b0145(1:trend+1)-Xlshift(bsb)*b0145(end));
                else
                    b2378=bsxfun(@times,yhatnlseaso,Xseaso(bsb,:))...
                        \(y(bsb)-Xtrend(bsb,:)*b0145(1:trend+1));
                end
            else
                if lshift>0
                    b2378=bsxfun(@times,yhatnlseaso,Xseaso(bsb,:))...
                        \(y(bsb)-Xtrend(bsb,:)*b0145(1:trend+1)-X(bsb,:)*b0145((trend+2):(trend+1+nexpl)) - Xlshift(bsb)*b0145(end));
                else
                    b2378=bsxfun(@times,yhatnlseaso,Xseaso(bsb,:))...
                        \(y(bsb)-Xtrend(bsb,:)*b0145(1:trend+1)-X(bsb,:)*b0145((trend+2):(trend+1+nexpl)));
                end
            end
            
            
            
            newbeta(indlinsc)=b2378;
            
            newbeta(otherind)=b0145;
            
            % betadiff is linked to the tolerance (specified in scalar
            % reftol)
            betadiff = norm(oldbeta - newbeta,1) / norm(newbeta,1);
            
            oldbeta=newbeta;
            
            % exit from the loop if the new beta has singular values. In
            % such a case, any intermediate estimate is not reliable and we
            % can just keep the initialbeta and initial scale.
            if (any(isnan(newbeta)))
                newbeta = beta0;
                exitflag=1;
                break
            end
        end
    end
end
%FScategory:REG-Regression