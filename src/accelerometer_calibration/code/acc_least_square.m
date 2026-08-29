% === Load your collected data ===
% Format: ax, ay, az, 1, gx, gy, gz
data = readmatrix('accel_data.csv');

% Extract components
raw  = data(:, 1:3);   % Ax, Ay, Az
true = data(:, 4:7);   % Expected gravity vector: gx, gy, gz
N = size(raw, 1);

% === Build least squares system: Y = W * X ===

% W is 3N × 12 matrix, X is 12×1 parameter vector, Y is 3N×1 vector
W = zeros(3*N, 12);
Y = reshape(true', 3*N, 1);  % Stack expected gx, gy, gz

for i = 1:N
    A = raw(i, :);  % [Ax Ay Az]
    
    % Fill 3 rows for gx, gy, gz equations
    row = 3*(i-1) + 1;

    % First row: gx equation
    W(row,   1:3)   = A;      % M11, M12, M13
    W(row,   10)    = -1;     % bx

    % Second row: gy equation
    W(row+1, 4:6)   = A;      % M21, M22, M23
    W(row+1, 11)    = -1;     % by

    % Third row: gz equation
    W(row+2, 7:9)   = A;      % M31, M32, M33
    W(row+2, 12)    = -1;     % bz
end

% === Solve for X using least squares ===
X = (W' * W) \ (W' * Y);   % 12×1 solution

% === Extract calibration parameters ===
M = reshape(X(1:9), [3, 3]);    % 3x3 misalignment + scale matrix
bias = X(10:12);                % bias vector

% === Display Results ===
disp("Misalignment + Scale Matrix (M):");
disp(M);

disp("Bias Vector:");
disp(bias);
