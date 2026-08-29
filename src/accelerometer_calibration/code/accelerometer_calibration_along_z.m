% === Configuration ===
accelPort = 'COM5';         % Port for accelerometer data
accelBaud = 115200;

degreePort = 'COM3';       % Port for degree data
degreeBaud = 9600;

outputFile = 'accel_gravity_log_z.csv';

logTimeFirstSet = 10;        % 5 minutes
logTimeOtherSets = 8;     % 4.5 minutes
pauseDuration = 2;              % pause in seconds

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
    % === Determine logging duration for current set ===
    if setNumber == 1
        logDuration = logTimeFirstSet;
    else
        logDuration = logTimeOtherSets;
    end

    fprintf('\n=== STARTING DATA LOGGING SET #%d (%.1f sec) ===\n', setNumber, logDuration);

    tic;  % Start logging timer
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

                % Only parse if valid format
                if count(accelLine, ',') >= 2 && ...
                   ~contains(accelLine, 'Starting') && ...
                   ~contains(accelLine, 'Slave')
                    accelParts = strsplit(accelLine, ',');
                    if length(accelParts) >= 3
                        ax = str2double(accelParts{1});
                        ay = str2double(accelParts{2});
                        az = str2double(accelParts{3});

                        if all(~isnan([ax, ay, az]))
                            % === Compute expected gravity vector (Z-axis rotation) ===
                            theta = deg2rad(latestDegree);

                            gx = -sin(theta);  % X-Y rotation
                            gy = cos(theta);
                            gz = 0;

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

    % === Pause between sets ===
    fprintf('=== PAUSING for %.0f seconds ===\n\n', pauseDuration);
    pause(pauseDuration);
    setNumber = setNumber + 1;

    % === Optional stopping condition ===
    % if setNumber > N
    %     continueLogging = false;
    % end
end

% === Cleanup ===
fclose(fid);
clear accel degree;
