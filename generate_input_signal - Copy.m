% Generate sample audio for the FIR high-pass filter project
% The signal contains:
% 1. A low-frequency component around 500 Hz
% 2. A high-frequency component around 6000 Hz
% The result is saved as input.wav at 48000 Hz.

clear;
clc;
close all;

%% Signal parameters
fs = 48000;          % Sampling frequency in Hz
durationSec = 5;     % Audio duration in seconds
fLow = 500;          % Low-frequency component in Hz
fHigh = 6000;        % High-frequency component in Hz

%% Time vector
t = (0:1/fs:durationSec - 1/fs).';

%% Generate audio components
lowFrequencyNoise = 0.7 * sin(2 * pi * fLow * t);
highFrequencySignal = 0.4 * sin(2 * pi * fHigh * t);

%% Combine components
inputSignal = lowFrequencyNoise + highFrequencySignal;

% Normalize to avoid clipping when saving
inputSignal = 0.95 * inputSignal / max(abs(inputSignal));

%% Save as WAV file
outputFileName = 'input.wav';
audiowrite(outputFileName, inputSignal, fs);

%% Optional preview plot
previewSamples = min(1000, length(inputSignal));
timeAxis = (0:previewSamples - 1) / fs;

figure('Name', 'Generated Input Signal', 'Color', 'w');
plot(timeAxis, inputSignal(1:previewSamples), 'LineWidth', 1.1);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Preview of Generated Input Signal');

%% Console message
fprintf('Generated %s successfully.\n', outputFileName);
fprintf('Sampling rate: %d Hz\n', fs);
fprintf('Duration     : %.2f seconds\n', durationSec);
fprintf('Components   : %d Hz and %d Hz\n', fLow, fHigh);
