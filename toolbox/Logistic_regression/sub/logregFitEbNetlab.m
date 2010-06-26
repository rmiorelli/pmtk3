function [model, logev] = logregFitEbNetlab(X, y)
% Empirical Bayes logistic regression using Netlab's evidence procedure
% X is n*d, y is d*1, can be binary or multiclass
% Do not add a column of 1s

x = X;
nclasses = nunique(y);
targets = dummyEncoding(y(:), nclasses);
model.isbinary = nclasses < 3;
if model.isbinary
  link = 'logistic';
else
  link = 'softmax';
end

% Uses evidence procedure to find optimal regularizer
% logev is log p(y|X, alpha-hat, beta-hat)
[n,d] = size(x);
% Set up network parameters.
nin = d;		% Number of inputs.
nout = 1;		% Number of outputs.
alpha_init = 0.01;	% initial regularizer

net = glm(nin, nout, link, alpha_init);

% Set up vector of options for the optimiser.
nouter = 5;			% Number of outer loops.
ninner = 2;			% Number of innter loops.
options = zeros(1,18);		% Default options vector.
options(1) = 0;			% This provides display of error values.
options(2) = 1.0e-5;		% Absolute precision for weights.
options(3) = 1.0e-5;		% Precision for objective function.
options(14) = 500;		% Number of training cycles in inner loop.

for k = 1:nouter
   net = glmtrain(net, options, x, targets);
   [net, gamma, logev] = evidence(net, x, targets, ninner);
end


model.netlab = net;
model.effnparams = gamma;
      
% Need to compute inverse hessian so we can get error bars
w = netpak(model.netlab);
hess = nethess(w, model.netlab, X, y);
invhess = inv(hess);
model.wMu = w;
model.wCov = invhess;

end