function [varargout] = tone(sampfreq, PARS)
% tonepip  - generate a tone pip with amplitude (V), frequency (Hz)
% delay (msec), duration (msec).
% does not shape the tone - just generates quadurature signals
% 4/2010 P. Manis. Minor fix for delay to first tone (was adding 2 delays).
% 8/2016-10/2016: Modified P. Manis/ T. Ropp
% The input structure PARS must contain:
% PARS.amp
% PARS.freq
% PARS.duration
% PARS.RF  % ignored
% PARS.phase0

if nargout == 0 
    fprintf(2, 'amp: %f  freq: %f  delay = %f  duration = %f  rf = %f\n',...
       PARS.amp, PARS.freq, PARS.duration, PARS.rf);
end;

clock = 1000/sampfreq; % calculate the sample clock rate - msec (khz)
phi = 2*pi*PARS.phase0/360; % convert phase from degrees to radians...
tpts = floor(PARS.duration/clock); % duration of a signal
tb = 0:clock:(tpts-1)*clock;
ws = PARS.amp*sin(phi + 2*pi*PARS.freq/1000*tb)';
wc = PARS.amp*cos(phi + 2*pi*PARS.freq/1000*tb)';

if(nargout >= 1)
    varargout{1} = ws;
    varargout{2} = wc;
end;

return;