function [varargout] = tonepip(sampfreq, PARS)
% tonepip  - generate a tone pip with amplitude (V), frequency (Hz)
% delay (msec), duration (msec).
% if no rf (risefall) time is given, cosine shaping 5 msec is applied.
% if no phase is given, phase starts on 0, with positive slope.
%
% 4/2010 P. Manis. Minor fix for delay to first tone (was adding 2 delays).
% 
% Input structure PARS must have at least the following members:
% PARS.n_sweeps = 1;
% PARS.amp = 5.;  % nominal V output
% PARS.freq = 2000.; %hertz
% PARS.attn = 30.;
% PARS.delay = 50.0;  % milliseconds
% PARS.duration = 100.;  % milliseconds
% PARS.rf = 2.5;  % milliseconds
% PARS.phase0 = 0.;
% PARS.sine = 0.
% PARS.dmod = 0.

if nargout == 0 
    PARS = testpars();
    sampfreq = 100000.;
end;

% 1. Generate the basic tone pip
% 2. gate the signal
% 3. add a delay to the start of the signal
% 4. if there are multiple pulses, then we need to add code to concatenate
% appropriately.
[ws, wc] = tone(sampfreq, PARS);
if PARS.sine == 0
    % use ws not wc
    wf = ws;
else
    wf = wc;
end
if PARS.dmod > 0.  % add modulation
    wf = wf .* envel(sampfreq, PARS);  % envelope is phase shifted -90 to start at 0.
end
wf = cosgate(sampfreq, wf, PARS.rf);
sratems = 1000.0/sampfreq;
delaypts = floor(PARS.delay/sratems);
wf = vertcat(zeros(delaypts, 1), wf);
if(nargout >= 1)
    varargout{1} = wf;
end

% if called from command line with no output, plot the spectrum
if(nargout == 0)
    [Pxx,F] = pwelch(wf, 512, 64, 4096, sampfreq);

    h = findobj('tag', 'tone_pip.gen_fig');
    if(~isempty(h))
        figure(h);
        clf;
        subplot(2, 1, 1);
        plot(F, Pxx);
    else
        figure('tag', 'tone_pip.gen_fig');
        subplot(2, 1, 1);
        plot(F, Pxx);
    end;
    set(gca, 'Xlim', [1000. 50000]);
    set(gca, 'XScale', 'log');
    subplot(2, 1, 2);
    plot(0:1.0/sampfreq:(length(wf)-1)/sampfreq, wf);
end;

end

% function [p] = testpars()
% 
% % This routine generates a noise using the input arguments as follows:
% PARS.n_sweeps = 1;
% PARS.amp = 5.;  % nominal V output
% PARS.freq = 2000.; %hertz
% PARS.attn = 30.;
% PARS.delay = 50.0;  % milliseconds
% PARS.duration = 500.;  % milliseconds
% PARS.rf = 2.5;  % milliseconds
% PARS.phase0 = 0.;
% PARS.dmod = 1;
% PARS.fmod = 20.;
% % The subsequent arguments depend on the mode
% PARS.noise.passtype = 'notch'; % for noise, choices wideband, lowpass, highpass, notch, bandpass and octave
% PARS.noise.f1 = 6000.;  % high pass corner freq
% PARS.noise.f2 = 8000.; % low pass corner
% PARS.noise.ftype = 'butter';
% PARS.noise.order = 8;
% PARS.noise.nstage = 4;
% PARS.noise.clip = [-10., 10.];
% 
% p = PARS;
% end
% 
