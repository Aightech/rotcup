
types = ["relax","flex"];
conf=["1", "2", "3"];

energy_arr=[]

for i = 1:length(conf)
    for j = 1:length(types)
        filename = "pos" + conf(i)+"_"+types(j)+"EMG.mat";
        %filename = "pos2_flex"+"EMG.mat";
        file = load(filename);
        s = size(file.data);
        s = s(1);
        data = [reshape(file.timestamp(1,:), s,1)  file.data ];
        data = sortrows(data);

        data = data(1:end,:);
        time = double(data(:,1))-data(1,1);
        emg = data(:,2:end);

        fs_target = length(time)/(time(end)-time(1)); % Desired constant sampling rate (Hz)
        time_interp = linspace(time(1), time(end), round((time(end) - time(1)) * fs_target));
        emg_interp = interp1(time, emg, time_interp, 'linear');


        % Apply a bandpass filter with passband [10, 200]
        low_freq = 10;  % Lower frequency limit (Hz)
        high_freq = 150; % Upper frequency limit (Hz)
        filter_order = 6; % Filter order

        % Design the bandpass filter
        nyquist_freq = 0.5 * fs_target;
        Wn = [low_freq, high_freq] / nyquist_freq;
        [b_bp, a_bp] = butter(filter_order, Wn, 'bandpass');

        emg_notch_filtered=emg_interp;
        for ii = 0:1
            notch_freq = 50+100*ii; % Notch frequency (Hz)
            notch_bw = 1; % Bandwidth of the notch (Hz)
            Wn = [notch_freq-notch_bw/2, notch_freq+notch_bw/2] / nyquist_freq;
            [b_notch, a_notch] = iirnotch(notch_freq/(fs_target/2), notch_bw/(fs_target/2));
            % Apply a stopband filter at 50 Hz
            emg_notch_filtered = filter(b_notch, a_notch, emg_notch_filtered);
        end

        % Filter the EMG signals
        emg_bp_filtered = filter(b_bp, a_bp, emg_notch_filtered);


        % Apply double rectification
        emg_rectified = abs(emg_bp_filtered);

        % Calculate the envelope
        % nyquist_freq = 0.5 * fs_target;
        % fenv=5;
        % Wn = fenv/ nyquist_freq;
        % [b_env, a_env] = butter(filter_order, Wn, 'low');
        % envelope = filtfilt(b_env, a_env, emg_notch_filtered);
        envelope_window = round(fs_target / 1); % Length of the moving average window
        envelope = movmean(emg_rectified, envelope_window, 1);



        % % Plot the filtered EMG signal
        % figure;
        % subplot(5, 1, 2);
        % plot(time_interp, emg_bp_filtered(:, channel));
        % title('bp Filtered EMG');
        % xlabel('Time (s)');
        % ylabel('Amplitude');
        %
        % subplot(5, 1, 1);
        % plot(time_interp, emg_notch_filtered(:, channel));
        % title('Notch Filtered EMG');
        % xlabel('Time (s)');
        % ylabel('Amplitude');
        %
        % subplot(5, 1, 3);
        % plot(time_interp, emg_rectified(:, channel));
        % title('Double Rectified EMG');
        % xlabel('Time (s)');
        % ylabel('Amplitude');
        %
        % subplot(5, 1, 4);
        % plot(time_interp, envelope(:, channel));
        % title('Envelope of EMG');
        % xlabel('Time (s)');
        % ylabel('Amplitude');
        %
        co="b";
        if j==2
            co="r";
        end
        figure(1)

        hold on
        plot(time, sum(envelope(:,4:12), 2),co);
        title('Raw EMG');
        xlabel('Time (s)');
        ylabel('Amplitude');
        axis([2 10 0 100]);

        emg_filtered =envelope;


%         % Define the grid layout for the 36 channels
%         n_rows = 6;
%         n_cols = 3;
%         %
%         % % Create a figure with a custom size
%         % figure('Position', [100, 100, 1200, 800]);
%         %
%         % % Plot the 36 filtered EMG channels
%         figure(2)
%         for i = 1:18
%             subplot(n_rows, n_cols, i);
%             selected_emg = emg_interp(:, i);
%         
% %         % Define spectrogram parameters
% %         window = round(fs_target / 10); % Window length (you can adjust this)
% %         noverlap = round(window * 0.8); % Overlap between windows (you can adjust this)
% %         nfft = max(512, 2^nextpow2(window)); % Number of FFT points (you can adjust this)
% %         
% %         % Calculate and plot the spectrogram
% %         spectrogram(selected_emg, window, noverlap, nfft, fs_target, 'yaxis');
% %         title(sprintf('Spectrogram for Channel %d', channel));
% %         xlabel('Time (s)');
% %         ylabel('Frequency (Hz)');
% %         colormap(jet); % Set colormap for better visualization (optional)
% %         
%             % Plot the filtered EMG signal for the current channel
%             plot(time_interp(1000:end), emg_filtered(1000:end, i), 'LineWidth', 1);
%         
%             % Set the title and labels for the current channel
%             title(sprintf('Channel %d', i));
%             xlabel('Time (s)');
%             ylabel('Amplitude');
%         
%             % Set the limits for the x-axis
%             xlim([time_interp(1) time_interp(end)]);
%         
%             % Set custom tick label format for better readability
%             ax = gca;
%             ax.XAxis.TickLabelFormat = '%.1f';
%             ax.YAxis.TickLabelFormat = '%.1f';
%         
%             % Improve readability by making the grid visible
%             grid on;
%         end
        %
        % % Adjust the layout to create some space between subplots
        % sgtitle('Filtered EMG Signals');

        % Initialize an array to store the energy for each channel
        energy_emg = zeros(1, 18);

        % Calculate the energy for each channel
        for channel = 1:18
            energy_emg(channel) = sum(emg_bp_filtered(:, channel).^2);
        end

        energy = sum(energy_emg);

        
        %plot(j, energy/10^8, "-o")
        hold on
        if(length(energy_arr)==0)
                energy_arr=[j energy];
            else
                energy_arr=[energy_arr; [j energy]];
            end

    end
end
hold off
% 
% axis([0.5 2.5 2 10])
