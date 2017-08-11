function gatedwave = cosgate(sampfreq, ws, rf)
%
% Generate a cosine^2 gated version of the incoming signal
% sampfreq is the sample frequency (Hz)
% Incoming waveform is in ws. 
% Rise-fall time is in rf (in msec)
% Returns: gated signal
%
gatedwave = ws;

if rf <= 0.
    return
end;

clock = 1000/sampfreq; % calculate the sample clock rate - msec (khz)

% build sin^2 rising and falling filter from 0 to 90 deg for shaping the waveform
nfilter_points = floor(rf/clock); % number of points in the filter rising/falling phase
fo = 1/(4*rf); % filter "frequency" in kHz - the 4 is because we use only 90deg for the rf component
fil = zeros(length(ws),1);

for i = 1:nfilter_points % rising filter shape
    fil(i) = sin(2*pi*fo*(i-1)*clock).^2; % filter
end;
for j = nfilter_points+1:(length(ws)-nfilter_points) % main part shape
    fil(j) = 1;
end;
i = 0;
for k = j+1:length(ws) % decay shape
    fil(k) = fil(nfilter_points+i); %reverse the rising phase
    i = i - 1;
end;

gatedwave = gatedwave.*fil; % this makes the stimulus pulse (sine, ramped)

if nargout == 0
    plot(fil);
end;
return;
