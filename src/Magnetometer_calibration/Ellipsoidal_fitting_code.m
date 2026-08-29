%% MAGNETOMETER CALIBRATION USING ELLIPSOID FITTING
%
%
% Performs:
%   1. Loading magnetometer data
%   2. Unit conversion
%   3. Ellipsoid fitting
%   4. Hard-iron bias estimation
%   5. Soft-iron correction matrix estimation
%   6. Calibration
%   7. Saving calibrated data
%   8. 3-D and 2-D visualization
%
clear;
clc;
close all;

% Input file
filename = 'mag_out.txt';

% Input unit:
% 'microtesla' or 'gauss'
unit = 'microtesla';

% Expected magnetic field strength
% IMPORTANT:
% Use the expected local magnetic-field magnitude in microTesla.
%
% Example:
%   India/Earth magnetic field is typically around 25-55 uT.
F = 40;

% Set true if you want plots
makePlots = true;

% Output file
outputFile = 'out.txt';

%% ==================================================

fprintf('=============================================\n');
fprintf('     MAGNETOMETER CALIBRATION - MATLAB\n');
fprintf('=============================================\n\n');

%% LOAD DATA

fprintf('Loading data from: %s\n', filename);
fprintf('Input unit: %s\n', unit);

data = loadMagnetometerData(filename, unit);

fprintf('Loaded %d data points.\n\n', size(data,1));

fprintf('First 5 raw values (microTesla):\n');
disp(data(1:min(5,size(data,1)),:));

%% CHECK DATA

if size(data,2) ~= 3
    error('Magnetometer data must contain exactly 3 columns: X, Y, Z.');
end

if size(data,1) < 10
    error('Not enough data points for ellipsoid fitting.');
end

%% PERFORM ELLIPSOID FIT

fprintf('Calibrating with %d data points...\n', size(data,1));
fprintf('Magnetic field strength: %.6f microTesla\n\n', F);

[M, n, d] = ellipsoidFit(data);

%% CALCULATE CALIBRATION PARAMETERS

M_inv = inv(M);

% Hard iron bias
b = -M_inv * n;

% Soft iron correction matrix
scaleFactor = F / sqrt(n' * M_inv * n - d);

A_1 = real(scaleFactor * sqrtm(M));

%% DISPLAY CALIBRATION PARAMETERS

fprintf('=============================================\n');
fprintf('       CALIBRATION COMPLETED\n');
fprintf('=============================================\n\n');

fprintf('Hard iron bias (microTesla):\n');
fprintf('  X = %.6f\n', b(1));
fprintf('  Y = %.6f\n', b(2));
fprintf('  Z = %.6f\n\n', b(3));

fprintf('Soft iron transformation matrix:\n');
disp(A_1);

%% APPLY CALIBRATION

% Same operation as Python:
%
% data_corrected = (data - self.b.T) @ self.A_1.T

calibratedData = (data - b') * A_1';

%% DISPLAY CALIBRATED DATA

fprintf('\nFirst 5 calibrated values (microTesla):\n');
disp(calibratedData(1:min(5,size(calibratedData,1)),:));

%% DISPLAY CALIBRATION CODE

fprintf('\n=============================================\n');
fprintf('       CALIBRATION PARAMETERS\n');
fprintf('=============================================\n');

fprintf('\nHard iron bias:\n');
fprintf('double hard_iron_bias_x = %.9f;\n', b(1));
fprintf('double hard_iron_bias_y = %.9f;\n', b(2));
fprintf('double hard_iron_bias_z = %.9f;\n', b(3));

fprintf('\nSoft iron matrix:\n');

fprintf('double A11 = %.9f;\n', A_1(1,1));
fprintf('double A12 = %.9f;\n', A_1(1,2));
fprintf('double A13 = %.9f;\n', A_1(1,3));

fprintf('double A21 = %.9f;\n', A_1(2,1));
fprintf('double A22 = %.9f;\n', A_1(2,2));
fprintf('double A23 = %.9f;\n', A_1(2,3));

fprintf('double A31 = %.9f;\n', A_1(3,1));
fprintf('double A32 = %.9f;\n', A_1(3,2));
fprintf('double A33 = %.9f;\n', A_1(3,3));

%% SAVE CALIBRATED DATA

writematrix(calibratedData, outputFile);

fprintf('\nCalibrated data saved to:\n%s\n', outputFile);

%% SAVE CALIBRATION PARAMETERS

calibration.M = M;
calibration.n = n;
calibration.d = d;
calibration.hard_iron_bias = b;
calibration.soft_iron_matrix = A_1;
calibration.magnetic_field_strength = F;
calibration.unit = 'microtesla';

save('magnetometer_calibration.mat', 'calibration');

fprintf('Calibration parameters saved to:\n');
fprintf('magnetometer_calibration.mat\n');

%% PLOTS

if makePlots

    %% RAW DATA - 3D

    figure('Name','Raw Magnetometer Data');

    plot3(data(:,1), data(:,2), data(:,3), '.', ...
        'MarkerSize', 5);

    grid on;
    axis equal;

    xlabel('X (\muT)');
    ylabel('Y (\muT)');
    zlabel('Z (\muT)');

    title('Raw Magnetometer Trajectory - 3D');

    %% CALIBRATED DATA - 3D

    figure('Name','Calibrated Magnetometer Data');

    plot3(calibratedData(:,1), ...
          calibratedData(:,2), ...
          calibratedData(:,3), '.', ...
          'MarkerSize', 5);

    grid on;
    axis equal;

    xlabel('X (\muT)');
    ylabel('Y (\muT)');
    zlabel('Z (\muT)');

    title('Calibrated Magnetometer Trajectory - 3D');

    %% COMMON LIMITS

    allData = [data(:); calibratedData(:)];

    minVal = min(allData);
    maxVal = max(allData);

    %% RAW PROJECTIONS

    figure('Name','Raw Magnetometer Projections');

    % XY
    subplot(2,2,1);

    scatter(data(:,1), data(:,2), 5, 'filled');

    xlabel('X (\muT)');
    ylabel('Y (\muT)');

    title('Raw XY Projection');

    axis equal;
    xlim([minVal maxVal]);
    ylim([minVal maxVal]);
    grid on;

    % XZ
    subplot(2,2,2);

    scatter(data(:,1), data(:,3), 5, 'filled');

    xlabel('X (\muT)');
    ylabel('Z (\muT)');

    title('Raw XZ Projection');

    axis equal;
    xlim([minVal maxVal]);
    ylim([minVal maxVal]);
    grid on;

    % YZ
    subplot(2,2,3);

    scatter(data(:,2), data(:,3), 5, 'filled');

    xlabel('Y (\muT)');
    ylabel('Z (\muT)');

    title('Raw YZ Projection');

    axis equal;
    xlim([minVal maxVal]);
    ylim([minVal maxVal]);
    grid on;

    %% CALIBRATED PROJECTIONS

    figure('Name','Calibrated Magnetometer Projections');

    % XY
    subplot(2,2,1);

    scatter(calibratedData(:,1), calibratedData(:,2), 5, 'filled');

    xlabel('X (\muT)');
    ylabel('Y (\muT)');

    title('Calibrated XY Projection');

    axis equal;
    grid on;

    % XZ
    subplot(2,2,2);

    scatter(calibratedData(:,1), calibratedData(:,3), 5, 'filled');

    xlabel('X (\muT)');
    ylabel('Z (\muT)');

    title('Calibrated XZ Projection');

    axis equal;
    grid on;

    % YZ
    subplot(2,2,3);

    scatter(calibratedData(:,2), calibratedData(:,3), 5, 'filled');

    xlabel('Y (\muT)');
    ylabel('Z (\muT)');

    title('Calibrated YZ Projection');

    axis equal;
    grid on;

end

fprintf('\n=============================================\n');
fprintf('              FINISHED\n');
fprintf('=============================================\n');


%% ============================================================
%                    LOCAL FUNCTIONS
% =============================================================

function data = loadMagnetometerData(filename, unit)

    % Get file extension
    [~,~,ext] = fileparts(filename);

    ext = lower(ext);

    %% CSV FILE

    if strcmp(ext,'.csv')

        T = readtable(filename);

        numberOfColumns = width(T);

        % Try to identify the specific Python column names
        variableNames = T.Properties.VariableNames;

        idxX = find(strcmpi(variableNames,'mag_x_gauss'),1);
        idxY = find(strcmpi(variableNames,'mag_y_gauss'),1);
        idxZ = find(strcmpi(variableNames,'mag_z_gauss'),1);

        if ~isempty(idxX) && ~isempty(idxY) && ~isempty(idxZ)

            data = T{:, [idxX idxY idxZ]};

            % These columns are explicitly Gauss
            data = data * 100;

        elseif numberOfColumns == 3

            % Use all three columns
            data = T{:,1:3};

        elseif numberOfColumns == 4

            % Skip first column (timestamp)
            data = T{:,2:4};

        else

            error(['CSV must contain 3 or 4 columns. ', ...
                   'Found %d columns.'], numberOfColumns);

        end

    %% TXT FILE

    elseif strcmp(ext,'.txt')

        data = readmatrix(filename);

        if size(data,2) ~= 3

            error(['TXT file must contain exactly 3 columns. ', ...
                   'Found %d columns.'], size(data,2));

        end

    else

        error('Unsupported file format: %s', ext);

    end

    %% UNIT CONVERSION

    if strcmpi(unit,'gauss')

        % 1 Gauss = 100 microTesla
        data = data * 100;

    elseif strcmpi(unit,'microtesla')

        % Already microTesla
        data = data;

    else

        error('Unsupported unit: %s', unit);

    end

end


%% ============================================================

function [M,n,d] = ellipsoidFit(s)


    % MATLAB input:
    %
    % s = N x 3
    %
    % Convert to:
    %
    % 3 x N

    s = s';

    %% Construct design matrix D

    D = [s(1,:).^2;
        s(2,:).^2;
        s(3,:).^2;
        2.*s(2,:).*s(3,:);
        2.*s(1,:).*s(3,:);
        2.*s(1,:).*s(2,:);
        2.*s(1,:);
        2.*s(2,:);
        2.*s(3,:);
        ones(1,size(s,2))];

    %% Scatter matrix

    S = D * D';

    %% Partition S

    S11 = S(1:6,1:6);

    S12 = S(1:6,7:10);

    S21 = S(7:10,1:6);

    S22 = S(7:10,7:10);

    %% Constraint matrix C

    C = [-1  1  1  0  0  0;
         1 -1  1  0  0  0;
         1  1 -1  0  0  0;
         0  0  0 -4  0  0;
         0  0  0  0 -4  0;
         0  0  0  0  0 -4];

    %% Reduced eigenvalue problem

    E = inv(C) * (S11 - S12 * inv(S22) * S21);

    %% Eigenvalue decomposition

    [V,D_eig] = eig(E);

    eigenvalues = diag(D_eig);

    % Select eigenvector corresponding to largest eigenvalue

    [~,index] = max(real(eigenvalues));

    v1 = real(V(:,index));

    %% Sign convention

    if v1(1) < 0
        v1 = -v1;
    end

    %% Calculate v2

    v2 = -inv(S22) * S21 * v1;

    %% Construct quadratic matrix M

    % Same parameter ordering as Python code

    M = [ v1(1), v1(6), v1(5);
        v1(6), v1(2), v1(4);
        v1(5), v1(4), v1(3)];

    %% Linear vector n

    n = [v2(1); v2(2); v2(3)];

    %% Constant term

    d = v2(4);

end