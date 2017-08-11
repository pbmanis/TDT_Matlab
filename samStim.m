function [varargout] = samStim(sampfreq,PARS)

if nargout == 0 
    PARS = testpars();
    sampfreq = 100000.;
end;

sineC = tone(sampfreq, PARS);
PARS.freq = PARS.fmod;
PARS.sine = 1;
stimlen = length(sineC);
sineM =ones(stimlen,1)+ PARS.dmod*tone(sampfreq,PARS);

ws = sineC .* sineM./PARS.amp;  %correction for multiplying by the amplitude twice
if PARS.dmod > 0.
    ws = ws .* envel(sampfreq, PARS);  % envelope is phase shifted -90 to start at 0.
end;

wf = cosgate(sampfreq, ws, PARS.rf);
sratems = 1000.0/sampfreq;
delaypts = floor(PARS.delay/sratems);
wf = vertcat(zeros(delaypts, 1), wf);
tb = 0:sratems:(length(wf)-1)*sratems;
figure(88);
plot(wf)
if(nargout >= 1)
    varargout{1} = wf;
end;

if nargout == 0
    ff = findobj('tag', 'tonepip_figure');
    if isempty(ff)
        ff = figure;
        set(ff, 'tag', 'tonepip_figure');
        set(ff, 'Name', 'Tone Pip Test');
        set(ff, 'NumberTitle', 'off');
    else
        figure(ff);
        cla;
    end;
    plot(tb, wf);
end

end

