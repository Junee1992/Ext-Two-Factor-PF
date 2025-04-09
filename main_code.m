
clear all; close all;

load('eua_sample.mat')
SS_folder = fullfile(pwd, "SS");
LSSVR_folder = fullfile(pwd, "LSSVR");
NPF_folder = fullfile(pwd, "NPF");
rng(1000);
addpath(SS_folder);

% Model Setting
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

% SS Model
rmpath(NPF_folder); addpath(SS_folder); rmpath(LSSVR_folder);
output_SS = ss_example(model_options);

% LSSVR Model
addpath(LSSVR_folder); rmpath(SS_folder);
output_lssvr = lssvr_example(model_options);

% NPF Model
addpath(NPF_folder); rmpath(SS_folder); rmpath(LSSVR_folder);
error_list = ["laplace", "hyperbolic"];
M = 1000; N = 1000; max_lags = 0; % Not supporting autoregressive errors
new_vars = {'M', 'N', 'err', 'max_lags'};
% Both Laplace and GH
for q = 1:2
    err = error_list(q);
    for i = 1:length(new_vars)
        name = new_vars{i};
        if ismember(name, new_vars)
            model_options.(name) = eval(name);
        end
    end  
    output_npf{q} = npf_example(model_options);
end

save('output_eua_final.mat', 'output_SS', 'output_lssvr', 'output_npf')

% Plot of results

figure;
p=1;
subplot(4,2,1);
plot(nobsn-n_forecast-99:nobsn, y(nobsn-n_forecast-99:end,p), 'k');
hold on

% SS
y_temp = output_SS.ytt_temp.time_20; varn = output_SS.varn;
plot(nobsn-n_forecast:nobsn, y_temp(nobsn-n_forecast:nobsn,p), 'r');
for i = 1:n_forecast
    lb_y(i,:) = y_temp(nobsn-n_forecast+i,:)' - 1.96 * sqrt(diag(varn(:,:,i)));
    ub_y(i,:) = y_temp(nobsn-n_forecast+i,:)' + 1.96 * sqrt(diag(varn(:,:,i)));
end
plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); lb_y(:,p)], 'r--');
plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); ub_y(:,p)], 'r--');

% LSSVR
plot(nobsn-n_forecast:nobsn, output_lssvr.y_data_temp(nobsn-n_forecast:nobsn,p), 'b')
plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); output_lssvr.y_data_temp(nobsn-n_forecast+1:nobsn,1) + 1.96 * sqrt(output_lssvr.res_lssvr_var(:,p))], 'b--')
plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast,1); output_lssvr.y_data_temp(nobsn-n_forecast+1:nobsn,1) - 1.96 * sqrt(output_lssvr.res_lssvr_var(:,p))], 'b--')

% NPF
for q = 1:2
    y_temp = output_npf{q}.y_temp; varn = output_npf{q}.varn;
    for i = 1:n_forecast
        lb_y(i,:) = y_temp(nobsn-n_forecast+i,:)' - 1.96 * sqrt(diag(varn(:,:,i)));
        ub_y(i,:) = y_temp(nobsn-n_forecast+i,:)' + 1.96 * sqrt(diag(varn(:,:,i)));
    end
    if q == 1
        plot(nobsn-n_forecast:nobsn, y_temp(nobsn-n_forecast:nobsn, p), 'g');
        plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast, p); lb_y(:,p)], 'g--');
        plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast, p); ub_y(:,p)], 'g--');
    elseif q == 2
        plot(nobsn-n_forecast:nobsn, y_temp(nobsn-n_forecast:nobsn, p), 'm');
        plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast, p); lb_y(:,p)], 'm--');
        plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast, p); ub_y(:,p)], 'm--');
    end
end

% RMSE
y_ss = output_SS.ytt_temp.time_20;
y_lssvr = output_lssvr.y_data_temp;
y_lap = output_npf{1}.y_temp;
y_gh = output_npf{2}.y_temp;

rmse(1,:) = sqrt(mean(y(nobsn-n_forecast+1:nobsn, :) - y_ss(nobsn-n_forecast+1:nobsn,:)).^2);
rmse(2,:) = sqrt(mean(y(nobsn-n_forecast+1:nobsn, :) - y_lssvr(nobsn-n_forecast+1:nobsn,:)).^2);
rmse(3,:) = sqrt(mean(y(nobsn-n_forecast+1:nobsn,:) - y_lap(nobsn-n_forecast+1:nobsn,:)).^2);
rmse(4,:) = sqrt(mean(y(nobsn-n_forecast+1:nobsn,:) - y_gh(nobsn-n_forecast+1:nobsn,:)).^2);

% CRPS
