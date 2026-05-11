% Real-Time High-Pass FIR Audio Filter with Visualization
% This script loads or generates an audio signal, applies a high-pass FIR
% filter using frame-based processing, plays the original and filtered
% signals, and compares them in both time and frequency domains.

clearvars -except enablePlayback enablePlots enableFVTool;
clc;
close all;

%% Project configuration
% MATLAB's fir1 high-pass design requires an even filter order, so an
% order of 64 produces 65 coefficients, which is the closest valid design
% to the "64 taps" requirement.
fs = 48000;                 % Sampling frequency in Hz
cutoffFreq = 3000;          % High-pass cutoff frequency in Hz
filterOrder = 64;           % FIR filter order
frameSize = 256;            % Samples per frame for real-time simulation
playbackGap = 0.5;          % Pause between original and filtered playback
audioFile = 'input.wav';    % Input audio file

%% Optional runtime flags
% These flags are useful when running the script in batch mode for testing.
if ~exist('enablePlayback', 'var')
    enablePlayback = true;
end
if ~exist('enablePlots', 'var')
    enablePlots = true;
end
if ~exist('enableFVTool', 'var')
    enableFVTool = true;
end

%% Load input audio
% The script uses input.wav when it is available. If the file is missing,
% a synthetic demo signal is generated so the project still runs.
[inputSignal, sourceDescription] = loadOrGenerateInput(audioFile, fs);
inputSignal = normalizeSignal(inputSignal);

fprintf('%s\n', sourceDescription);
fprintf('Signal length: %.2f seconds\n', numel(inputSignal) / fs);
fprintf('Sampling frequency: %d Hz\n', fs);

%% Design high-pass FIR filter
filterCoeffs = designHighpassFIR(fs, cutoffFreq, filterOrder);

%% Simulate real-time frame-based filtering
% The filter state is preserved between frames so each chunk continues from
% where the previous one stopped, just like a streaming DSP system.
filteredSignal = filterSignalInFrames(inputSignal, filterCoeffs, frameSize);

% Scale the filtered signal only if its peak exceeds the valid audio range.
filteredSignal = limitSignalPeak(filteredSignal);

%% Play the original and filtered audio
if enablePlayback
    playSignalsSequentially(inputSignal, filteredSignal, fs, playbackGap);
else
    fprintf('\nAudio playback skipped because enablePlayback is false.\n');
end

%% Plot time-domain and frequency-domain comparisons
if enablePlots
    plotTimeComparison(inputSignal, filteredSignal, fs, filterCoeffs);
    plotFrequencyComparison(inputSignal, filteredSignal, fs, cutoffFreq);
else
    fprintf('Plots skipped because enablePlots is false.\n');
end

%% Display the filter response
if enableFVTool
    fvtool(filterCoeffs, 1, 'Fs', fs);
else
    fprintf('FVTool display skipped because enableFVTool is false.\n');
end

%% Print a short summary
fprintf('\nFilter summary:\n');
fprintf('Type           : High-pass FIR\n');
fprintf('Sampling rate  : %d Hz\n', fs);
fprintf('Cutoff         : %d Hz\n', cutoffFreq);
fprintf('Order          : %d\n', filterOrder);
fprintf('Coefficients   : %d\n', numel(filterCoeffs));
fprintf('Frame size     : %d samples\n', frameSize);
fprintf('Approx. delay  : %d samples\n', floor(filterOrder / 2));

%% Local functions
function [signal, description] = loadOrGenerateInput(audioFile, fsRequired)
%LOADORGENERATEINPUT Load input.wav or generate a demo signal if missing.

    if isfile(audioFile)
        [audioData, fs] = audioread(audioFile);

        if fs ~= fsRequired
            error('The input file sampling rate is %d Hz, but %d Hz is required.', fs, fsRequired);
        end

        % Convert stereo input to mono so the filter operates on one channel.
        if size(audioData, 2) > 1
            signal = mean(audioData, 2);
        else
            signal = audioData;
        end

        description = sprintf('Loaded audio file: %s', audioFile);
    else
        signal = generateDemoSignal(fsRequired, 5);
        description = 'Generated demo audio signal because input.wav was not found';
    end

    signal = signal(:);
end

function signal = generateDemoSignal(fs, durationSec)
%GENERATEDEMOSIGNAL Create a test signal with low and high frequency content.

    timeVector = (0:1/fs:durationSec - 1/fs).';

    lowFrequency1 = 0.55 * sin(2 * pi * 500 * timeVector);
    lowFrequency2 = 0.35 * sin(2 * pi * 1500 * timeVector);
    highFrequency1 = 0.30 * sin(2 * pi * 6000 * timeVector);
    highFrequency2 = 0.20 * sin(2 * pi * 10000 * timeVector);

    signal = lowFrequency1 + lowFrequency2 + highFrequency1 + highFrequency2;
end

function normalizedSignal = normalizeSignal(signal)
%NORMALIZESIGNAL Scale a signal so its peak magnitude is 1.

    normalizedSignal = signal(:) ./ max(abs(signal) + eps);
end

function limitedSignal = limitSignalPeak(signal)
%LIMITSIGNALPEAK Scale only when the peak exceeds the audio range.

    peakValue = max(abs(signal));
    if peakValue > 1
        limitedSignal = 0.98 * signal / peakValue;
    else
        limitedSignal = signal;
    end
end

function filterCoeffs = designHighpassFIR(fs, cutoffFreq, filterOrder)
%DESIGNHIGHPASSFIR Design a Hamming-window high-pass FIR filter.

    normalizedCutoff = cutoffFreq / (fs / 2);
    windowVector = hamming(filterOrder + 1);
    filterCoeffs = fir1(filterOrder, normalizedCutoff, 'high', windowVector);
end

function filteredSignal = filterSignalInFrames(inputSignal, filterCoeffs, frameSize)
%FILTERSIGNALINFRAMES Process the input signal in fixed-size frames.

    numSamples = numel(inputSignal);
    filteredSignal = zeros(size(inputSignal));

    % zi stores the internal filter memory between consecutive frames.
    zi = zeros(numel(filterCoeffs) - 1, 1);

    for startIndex = 1:frameSize:numSamples
        endIndex = min(startIndex + frameSize - 1, numSamples);
        currentFrame = inputSignal(startIndex:endIndex);

        [filteredFrame, zi] = filter(filterCoeffs, 1, currentFrame, zi);
        filteredSignal(startIndex:endIndex) = filteredFrame;
    end
end

function playSignalsSequentially(originalSignal, filteredSignal, fs, playbackGap)
%PLAYSIGNALSSEQUENTIALLY Play original audio first, then filtered audio.

    originalPlayback = 0.98 * originalSignal / max(abs(originalSignal) + eps);
    filteredPlayback = 0.98 * filteredSignal / max(abs(filteredSignal) + eps);

    fprintf('\nPlaying original audio...\n');
    sound(originalPlayback, fs);
    pause(numel(originalPlayback) / fs + playbackGap);

    fprintf('Playing filtered audio...\n');
    sound(filteredPlayback, fs);
end

function plotTimeComparison(originalSignal, filteredSignal, fs, filterCoeffs)
%PLOTTIMECOMPARISON Plot the original and filtered signals on one axis.

    groupDelay = floor((numel(filterCoeffs) - 1) / 2);
    alignedFilteredSignal = [filteredSignal(groupDelay + 1:end); zeros(groupDelay, 1)];

    numSamples = numel(originalSignal);
    timeAxis = (0:numSamples - 1) / fs;
    displayDuration = min(0.02, numSamples / fs);
    displaySamples = max(1, round(displayDuration * fs));

    figure('Name', 'Time-Domain Comparison', 'Color', 'w');
    plot(timeAxis(1:displaySamples), originalSignal(1:displaySamples), ...
        'b', 'LineWidth', 1.2);
    hold on;
    plot(timeAxis(1:displaySamples), alignedFilteredSignal(1:displaySamples), ...
        'r', 'LineWidth', 1.2);
    grid on;
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Time-Domain Comparison of Original and Filtered Audio');
    legend('Original Signal', 'Filtered Signal (Delay Compensated)', ...
        'Location', 'best');
end

function plotFrequencyComparison(originalSignal, filteredSignal, fs, cutoffFreq)
%PLOTFREQUENCYCOMPARISON Compare the FFT magnitude spectra in dB.

    numSamples = numel(originalSignal);
    nfft = 2^nextpow2(numSamples);
    frequencyAxis = (0:nfft/2) * (fs / nfft);

    originalSpectrum = fft(originalSignal, nfft);
    filteredSpectrum = fft(filteredSignal, nfft);

    originalMagnitudeDB = 20 * log10(abs(originalSpectrum(1:nfft/2 + 1)) + eps);
    filteredMagnitudeDB = 20 * log10(abs(filteredSpectrum(1:nfft/2 + 1)) + eps);

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
