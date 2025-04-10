%% Kalman filter

function log_L = kf_v3_arp(par_init, par_names, y, deltat, ttm, LT, correlation, serial)

% Defining the dimensions of the dataset.
[nobsn, ncontracts] = size(y);
par = set_parameters(LT, ncontracts, par_names, par_init, correlation, serial, "normal");
if serial == "yes"
    n_lag = size(par.phi,2)/ncontracts;
elseif serial == "no"
    n_lag = 0;
end

% Transition matrices in state and measurement equation
% x_t = C + G x_{t-1} + w_t,  w_t ~ N(0, W)
% y_t = d_t + B_t * x_t + v_t, v_t ~ N(0, V)
if LT == "GBM"

    C = [0; par.mu * deltat];
    G = [exp(-par.kappa * deltat), 0; 0, 1];
    W = [(1-exp(-2*par.kappa*deltat))/(2*par.kappa)*par.sigmachi^2, (1-exp(-par.kappa*deltat))/par.kappa * (par.sigmachi * par.sigmaxi * par.rho_chixi);...
        (1-exp(-par.kappa*deltat))/par.kappa * (par.sigmachi * par.sigmaxi * par.rho_chixi), par.sigmaxi^2 * deltat]; %the covariance matrix of w

    d1 = (1 - exp(-2 * par.kappa * ttm)) * par.sigmachi^2 / (2 * par.kappa);
    d2 = par.sigmaxi^2 * ttm;
    d3 = (1 - exp(-(par.kappa) * ttm)) * 2 * par.sigmachi * par.sigmaxi * par.rho_chixi / (par.kappa);
    d_temp = (par.mu - par.lambdaxi) * ttm - (par.lambdachi / par.kappa) * (1 - exp(-par.kappa * ttm)) + (1/2) * (d1 + d2 + d3);
    d_temp = d_temp';

    for i = 1:nobsn
        B1(i,:) = exp(-par.kappa * ttm(i,:));
        B2(i,:) = repelem(1, ncontracts);
        B_temp(:,:,i) = [B1(i,:); B2(i,:)]';
    end

elseif LT == "OU"

    C = [0 ; (par.mu / par.gamma) * (1 - exp(-par.gamma * deltat))];
    G = [exp(-par.kappa * deltat), 0; 0, exp(-par.gamma * deltat)];
    W = [(1 - exp(-2 * par.kappa * deltat)) / (2 * par.kappa) * par.sigmachi^2, (1 - exp(-(par.kappa + par.gamma) * deltat)) / (par.kappa + par.gamma) * (par.sigmachi * par.sigmaxi * par.rho_chixi);
        (1 - exp(-(par.kappa + par.gamma) * deltat)) / (par.kappa + par.gamma) * (par.sigmachi * par.sigmaxi * par.rho_chixi), (1 - exp(-2 * par.gamma * deltat)) / (2 * par.gamma) * par.sigmaxi^2];

    d1 = (1 - exp(-2 * par.kappa * ttm)) * par.sigmachi^2 / (2 * par.kappa);
    d2 = (1 - exp(-2 * par.gamma * ttm)) * par.sigmaxi^2 / (2 * par.gamma);
    d3 = (1 - exp(-(par.kappa + par.gamma) * ttm)) * 2 * par.sigmachi * par.sigmaxi * par.rho_chixi / (par.kappa + par.gamma);
    d_temp = (par.mu - par.lambdaxi) / par.gamma * (1 - exp(-par.gamma * ttm)) - (par.lambdachi / par.kappa) * (1 - exp(-par.kappa * ttm)) + (1/2) * (d1 + d2 + d3);
    d_temp = d_temp';

    for i = 1:nobsn
        B1(i,:) = exp(-par.kappa * ttm(i,:));
        B2(i,:) = exp(-par.gamma * ttm(i,:));
        B_temp(:,:,i) = [B1(i,:); B2(i,:)]';
    end

else
    error('Please specify the process of the long-term factor LT.')
end

vsig2 = par.s.^2;
if correlation == 0
    V_temp = diag(vsig2);

elseif correlation == 1
    correl = par.rho;

    % Manually creating the correlation matrix of measurement errors
    CorMat = diag(repelem(1, ncontracts));
    for i = 1:ncontracts
        for j = 1:ncontracts
            if i == j
                CorMat(i,j) = 1;
            else
                CorMat(i,j) = correl(i) * correl(j);
            end
        end
    end
    D = diag(vsig2);
    V_temp = D^(1/2) * CorMat * D^(1/2);

else
    error('correlation must be 0 or 1.')
end

d = []; B = []; Ct = [];

for t = 1+n_lag:nobsn
    phiy = zeros(ncontracts, 1); phiBG = zeros(ncontracts,1);
    phid = zeros(ncontracts, 1); 
    phiBGinv = zeros(ncontracts, size(G,2)); phiBGWG = zeros(ncontracts,ncontracts);
    GWG = zeros(size(G,1), size(G,2)); GBphi = zeros(size(G,1), ncontracts);
    for j = 1:n_lag
        Ginv = zeros(size(G,1), size(G,2));
        phiy = phiy + diag(par.phi((j-1)*ncontracts+1:j*ncontracts))*y(t-j,:)';
        phid = phid + diag(par.phi((j-1)*ncontracts+1:j*ncontracts))*d_temp(:,t-j);
        for k = 1:j
            Ginv = Ginv + inv(G)^k;
        end
        phiBG = phiBG + diag(par.phi((j-1)*ncontracts+1:j*ncontracts))*B_temp(:,:,t-j)*Ginv*C;
        phiBGinv = phiBGinv + diag(par.phi((j-1)*ncontracts+1:j*ncontracts))*B_temp(:,:,t-j)*inv(G)^j;
        GBphi = GBphi + (inv(G)')^(j-1)*B_temp(:,:,t-j)'*diag(par.phi((j-1)*ncontracts+1:j*ncontracts));
    end
    save_phiBGinv(:,:,t) = phiBGinv;
    d(:,t) = phiy + d_temp(:,t) - phid + phiBG;
    B(:,:,t) = B_temp(:,:,t) - phiBGinv;
    Ct(:,:,t) = W*inv(G)'*GBphi;
end

% Kalman Filter
% Initial distribution of state variables
% E(x_{1|0}) = a0
% Cov(x_{1|0}) = P0
if LT == "GBM"
    a0 = [0; y(1,1)];
    P0 = [0.01, 0.01; 0.01, 0.01];

elseif LT == "OU"
    a0 = [0; y(1,1)];
    % a0 = [0; mean(y(1,:), 2)]; 
    P0 = [0.01, 0; 0, 0.01];

end

global save_ytt save_att save_ett save_vtt save_et save_att_1 save_Ptt_1 save_Ptt
save_ytt = zeros(nobsn, ncontracts); % Estimation of y given x_1:t, y_{t-1}
save_att = zeros(nobsn, length(a0)); % Updated estimation of x at time t
save_ett = zeros(nobsn, ncontracts); % Prediction error
save_vtt = zeros(nobsn, ncontracts); % Measurement errors
save_att_1 = zeros(nobsn+1, length(a0)); % Updated estimation of x at time t
save_et = zeros(nobsn, ncontracts);
att_1 = []; Ptt_1 = []; att = []; Ptt = [];
att_1(:,1) = a0; Ptt_1(:,:,1) = P0;
att(:,1) = a0; Ptt(:,:,1) = P0;
% 
for i = 2:n_lag
    att_1(:,i) = C + G*att(:,i-1); Ptt_1(:,:,i) = G * Ptt_1(:,:,i-1) * G' + W;
    att(:,i) = att_1(:,i); Ptt(:,:,i) = Ptt_1(:,:,i);
end
% att_1(:,n_lag+1) = C + G * att(:,n_lag); Ptt_1(:,:,n_lag+1) = G * Ptt(:,:,n_lag)*G' + W; 
% att_1(:,1) = a0;
% Ptt_1(:,:,1) = P0;
% K = Ptt_1(:,:,1)*B_temp(:,:,1)'*(inv(B_temp(:,:,1)*Ptt_1(:,:,1)*B_temp(:,:,1)'+V_temp));
% att(:,1) = a0 + K*(y(1,:)'-d_temp(:,1)-B_temp(:,:,1)*a0);
% save_Ptt(:,:,1) = (eye(2)-K*B_temp(:,:,i))*Ptt_1(:,:,1);
% save_ytt(1,:) = (d_temp(:,1) + B_temp(:,:,1)*att(:,1))';

% for i = 2:n_lag
%     att_1(:,i) = C + G * att(:,i-1);
%     Ptt_1(:,:,i)  = G * save_Ptt(:,:,i-1) * G' + W;
%     K = Ptt_1(:,:,i)*B_temp(:,:,i)'*(inv(B_temp(:,:,i)*Ptt_1(:,:,i)*B_temp(:,:,i)'+V_temp));
%     save_Ptt(:,:,i) = (eye(2)-K*B_temp(:,:,i))*Ptt_1(:,:,i);
%     att(:,i) = att_1(:,i-1) + K*(y(i,:)'-d_temp(:,i)-B_temp(:,:,i)*att_1(:,i-1));
%     % att_1(:,i+1) = a0; Ptt_1(:,:,i+1) = P0;
%     save_ytt(i,:) = d_temp(:,i) + B_temp(:,:,i)*att(:,i) + diag(par.phi(1:7))*(y(1,:)-save_ytt(1,:))';
% end
att_1(:,n_lag+1) = C + G * att(:,n_lag);
Ptt_1(:,:,n_lag+1) = G * Ptt(:,:,n_lag)*G'+W;
% save_att(1:n_lag,:) = att';
% for i = 1:n_lag
%     ModX = fitlm(B_temp(:,:,i), y(i,:)' - d_temp(:,i), 'intercept', false);
%     att(:,i) = ModX.Coefficients{:,1};
%     K = Ptt_1(:,:,i)*B_temp(:,:,i)'*(inv(B_temp(:,:,i)*Ptt_1(:,:,i)*B_temp(:,:,i)'+V_temp));
%     Ptt(:,:,i) = (eye(2)-K*B_temp(:,:,i))*Ptt_1(:,:,i);
%     att_1(:,i+1) = C + G * att(:,i);
%     Ptt_1(:,:,i+1)  = G * Ptt(:,:,i) * G' + W;
% end

eLe = 0;
dLtt_1 = 0;
vtt = zeros(nobsn, ncontracts)';
wt = [];

for i = 1+n_lag:nobsn
  
    if n_lag <= 1
        vt = zeros(ncontracts, nobsn);

    elseif n_lag > 1
        Gw = zeros(length(C),1);
        phiBGw = zeros(ncontracts, 1);
        for r = 2:n_lag
            for k = 2:r
                wt = att(:,i-1) - C - G * att(:,i-2);
                % wt = ks_v2(i-1, k-1, C, G, att, att_1, Ptt, Ptt_1);
                Gw = Gw + inv(G)^(r-k+1) * wt(:,k-1);
            end
            phiBGw = phiBGw + diag(par.phi((r-1)*ncontracts+1:r*ncontracts)) * B_temp(:,:,i-r) * Gw;
        end
        
        vt(:,i) = phiBGw;

    end

    %Prediction error and covariance matrix
    % e_t = y_t - E[y_t | I_{t-1}]

    ytt_1 = d(:,i) + B(:,:,i) * att_1(:,i) + vt(:,i); % E[y_t | I_{t-1}]
    yt = y(i,:)'; % y_t
    et = yt - ytt_1;

    phiBGinv = zeros(ncontracts, size(G,2));
    for j = 1:n_lag
        phiBGinv = phiBGinv + diag(par.phi((j-1)*ncontracts+1:j*ncontracts))*B_temp(:,:,i-j)*inv(G)^j;
    end
    V = phiBGinv * W * phiBGinv' + V_temp;
    Ltt_1 = B(:,:,i) * Ptt_1(:,:,i) * B(:,:,i)' + V + B(:,:,i)*W*phiBGinv' + phiBGinv * W' * B(:,:,i)' + 1e-5 * eye(ncontracts);
    %      if sum(sum(diag(eig((Ltt_1 + Ltt_1') / 2)))) > 0
    %          disp('matrix is not postive semi-definite');
    %      end

    dLtt_1 = dLtt_1 + log(det(Ltt_1)); % ln (det(L_t|{t-1}))
    eLe = eLe + et' * inv(Ltt_1) * et;
    
    % eLe = eLe + et' * inv(Ltt_1 + 1e-5 * eye(size(Ltt_1))) * et; % e_t' * L_t|{t-1} * e_t
    % 
    % Update equation
    % Kalman gain: K_t = P_t|{t-1} B_t' (L_t|{t-1})^(-1)
    % Expectation: a_t = a_{t|t-1} + K_t e_t
    % Covariance:
    % P_t = (I - K_t B_t) * P_{t|t-1} * (I - K_t B_t)'+ K_t * V * K_t'
    % Kt = (Ptt_1(:,:,i) * B(:,:,i)' + Ct(:,:,i)) * inv(Ltt_1 + 1e-5 * eye(size(Ltt_1)) + B(:,:,i) * Ct(:,:,i) + Ct(:,:,i)'*B(:,:,i)');
    Kt = (Ptt_1(:,:,i) * B(:,:,i)' + Ct(:,:,i)) * inv(Ltt_1 + B(:,:,i) * Ct(:,:,i) + Ct(:,:,i)'*B(:,:,i)');
    att(:,i) = att_1(:,i) + Kt * et;
    Rt = eye(size(Ptt_1(:,:,i),1)) - Kt * B(:,:,i);
    Ptt(:,:,i) = Rt * Ptt_1(:,:,i) * Rt' - Rt * Ct(:,:,i) * Kt' - Kt * Ct(:,:,i)' * Rt' + Kt * V * Kt';

    % Forecast distributions of state variables
    % a_{t+1|t} = C + G a_t
    % P_{t+1|t} = G * P_t * G' + W
    att_1(:,i+1) = C + G * att(:,i);
    Ptt_1(:,:,i+1) = G * Ptt(:,:,i) * G' + W;

    vtt_temp = zeros(ncontracts, 1);
    for p = 1:n_lag
        vtt_temp = vtt_temp + diag(par.phi((p-1)*ncontracts+1:p*ncontracts)) * vtt(:,i-p);
    end
    
    % ytt = d_temp(:,i) + B_temp(:,:,i)*att(:,i) + vtt_temp;
    % ytt = d_temp(:,i) + B_temp(:,:,i)*att(:,i) + vtt(:,i-1);
    
        phiBGw = zeros(ncontracts, 1);
        for r = 1:n_lag
            Gw = zeros(length(C),1);
            for k = 1:r
                wt = att(:,i-k+1) - C - G * att(:,i-k);
                % wt = ks_v2(i-1, k-1, C, G, att, att_1, Ptt, Ptt_1);
                Gw = Gw + inv(G)^(r-k+1) * wt;
            end
            phiBGw = phiBGw + diag(par.phi((r-1)*ncontracts+1:r*ncontracts)) * B_temp(:,:,i-r) * Gw;
        end
    
    ytt = d(:,i) + B(:,:,i) * att(:,i) + phiBGw;
    ett = yt - ytt; % Measurement error.
    % vtt(:,i) = vtt_temp + ett;
    vtt(:,i) = yt - d_temp(:,i) - B_temp(:,:,i)*att(:,i);

    save_ytt(i,:) = ytt';
    save_att(i,:) = att(:,i)';
    save_ett(i,:) = ett';
    save_et(i,:) = et';
end

save_Ptt = Ptt; save_Ptt_1 = Ptt_1;
save_att_1 = att_1';
save_ytt(1:n_lag,:) = y(1:n_lag,:);
save_att(1:n_lag, :) = att(:,1:n_lag)';
save_vtt = vtt';
% save_vtt_star = vtt_star';
logL = -(1/2) * nobsn * ncontracts * log(2*pi) - (1 / 2) * dLtt_1 - (1 / 2) * eLe;
log_L = -logL;

if isnan(log_L)
    log_L = 0;
end
%------------------- End of Likelihood Function ---------------------%