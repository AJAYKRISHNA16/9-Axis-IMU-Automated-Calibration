close all;
% Load data from CSV file (adjust the filename if needed)
data = readmatrix('gyro_data_1.csv');

% Extract W from columns 1 to 4
W = data(:, 1:3);

% Extract Y from columns 5 to 7
Y = data(:, 4:7);

A = W';

B = inv(A*W);

C = B*A;

D= C*Y;
disp(D');
%  H = D(:,1:3);
%  %I = D(:,);
%  %disp(H);
%  I = [0.0166 0.0165 0.0156];
% 
% 
%  imu_CAL = H*W'+I';
%  disp(imu_CAL);
% %c=M*a+b;

 W = [0.653 0.055 9.418];
% 
 M = [0.1014 0.0016 0.0041; 0.0059 0.1011 0.0036; 0.0092 -0.0026 0.1019];
 b = [-0.0035 -0.0035 -0.0124];
% % h = W-b;
% % omega_calibrated = M \ h;
% % disp(omega_calibrated);
  imu_CAL = W* M+b;
  disp(imu_CAL);
% disp(imu_CAL.*imu_CAL);

