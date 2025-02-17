clc;
clear;

%% Solar Panel Parameters
A = 1.6; % Panel area in m^2
eta = 0.18; % Panel efficiency (18%)
PR = 0.9; % Performance Ratio
T_ref = 25; % Reference temperature (°C)
beta = 0.004; % Temperature coefficient (4% per 100°C)
V_oc = 40; % Open-circuit voltage (V)
I_sc = 8.5; % Short-circuit current (A)
G_ref = 1000; % Reference irradiance (W/m^2)

%% Elevation & Air Mass Correction
elevation = 1000; % Elevation in meters (example: 1000m above sea level)
AM_correction = exp(-elevation / 8000); % Approximate correction factor for AM effect

%% Dynamic Irradiance & Temperature Profile (Simulating a Full Day)
time = linspace(0, 12, 100); % 0 to 12 hours (morning to evening)
G = (100 + 900 * sin(pi * time / 12)) .* AM_correction; % Adjusted irradiance with elevation
T_op = (20 + 10 * sin(pi * time / 12)) - (elevation * 0.0065); % Temperature correction with elevation

%% Solar Angle & Effective Irradiance (Angle of Incidence Correction)
panel_tilt = 30; % Panel tilt angle in degrees
solar_altitude = 90 - abs(time - 6) * 15; % Approximate solar altitude angle
incidence_angle = abs(panel_tilt - solar_altitude); % Angle of incidence
G_effective = G .* cosd(incidence_angle); % Effective irradiance on panel
G_effective(G_effective < 0) = 0; % Ensure no negative irradiance

%% MPPT Initialization (Perturb & Observe)
V = V_oc * 0.76; % Initial operating voltage (near MPP)
V_step = 0.5; % Voltage step size
P_old = 0; % Initial power

P_MPPT = zeros(size(time)); % Store MPPT power

%% MPPT Algorithm (P&O) Dynamic Simulation
for k = 1:length(time)
    G_k = G_effective(k);
    T_k = T_op(k);
    
    % Adjust Voc and Isc based on Irradiance & Temperature
    V_oc_k = V_oc * (1 - beta * (T_k - T_ref));
    I_sc_k = I_sc * (G_k / G_ref);
    
    % Measure new voltage and current
    V_new = V + V_step;
    I_new = I_sc_k * (1 - (V_new / V_oc_k)); % Approximated current model
    P_new = V_new * I_new;
    
    % Compare power
    if P_new > P_old
        V = V_new; % Move towards higher power
    else
        V_step = -V_step; % Reverse direction if power decreases
    end
    
    P_old = P_new;
    P_MPPT(k) = P_old;
    
    % Display results
    fprintf('Time %.2f hrs: Voltage = %.2f V, Power = %.2f W\n', time(k), V, P_new);
end

%% Plot Results
figure;
subplot(3,1,1);
plot(time, G, 'r', 'LineWidth', 2);
hold on;
plot(time, T_op, 'b', 'LineWidth', 2);
legend('Irradiance (W/m^2)', 'Temperature (°C)');
xlabel('Time (hours)'); ylabel('G & T'); title('Solar Irradiance & Temperature with Elevation');

title('Solar Irradiance & Temperature with Elevation');
subplot(3,1,2);
plot(time, G_effective, 'm', 'LineWidth', 2);
xlabel('Time (hours)'); ylabel('G Effective (W/m^2)'); title('Effective Irradiance with Angle of Incidence');

title('Effective Irradiance with Angle of Incidence');
subplot(3,1,3);
plot(time, P_MPPT, 'k', 'LineWidth', 2);
xlabel('Time (hours)'); ylabel('Power (W)'); title('MPPT Power Output');
grid on;
