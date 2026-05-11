function [inputSignal, filteredSignal, fs, filterCoeffs] = load_and_filter_audio(audioFile)
%LOAD_AND_FILTER_AUDIO Load a WAV file, ensure mono, and apply a high-pass FIR filter.
%   [inputSignal, filteredSignal, fs, filterCoeffs] = LOAD_AND_FILTER_AUDIO(audioFile)
%   loads the specified audio file, converts it to mono if needed, designs
%   a Hamming-window high-pass FIR filter, and filters the signal using
%   frame-based processing with MATLAB's filter() function.
%
%   Example:
%   [inputSignal, filteredSignal, fs, b] = load_and_filter_audio('input.wav');

    if nargin < 1
        audioFile = 'input.wav';
    end

    %% Filter specifications
    fsRequired = 48000;      % Required sampling frequency in Hz
    cutoffFreq = 3000;       % Cutoff frequency in Hz
    filterOrder = 64;        % Even order required for fir1 high-pass design
    numTaps = filterOrder + 1;
    frameSize = 256;         % Frame size for real-time simulation

    %% Load and validate audio
    [inputSignal, fs] = load_mono_audio(audioFile, fsRequired);

    %% Design FIR high-pass filter
    filterCoeffs = design_highpass_fir(fs, cutoffFreq, filterOrder, numTaps);

    %% Apply frame-based filtering
    filteredSignal = process_audio_frames(inputSignal, filterCoeffs, frameSize);

    %% Normalize filtered output only if needed
    peakValue = max(abs(filteredSignal));
    if peakValue > 1
        filteredSignal = 0.98 * filteredSignal / peakValue;
    end
end

function [monoSignal, fs] = load_mono_audio(audioFile, fsRequired)
%LOAD_MONO_AUDIO Read WAV audio, convert stereo to mono, and validate Fs.

    if ~isfile(audioFile)
        error('Audio file not found: %s', audioFile);
    end

    [audioData, fs] = audioread(audioFile);

    if fs ~= fsRequired
        error('Input audio must have sampling rate %d Hz. Found %d Hz.', fsRequired, fs);
    end

    if size(audioData, 2) > 1
        monoSignal = mean(audioData, 2);
    else
        monoSignal = audioData;
    end

    monoSignal = monoSignal(:);
end

function filterCoeffs = design_highpass_fir(fs, cutoffFreq, filterOrder, numTaps)
%DESIGN_HIGHPASS_FIR Design a Hamming-window high-pass FIR filter.

    normalizedCutoff = cutoffFreq / (fs / 2);
    filterCoeffs = fir1(filterOrder, normalizedCutoff, 'high', hamming(numTaps));
end

function filteredSignal = process_audio_frames(inputSignal, filterCoeffs, frameSize)
%PROCESS_AUDIO_FRAMES Filter the signal in chunks while preserving state.

    numSamples = length(inputSignal);
    filteredSignal = zeros(size(inputSignal));

    % Preserve filter memory between frames to maintain continuity.
    zi = zeros(length(filterCoeffs) - 1, 1);

    startIndex = 1;
    while startIndex <= numSamples
        endIndex = min(startIndex + frameSize - 1, numSamples);
        currentFrame = inputSignal(startIndex:endIndex);

        [filteredFrame, zi] = filter(filterCoeffs, 1, currentFrame, zi);
        filteredSignal(startIndex:endIndex) = filteredFrame;

        startIndex = endIndex + 1;
    end
end
