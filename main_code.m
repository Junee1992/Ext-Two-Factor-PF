
clear all; close all;

load('eua_sample_v2.mat')
SS_folder = fullfile(pwd, "SS");
LSSVR_folder = fullfile(pwd, "LSSVR");
NPF_folder = fullfile(pwd, "NPF");
rng(1000);
addpath(SS_folder);

LT = "OU"; correlation = 1; % = 1 if inter-correlated measurement errors, = 0 if diagonal.
deltat = 1/260; % Assume 260 days in a year.
[nobsn, ncontracts] = size(y);
n_forecast = 20;
y_pred = [];
n_temp = nobsn - n_forecast;
y_temp = y(1:n_temp,:); y_fore = [];
detrend_price = "yes";
correlation = 1; % 0 for diagonal matrix, 1 for full matrix.
max_lags = 2; % number of lags to be considered for serial correlation of measurement errors
n_lag = 0; % Assume no AR in the first iteration.
par_names = define_parameters(LT, ncontracts, correlation, n_lag)';
model_options = struct();
vars = whos;
exclude_vars = {'i', 'model_options'};
for i = 1:length(vars)
    name = vars(i).name;
    if ~ismember(name, exclude_vars)
        model_options.(name) = eval(name);
    end
end

% model_options = struct('LT', LT, 'correlation', correlation, 'par_names', par_names, 'deltat', deltat, ...
%     'detrend_price', detrend_price, 'max_lags', max_lags, 'n_forecast', n_forecast, 'n_temp', n_temp);

% SS Model
output_SS = ss_example(model_options);

% LSSVR Model
addpath(LSSVR_folder); rmpath(SS_folder);


% NPF Model
addpath(NPF_folder); rmpath(SS_folder); rmpath(LSSVR_folder);
error_list = ["laplace", "hyperbolic"];
M = 1000; N = 1000; max_lags = 0;
new_vars = {'M', 'N', 'err'};
for q = 1:2
    err = error_list(q);% Not supporting autoregressive errors
    for i = 1:length(new_vars)
        name = new_vars{i};
        if ismember(name, new_vars)
            model_options.(name) = eval(name);
        end
    end  
    output_NPF{q} = npf_example(model_options);
end

