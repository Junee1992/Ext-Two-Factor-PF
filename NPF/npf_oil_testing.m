%% NPF (Nested Particle Filter) Model
% This code runs the NPF (Nested Particle Filter) algorithm for estimation
% of states and parameters. Assume futures contracts mature annually.

close all; clear all;

for q = 2:2
    clearvars -except q
    rng(1000);
    load('eua_sample_v2.mat')

    detrend_price = "yes";
    LT = "OU"; correlation = 1; % = 1 if inter-correlated measurement errors, = 0 if diagonal.
    deltat = 1/260; % Assume 260 days in a year.
    [nobsn, ncontracts] = size(y);
    error_list = ["laplace", "hyperbolic"];

    err = error_list(q); n_lags = 0;
    par_names = define_parameters(LT, ncontracts, correlation, n_lags);
    % if err == "laplace"
    %     par_names = [par_names "sG"];
    % elseif err == "hyperbolic"
    %     nu_name = [];
    %     for i = 1:ncontracts
    %         nu_name = [nu_name sprintf("nu_%d", i)];
    %     end
    %     par_names = [par_names "lambda" "psi" "chi" nu_name];
    % end

    % Forecast
    n_forecast = 20; M = 1000; N = 1000;
    max_lags = 0;
    model_options = struct('LT', LT, 'correlation', correlation, 'nobsn', nobsn, ...
        'ncontracts', ncontracts, 'par_names', par_names, 'deltat', deltat, ...
        'detrend_price', detrend_price, 'err', err, 'n_forecast', n_forecast, ...
        'M', M, 'N', N, 'max_lags', max_lags);
    output = forecast_NPF(y, ttm, model_options);

    % Plot of forecast (1st available contract)
    figure;
    p = 1;
    y_temp = output.y_temp; varn = output.varn;
    plot(y(:,p), 'k');
    hold on
    plot(nobsn-n_forecast:nobsn, y_temp(nobsn-n_forecast:nobsn, p), 'g');
    for i = 1:n_forecast
        lb_y(i,:) = y_temp(nobsn-n_forecast+i,:)' - 1.96 * sqrt(diag(varn(:,:,i)));
        ub_y(i,:) = y_temp(nobsn-n_forecast+i,:)' + 1.96 * sqrt(diag(varn(:,:,i)));
    end
    plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast, p); lb_y(:,p)], 'g--');
    plot(nobsn-n_forecast:nobsn, [y_temp(nobsn-n_forecast, p); ub_y(:,p)], 'g--');
    % save('output_gh.mat', 'output')
    name = sprintf('output_%s.mat', err);
    save(name);
end