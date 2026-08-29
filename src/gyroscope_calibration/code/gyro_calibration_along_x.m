% === Configuration ===
imuPort = 'COM5';
imuBaud = 115200;

rpmPort = 'COM3';
rpmBaud = 9600;

outputFile = 'combined_data_x.csv';

logDurationFirst = 1.2 * 60;       % 5 minutes
logDurationOther = 1 * 60;     % 4.5 minutes
pauseDuration = 12;              % 30 seconds

% === Serial Port Setup ===
imu = serialport(imuPort, imuBaud, 'Timeout', 1);
rpm = serialport(rpmPort, rpmBaud, 'Timeout', 1);
configureTerminator(imu, "LF");
configureTerminator(rpm, "LF");
flush(imu);
flush(rpm);

% === File Setup ===
fid = fopen(outputFile, 'w');
if fid == -1
    error("Failed to open output file.");
end

disp("Logging IMU and RPM data (format: gx,gy,gz,1,rpm,0,0)");

% === Main Loop ===
isFirstCycle = true;

while true
    if isFirstCycle
        logDuration = logDurationFirst;
        isFirstCycle = false;
    else
        logDuration = logDurationOther;
    end

    startTime = tic;
    while toc(startTime) < logDuration
        try
            if imu.NumBytesAvailable > 0 && rpm.NumBytesAvailable > 0
                imuLine = strtrim(readline(imu));
                rpmLine = strtrim(readline(rpm));

                imuParts = strsplit(imuLine, ',');
                if length(imuParts) == 3
                    rpmVal = str2double(rpmLine);
                    if ~isnan(rpmVal)
                        % Format: gx,gy,gz,1,rpm,0,0
                        logLine = sprintf('%s,1,%.2f,0,0', strjoin(imuParts, ','), rpmVal * 6);
                        fprintf(fid, '%s\n', logLine);
                        disp("[LOG] " + logLine);
                    end
                end
            end
        catch ME
            break;
        end
    end

    disp("Pausing for 30 seconds...");
    pause(pauseDuration);
end

% === Cleanup (if interrupted) ===
fclose(fid);
clear imu rpm;
