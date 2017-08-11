
function [wf, sr] = noise_gen(sample_freq, PARS)
%
% noise generator for audtiory experiments
% This routine generates a noise using the input arguments as follows:
% PARS.n_sweeps = 1;
% PARS.amp = 10.;  % nominal V output 
% PARS.freq = 2000.; %hertz
% PARS.attn = 30.;
% PARS.delay = 50.0;  % milliseconds
% PARS.duration = 100.;  % milliseconds
% PARS.rf = 2.5;  % milliseconds
% The subsequent arguments depend on the mode
% PARS.noise.passtype = 'wideband'; % for noise, choices wideband, low, high, stop, bandpass
% PARS.noise.f1 = 8000.;  % high pass corner freq
% PARS.noise.f2 = 16000.; % low pass corner
% PARS.noise.ftype = 'butter';
% PARS.noise.order = 8;
% PARS.noise.nstage = 4;
% PARS.noise.clip = [-10., 10.]

% if no output, then the program generates 1 sec worth of data at 500 kHz, and
% calculates the power spectrum of the result
% otherwise,it fills the output with the waveform and the sample rate.

% 26 March 2007 Paul B. Manis, Ph.D.
% UNC Chapel Hill

% generate the wideband noise signal first
%

if nargout == 0
    PARS = testpars();
    sample_freq = 100000.;
end

Fs = sample_freq; % sample rate, points per second (Hz)  e.g. 97656
fclp = Fs;

sr = 1/Fs;  % seconds per point
npnts = floor((PARS.duration/1000.)/sr);
wbn = randn(npnts, 1);
wbn(1) = 0;
wbn(npnts-2:npnts) = 0;

nstage = PARS.noise.nstage;

switch(PARS.noise.passtype)
    case 'wideband'
        fclp = Fs;
        % do nothing
    case {'low', 'LP', 'lp'}
        fclp = PARS.noise.f1; 
    case {'high', 'HP', 'hp'}
        fclp = PARS.noise.f2;
    case {'bandpass'}
        [fclp] = sort([PARS.noise.f1, PARS.noise.f2]);
    case {'stop', 'notch'}
        PARS.noise.passtype = 'stop';
        [fclp] = sort([PARS.noise.f1, PARS.noise.f2]);

    otherwise
end

wf = wbn;
% cutoff frequency in Hz
wco = fclp/(Fs/2.0); % wco of 1 is for half of the sample rate, so set it like this...
if(all(wco < 1)) % if wco is > 1 then this is not a filter!
    [b, a] = filterselect(PARS.noise.ftype, PARS.noise.order, wco, PARS.noise.passtype);
    for i = 1:PARS.noise.nstage
        wf = filter(b, a, wf); % filter all the traces...repeatedly
    end;
    for i = 1:nstage
        [b, a] = filterselect('elliptic', PARS.noise.order, wco, PARS.noise.passtype);
        wf = filter(b, a, wf); % filter all the traces...repeatedly
    end
end
if PARS.dmod > 0.
    wf = wf .* envelope(sample_freq, PARS);  % envelope is phase shifted -90 to start at 0.
end;
% TFR- adding cosine gate with 3ms risefall
wf = cosgate(Fs, wf, PARS.rf); %TFR- adding cosine gate

sratems = 1000.0/sample_freq;
delaypts = floor(PARS.delay/sratems);
wf = vertcat(zeros(delaypts, 1), wf);
wf(wf > PARS.noise.clip(2)) = PARS.noise.clip(2);
wf(wf < PARS.noise.clip(1)) = PARS.noise.clip(1);


if(nargout == 0)
    [Pxx,F] = pwelch(wf, 512, 64, 4096, sample_freq);

    h = findobj('tag', 'noise.gen_fig');
    if(~isempty(h))
        figure(h);
        clf;
        subplot(2, 1, 1);
        plot(F, Pxx);
    else
        figure('tag', 'noise.gen_fig');
        subplot(2, 1, 1);
        plot(F, Pxx);
    end;
    set(gca, 'Xlim', [1000. 50000]);
    set(gca, 'XScale', 'log');
    subplot(2, 1, 2);
    plot(0:1.0/sample_freq:(length(wf)-1)/sample_freq, wf);
end;
end

function [b, a] = filterselect(type, order, wco, passtype)

switch(type)
    case 'butter'
        [b, a] = butter(order, wco, passtype); % butterworth
    case 'elliptic'
        [b, a] = ellip(order, 0.1, 120, wco, passtype);
    case 'cheby1'
        [b, a] = cheby1(order, 0.1, wco, passtype);
    case 'cheby2'
        [b, a] = cheby2(order, 10, wco, passtype);
    otherwise
        [b, a] = butter(order, wco, passtype); % butterworth

end;
end

function [p] = testpars()

% This routine generates a noise using the input arguments as follows:
PARS.n_sweeps = 1;
PARS.amp = 5.;  % nominal V output
PARS.freq = 2000.; %hertz
PARS.attn = 30.;
PARS.delay = 50.0;  % milliseconds
PARS.duration = 100.;  % milliseconds
PARS.rf = 2.5;  % milliseconds
PARS.phase0 = 0.;
PARS.dmod = 0.5;
PARS.fmod = 20.;
% The subsequent arguments depend on the mode
PARS.noise.passtype = 'notch'; % for noise, choices wideband, lowpass, highpass, notch, bandpass and octave
PARS.noise.f1 = 6000.;  % high pass corner freq
PARS.noise.f2 = 8000.; % low pass corner
PARS.noise.ftype = 'butter';
PARS.noise.order = 8;
PARS.noise.nstage = 4;
PARS.noise.clip = [-10., 10.];

p = PARS;
end
