filename = "empty"+"EMG.mat";
file = load(filename);
s = size(file.data);
s = s(1)
data = [reshape(file.timestamp(1,:), s,1)  file.data ];
data = sortrows(data);

data = data(1:end,:);
time = double(data(:,1))-data(1,1);
emg = data(:,2:end);

fs_target = 1500; % Desired constant sampling rate (Hz)
time_interp = linspace(time(1), time(end), round((time(end) - time(1)) * fs_target));
emg_interp = interp1(time, emg, time_interp, 'linear');


% Apply a bandpass filter with passband [10, 200]
low_freq = 10;  % Lower frequency limit (Hz)
high_freq = 200; % Upper frequency limit (Hz)
filter_order = 6; % Filter order

% Design the bandpass filter
nyquist_freq = 0.5 * fs_target;
Wn = [low_freq, high_freq] / nyquist_freq;
[b_bp, a_bp] = butter(filter_order, Wn, 'bandpass');


notch_freq = 50; % Notch frequency (Hz)
notch_bw = 1; % Bandwidth of the notch (Hz)
Wn = [notch_freq-notch_bw/2, notch_freq+notch_bw/2] / nyquist_freq;
[b_notch, a_notch] = butter(filter_order, Wn, 'stop');%iirnotch(notch_freq/(fs_target/2), notch_bw/(fs_target/2));



% Apply a stopband filter at 50 Hz
emg_notch_filtered = emg_interp;%filtfilt(b_notch, a_notch, emg_interp);

% Filter the EMG signals
emg_bp_filtered = filtfilt(b_bp, a_bp, emg_notch_filtered);


% Apply double rectification
emg_rectified = abs(emg_bp_filtered);

% Calculate the envelope
% nyquist_freq = 0.5 * fs_target;
% fenv=5;
% Wn = fenv/ nyquist_freq;
% [b_env, a_env] = butter(filter_order, Wn, 'low');
% envelope = filtfilt(b_env, a_env, emg_notch_filtered);
envelope_window = round(fs_target / 3); % Length of the moving average window
envelope = movmean(emg_rectified, envelope_window, 1);



%Choose the channel to plot
channel = 3; % Replace with the desired channel number (1-36)

% Plot the filtered EMG signal
figure;
subplot(5, 1, 2);
plot(time_interp, emg_bp_filtered(:, channel));
title('bp Filtered EMG');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(5, 1, 1);
plot(time_interp, emg_notch_filtered(:, channel));
title('Notch Filtered EMG');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(5, 1, 3);
plot(time_interp, emg_rectified(:, channel));
title('Double Rectified EMG');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(5, 1, 4);
plot(time_interp, envelope(:, channel));
title('Envelope of EMG');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(5, 1, 5);
plot(time, emg(:, channel));
title('Raw EMG');
xlabel('Time (s)');
ylabel('Amplitude');

emg_filtered =envelope;


% Define the grid layout for the 36 channels
n_rows = 6;
n_cols = 6;

% Create a figure with a custom size
figure('Position', [100, 100, 1200, 800]);

% Plot the 36 filtered EMG channels
for i = 1:36
    subplot(n_rows, n_cols, i);
    
    % Plot the filtered EMG signal for the current channel
    plot(time_interp, emg_filtered(:, i), 'LineWidth', 1);
    
    % Set the title and labels for the current channel
    title(sprintf('Channel %d', i));
    xlabel('Time (s)');
    ylabel('Amplitude');
    
    % Set the limits for the x-axis
    xlim([time_interp(1) time_interp(end)]);
    
    % Set custom tick label format for better readability
    ax = gca;
    ax.XAxis.TickLabelFormat = '%.1f';
    ax.YAxis.TickLabelFormat = '%.1f';
    
    % Improve readability by making the grid visible
    grid on;
end

% Adjust the layout to create some space between subplots
sgtitle('Filtered EMG Signals');

% Initialize an array to store the energy for each channel
energy_emg = zeros(1, 36);

% Calculate the energy for each channel
for channel = 1:36
    energy_emg(channel) = sum(emg_filtered(:, channel).^2);
end

energy = sum(energy_emg)

% Display the energy values for each channel
for channel = 1:36
    fprintf('Energy of channel %d: %f\n', channel, energy_emg(channel));
end
