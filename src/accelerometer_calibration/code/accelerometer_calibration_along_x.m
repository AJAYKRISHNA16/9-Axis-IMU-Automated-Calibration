% === Configuration ===
accelPort = 'COM5';         % Port for accelerometer data
accelBaud = 115200;

degreePort = 'COM3';       % Port for degree data
degreeBaud = 9600;

outputFile = 'accel_gravity_log_x1.csv';

logTimeFirstSet = 10;        % 5 minutes in seconds
logTimeOtherSets = 8;     % 4.5 minutes in seconds
pauseDuration = 2;              % 30 seconds between sets

% === Serial Port Setup ===
accel = serialport(accelPort, accelBaud, 'Timeout', 1);
degree = serialport(degreePort, degreeBaud, 'Timeout', 1);
configureTerminator(accel, "LF");
configureTerminator(degree, "LF");
flush(accel);
flush(degree);

% === File Setup ===
fid = fopen(outputFile, 'w');
if fid == -1
    error("Failed to open output file.");
end

disp("Logging accel + gravity vector data in format: ax,ay,az,1,gx,gy,gz");

% === Variables ===
latestDegree = NaN;
setNumber = 1;
continueLogging = true;

while continueLogging
    % === Start Logging Phase ===
    fprintf('--- Starting data logging set #%d ---\n', setNumber);

    if setNumber == 1
        logDuration = logTimeFirstSet;
    else
        logDuration = logTimeOtherSets;
    end

    tic;  % Start timer
    while toc < logDuration
        try
            % === Read Degree ===
            if degree.NumBytesAvailable > 0
                degLine = strtrim(readline(degree));
                degVal = str2double(degLine);
                if ~isnan(degVal)
                    latestDegree = degVal;
                    disp("Degree read: " + degVal);
                end
            end

            % === Read Accelerometer ===
            if accel.NumBytesAvailable > 0 && ~isnan(latestDegree)
                accelLine = strtrim(readline(accel));
                disp("Accel read: " + accelLine);

                if count(accelLine, ',') >= 2 && ...
                   ~contains(accelLine, 'Starting') && ...
                   ~contains(accelLine, 'Slave')

                    accelParts = strsplit(accelLine, ',');
                    if length(accelParts) >= 3
                        ax = str2double(accelParts{1});
                        ay = str2double(accelParts{2});
                        az = str2double(accelParts{3});

                        if all(~isnan([ax, ay, az]))
                            % === Compute expected gravity vector (X-axis rotation) ===
                            theta = deg2rad(latestDegree);
                            gx = 0;
                            gy = sin(theta);
                            gz = cos(theta);

                            % === Compose and log the line ===
                            logLine = sprintf('%.3f,%.3f,%.3f,1,%.4f,%.4f,%.4f', ax, ay, az, gx, gy, gz);
                            fprintf(fid, '%s\n', logLine);
                            disp("[LOG] " + logLine);
                        end
                    end
                end
            end
        catch ME
            break;
        end
    end

    % === Pause Phase ===
    fprintf('--- Pausing for %.0f seconds ---\n', pauseDuration);
    pause(pauseDuration);

    % === Continue to next set ===
    setNumber = setNumber + 1;

    % OPTIONAL: Add stopping condition here
    % For example, if setNumber > N, break
    % if setNumber > 108
    %     continueLogging = false;
    % end
end

% === Cleanup ===
fclose(fid);
clear accel degree;
