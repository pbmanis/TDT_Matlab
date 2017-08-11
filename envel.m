function [varargout] = envelope(sampfreq, PARS)
% tonepip  - generate an envelope tone pip with amplitude (V), frequency (Hz)
% delay (msec), duration (msec).

% 4/2010 P. Manis. Minor fix for delay to first tone (was adding 2 delays).
% 8/2016-10/2016: Modified P. Manis/ T. Ropp
% The input structure PARS must contain:
% PARS.amp
% PARS.freq
% PARS.duration
% PARS.RF
% PARS.phase0

if nargout == 0 
    fprintf(2, 'amp: %f  modfreq: %f moddepth: %f delay = %f  duration = %f  rf = %f\n',...
       PARS.amp, PARS.fmod, pars.dmod, PARS.duration, PARS.rf);
end;

clock = 1000/sampfreq; % calculate the sample clock rate - msec (khz)
phi = 2*pi*(PARS.phase0+90.)/360; % convert phase from degrees to radians...
tpts = floor(PARS.duration/clock); % duration of a signal
tb = 0:clock:(tpts-1)*clock;
ws = 1.0 - PARS.dmod*sin(phi + 2*pi*PARS.fmod/1000*tb)';

if(nargout >= 1)
    varargout{1} = ws;
end;

return;