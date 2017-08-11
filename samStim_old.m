function [stimulus] = samStim(modfreq, amp, freq, delay, duration, rf, phase0, sampfreq, ipi, np, alternate)
% samStim  - generates a sine amplitude modulated stimuli of a certain 
% frequency (Hz) with a modulation frequency (Hz) using Paul's tonepip 
% generator.
%
% 4/2016 TFR
% 

if nargout == 0 
    fprintf(2, 'amp: %f  freq: %f  delay = %f  duration = %f  rf = %f  ipi = %f  np = %f\n',...
       amp, freq, delay, duration, rf, ipi, np);
end;

if(nargin < 5)
    fprintf(2, 'samStim requires at least 5 arguments: amp, freq, delay, duration\n');
    return;
end;

if(nargin == 5)
    phase0 = 0; % set defaults
    rf = 5;
    np = 1;
    ipi = 20;
    alternate  = 0;
end;
if(nargin < 6)
    phase0 = 0;
    np = 1;
    ipi = 20;
    alternate  = 0;
end;
if(nargin <= 7)
    sampfreq = 500000; % sec....
    np = 1;
    ipi = 20;
    alternate  = 0;
end;
% assume that ipi, np and alternate are set if more than 6 arguments.
if(nargin > 11)
    disp('too many arguments to samStim');
    return;
end;
if(nargout == 0)
    plotflag = 1;
else
    plotflag = 0;
end;
phase0=-90;
sineC = tone(amp, freq, delay, duration, 0, phase0, sampfreq, ipi, np, alternate);
%figure(52); plot(purelysine)
stimlen = length(sineC);
sineM =ones(stimlen,1)+ 0.7*tone(1, modfreq, delay, duration, 0, -90, sampfreq, ipi, np, alternate);
%figure(53); plot(sineM);

sam = sineC .* sineM;

stimulus = cosgate(sam,rf,duration,sampfreq,delay,ipi,np,alternate);

%figure(54); plot(sam)
%stimulus=sam
% 
% i = 0;
% for k = j+1:j+nfilter_points % decay shape
%     fil(k) = fil(nfilter_points+i); %reverse the rising phase
%     i = i - 1;
% end;
% %Fs = 1000/clock;
% %phi = 0; % initial phase
% tfil = 0:clock:(length(fil)-1)*clock;
% ws = amp*sin(phi + 2*pi*freq/1000*tfil)';
% if rf > 0.0
%     wf = ws.*fil; % this makes the stimulus pulse (sine, ramped)
% else
%     wf = ws;
% end;
% nwf = length(wf);
% %
% % next put in context and make an output waveform
% %
% id = floor(ipi/clock); % spacing between pulses
% jd = floor(delay/clock); % delay to start of stimulus
% if jd <= 0
%     jd = 1;
% end
% 
% 
% if(np > 1)
% %    w = zeros(jd+np*np_ipi+nwf, 1);
%     w = zeros(jd+np*np_ipi, 1);
% else
%     if jd + nwf < np_ipi
%         w = zeros(np_ipi, 1);
%     else
%         w = zeros(jd+nwf, 1);
%     end;
% end;
% 
% for i = 1:np
%     j0 = jd + (i-1)*id;
%     if jd == 0 && rf == 0.0
%         j0 = 1 + (i-1)*id;
%     end;
%     
%     if(alternate && mod(i,2) == 1)
%         sign = -1;
%     else
%         sign = 1;
%     end;
%     ij=1;
%     for j = j0:j0+nwf-1
%         w(j) = sign*wf(ij);
%         ij = ij + 1;
%     end;
%     
% end;
% w = w(1:length(w)-jd);  % cut tail points out of waveform so that we can
%                         % concatenate without a delay.
% 
% if(nargout >= 1)
%     varargout{1} = w;
% end;
% if(nargout >= 2)
%     varargout{2} = uclock;
% end;
% if(nargout >= 3)
%     varargout{3} = fil;
% end;
% 
% %fprintf(1, 'Stim Duration: %f pts,   %f msec\n', length(w), length(w)*clock);
% if(plotflag)
%     t = 0:clock:(length(w)-1)*clock;
%     ff = findobj('tag', 'tonepip_figure');
%     if isempty(ff)
%         ff = figure;
%         set(ff, 'tag', 'tonepip_figure');
%         set(ff, 'Name', 'Tone Pip Test');
%         set(ff, 'NumberTitle', 'off');
%     else
%         figure(ff);
%         cla;
%     end;
%     plot(t, w);
%     hold on
%     plot(tfil, fil, 'r');
%     plot(tfil, ws, 'g');
%     
%     plot(tfil, wf, 'c');
% end;

return;