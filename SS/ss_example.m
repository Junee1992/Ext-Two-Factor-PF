%% SS Model - Kalman filter (with AR(p) measurement errors)
% This code runs the Schwartz-Smith Two-factor Model (2000) with two
% factors following correlated bivariate Ornstein-Uhlenbeck processes.
% Assume futures contracts mature annually.

function output = ss_example(model_options)

fields = fieldnames(model_options);
for i = 1:numel(fields)
    fieldName = fields{i};
    eval([fieldName ' = model_options.(fieldName);']);
end

% load('eua_sample_v2.mat')

% Model Options (Simulation)
% LT = "OU"; correlation = 1; % = 1 if inter-correlated measurement errors, = 0 if diagonal.
% deltat = 1/260; % Assume 260 days in a year.
% [nobsn, ncontracts] = size(y);

% Global variables
global save_ett save_ytt save_att save_vtt

% Data Calibration / Model Estimation
% att: estimated states
% ytt: estimated measurements
% ett: measurement errors
% par_optim: optimised parameters
% max_lags = 0; % Maximum lags to be considered initially.
% [par_optim, ~, ~, ~, ~, att, ytt, ett] = par_estimate(y, ttm, model_options, max_lags);

model_options = struct('LT', LT, 'correlation', correlation, 'nobsn', nobsn, ...
    'ncontracts', ncontracts, 'par_names', par_names, 'deltat', deltat, ...
    'detrend_price', detrend_price, 'n_forecast', n_forecast, 'y_temp', y_temp,...
    'max_lags', max_lags);

% Forecasting
output = forecast_KF(y, ttm, model_options);

% Plot
% figure;
% y_temp = output.ytt_temp.time_20; varn = output.varn;
% plot(y(:,1), 'k');
% hold on
% plot(nobsn-n_forecast:nobsn, y_temp(nobsn-n_forecast:nobsn,1), 'r');
% for i = 1:n_forecast
%     lb_y(i,:) = y_temp(nobsn-n_forecast+i,:)' - 1.96 * sqrt(diag(varn(:,:,i)));
%     ub_y(i,:) = y_temp(nobsn-n_forecast+i,:)' + 1.96 * sqrt(diag(varn(:,:,i)));
% end
% plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); lb_y(:,1)], 'r--');
% plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); ub_y(:,1)], 'r--');
