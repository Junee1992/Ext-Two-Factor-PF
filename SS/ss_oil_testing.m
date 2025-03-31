%% SS Model - Kalman filter (with AR(p) measurement errors)
% This code runs the Schwartz-Smith Two-factor Model (2000) with two
% factors following correlated bivariate Ornstein-Uhlenbeck processes.
% Assume futures contracts mature annually.

% clear all; close all;



load('eua_sample_v2.mat')

% Model Options
LT = "OU"; correlation = 1; % = 1 if inter-correlated measurement errors, = 0 if diagonal.
deltat = 1/260; % Assume 260 days in a year.
[nobsn, ncontracts] = size(y);

% Global variables
global save_ett save_ytt save_att save_vtt

% Data Calibration / Model Estimation
% att: estimated states
% ytt: estimated measurements
% ett: measurement errors
% par_optim: optimised parameters
% max_lags = 0; % Maximum lags to be considered initially.
% [par_optim, ~, ~, ~, ~, att, ytt, ett] = par_estimate(y, ttm, model_options, max_lags);

% Forecasting
n_forecast = 20;
y_pred = [];
n_temp = nobsn - n_forecast;
y_temp = y(1:n_temp,:); y_fore = [];
detrend_price = "yes";
LT = "OU"; % GBM or OU.
n_season = 0;
correlation = 1; % 0 for diagonal matrix, 1 for full matrix.
max_lags = 2; % number of lags to be considered for serial correlation of measurement errors
n_lag = 0; % Assume no AR in the first iteration.
par_names = define_parameters(LT, ncontracts, correlation, n_lag)';
model_options = struct('LT', LT, 'correlation', correlation, 'par_names', par_names, 'deltat', deltat, ...
    'detrend_price', detrend_price, 'max_lags', max_lags, 'n_forecast', n_forecast, 'n_temp', n_temp);
output = forecast_KF(y_temp, ttm, model_options);

% Plot
figure;
y_temp = output.ytt_temp.time_20; varn = output.varn;
plot(y(:,1), 'k');
hold on
plot(nobsn-n_forecast:nobsn, y_temp(nobsn-n_forecast:nobsn,1), 'r');
for i = 1:n_forecast
    lb_y(i,:) = y_temp(nobsn-n_forecast+i,:)' - 1.96 * sqrt(diag(varn(:,:,i)));
    ub_y(i,:) = y_temp(nobsn-n_forecast+i,:)' + 1.96 * sqrt(diag(varn(:,:,i)));
end
plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); lb_y(:,1)], 'r--');
plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); ub_y(:,1)], 'r--');
