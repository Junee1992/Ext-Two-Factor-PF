# Ext-Two-Factor-PF

This repository includes MATLAB codes of three models studied in Jun Han's Ph.D. Thesis.

a) The extended Schwartz-Smith (SS) Two-Factor Model introduced in [[1]](#ref-han1) and [[2]](#ref-han2);

b) The ARIMA Multi-output Least-Squares Support Vector Regression Model (ARIMA-MLS-SVR) model by combining algorithms in [[3]](#ref-zhu) and [[4]](#ref-xu);

c) The Nested Particle Filter (NPF) algorithm by [[5]](#ref-crisan), [[6]](#ref-perez-vieites), using resampling algorithm in [[7]](#ref-kamariotis), under the two-factor model framework;

# How to run the codes

Each algorithm are placed in different folders. The users can run "main_{algorithm}.m" files to run the algorithm. The data are simulated within the same code.

## References
<a id="ref-han1"></a> [1] Han, J. S., Kordzakhia, N., Shevchenko, P. V., & Trück, S. (2022). On correlated measurement errors in the Schwartz–Smith two-factor model. Dependence Modeling, 10(1), 108-122. (https://www.degruyter.com/document/doi/10.1515/demo-2022-0106/html)

<a id="ref-han2"></a> [2] Han, J. S., Kordzakhia, N., Shevchenko, P. V., & Trück, S. (2024). On Autoregressive Measurement Errors in a Two-Factor Model. In 2021-2022 MATRIX Annals (pp. 383-398). Cham: Springer Nature Switzerland. (https://link.springer.com/chapter/10.1007/978-3-031-47417-0_19)

<a id="ref-zhu"></a> [3] Zhu, B., Chevallier, J., Zhu, B., & Chevallier, J. (2017). Carbon price forecasting with a hybrid Arima and least squares support vector machines methodology. Pricing and forecasting carbon markets: Models and empirical analyses, 87-107. (https://link.springer.com/chapter/10.1007/978-3-319-57618-3_6)

<a id="ref-xu"></a> [4] Xu, S., An, X., Qiao, X., Zhu, L., & Li, L. (2013). Multi-output least-squares support vector regression machines. Pattern recognition letters, 34(9), 1078-1084.  (https://www.sciencedirect.com/science/article/pii/S0167865513000196?casa_token=dPIBhztP2y0AAAAA:BkkcToBHa06fTaFhCK4aU6W-K1Qsc5ZHwgyQFYJA3lvc06tWu7J46sUltQak2Aq-q2QTeTHd8w)

<a id="ref-crisan"></a> [5] Crisan, D., & Miguez, J. (2018). Nested particle filters for online parameter estimation in discrete-time state-space Markov models. Bernoulli, 24(4A), 3039-3086. (https://projecteuclid.org/journals/bernoulli/volume-24/issue-4A/Nested-particle-filters-for-online-parameter-estimation-in-discrete-time/10.3150/17-BEJ954.full)

<a id="ref-perez-vieites"></a> [6] Pérez-Vieites, S. (2018) Nested hybrid filters (NHFs). (https://github.com/sarapv/Perez-Vieites2018_NestedHybridFilter.)

<a id="ref-kamariotis"></a> [7] Kamariotis, A., Sardi, L., Papaioannou, I., Chatzi, E., & Straub, D. (2023). On off-line and on-line Bayesian filtering for uncertainty quantification of structural deterioration. Data-Centric Engineering, 4, e17. (https://www.cambridge.org/core/journals/data-centric-engineering/article/on-offline-and-online-bayesian-filtering-for-uncertainty-quantification-of-structural-deterioration/11924D1729F98A6FF55EB63C16AA2AA8)
