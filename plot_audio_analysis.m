function plot_audio_analysis(originalSignal, filteredSignal, fs, cutoffFreq, filterCoeffs)
%PLOT_AUDIO_ANALYSIS Plot time-domain and frequency-domain comparisons.
%   PLOT_AUDIO_ANALYSIS(originalSignal, filteredSignal, fs, cutoffFreq, filterCoeffs)
%   overlays the original and filtered signals in the time domain, plots
%   their FFT magnitude spectra in dB, and marks the cutoff frequency.

    if nargin < 5
        error(['Usage: plot_audio_analysis(originalSignal, filteredSignal, ' ...
               'fs, cutoffFreq, filterCoeffs)']);
    end

    originalSignal = originalSignal(:);
    filteredSignal = filteredSignal(:);

    if length(originalSignal) ~= length(filteredSignal)
        error('Original and filtered signals must have the same length.');
    end

    %% Time-domain comparison
    % Compensate for the FIR group delay so the overlay is easier to read.
    groupDelay = floor((length(filterCoeffs) - 1) / 2);
    filteredAligned = [filteredSignal(groupDelay + 1:end); zeros(groupDelay, 1)];

    numSamples = length(originalSignal);
    timeAxis = (0:numSamples - 1) / fs;
    displayDuration = min(0.02, numSamples / fs);   % Show up to 20 ms
    displaySamples = max(1, round(displayDuration * fs));

    figure('Name', 'Time-Domain Comparison', 'Color', 'w');
    plot(timeAxis(1:displaySamples), originalSignal(1:displaySamples), ...
        'b', 'LineWidth', 1.2);
    hold on;
    plot(timeAxis(1:displaySamples), filteredAligned(1:displaySamples), ...
        'r', 'LineWidth', 1.2);
    grid on;
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Time-Domain Comparison of Original and Filtered Audio');
    legend('Original Signal', 'Filtered Signal (Delay Compensated)', ...
        'Location', 'best');

    %% Frequency-domain comparison using FFT
    nfft = 2^nextpow2(numSamples);
    frequencyAxis = (0:nfft/2) * (fs / nfft);

    originalSpectrum = fft(originalSignal, nfft);
    filteredSpectrum = fft(filteredSignal, nfft);

    originalMagnitude = abs(originalSpectrum(1:nfft/2 + 1));
    filteredMagnitude = abs(filteredSpectrum(1:nfft/2 + 1));

    originalMagnitudeDB = 20 * log10(originalMagnitude + eps);
    filteredMagnitudeDB = 20 * log10(filteredMagnitude + eps);

    figure('Name', 'Frequency Spectrum Comparison', 'Color', 'w');
    plot(frequencyAxis, originalMagnitudeDB, 'b', 'LineWidth', 1.2);
    hold on;
    plot(frequencyAxis, filteredMagnitudeDB, 'r', 'LineWidth', 1.2);
    xline(cutoffFreq, '--k', sprintf('Cutoff = %d Hz', cutoffFreq), ...
        'LineWidth', 1.2, ...
        'LabelVerticalAlignment', 'middle', ...
        'LabelHorizontalAlignment', 'left');
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    title('Frequency Spectrum of Original and Filtered Audio');
    legend('Original Spectrum', 'Filtered Spectrum', 'Cutoff Frequency', ...
        'Location', 'best');
    xlim([0 fs / 2]);
end
