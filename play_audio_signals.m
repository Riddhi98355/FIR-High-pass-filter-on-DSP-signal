function play_audio_signals(originalSignal, filteredSignal, fs)
%PLAY_AUDIO_SIGNALS Play original audio first, then filtered audio.
%   PLAY_AUDIO_SIGNALS(originalSignal, filteredSignal, fs) plays the
%   original mono signal, waits until playback finishes, inserts a short
%   delay, and then plays the filtered signal.

    if nargin < 3
        error('Usage: play_audio_signals(originalSignal, filteredSignal, fs)');
    end

    playbackGap = 0.5; % Extra delay between original and filtered playback

    % Normalize for safe playback without clipping.
    originalPlayback = normalize_for_playback(originalSignal);
    filteredPlayback = normalize_for_playback(filteredSignal);

    fprintf('Playing original audio...\n');
    sound(originalPlayback, fs);
    pause(length(originalPlayback) / fs + playbackGap);

    fprintf('Playing filtered audio...\n');
    sound(filteredPlayback, fs);
end

function outputSignal = normalize_for_playback(inputSignal)
%NORMALIZE_FOR_PLAYBACK Scale signal safely for audio playback.

    inputSignal = inputSignal(:);
    outputSignal = 0.98 * inputSignal / max(abs(inputSignal) + eps);
end
