% StimController: a program to generate and present stimuli
% interacting with the RZ5D and NI 6731 card
% Uses TDEVAcc methods
% Somewhat limited, but sufficient to set up triggers
%
function []=StimController22(varargin)

global AO RZ5D RPActive DA RP
global STIM STPARS STCOUNT SPKR SPLCAL
global CAL

STCOUNT = 0;
RPActive = 0;
fprintf(2, 'StimController2.m [Using NI, PA5, and RZ5D]\n');

% set up for calibration
Speaker = 'MF1';
SPKR.id = Speaker;
switch (SPKR.id)
    case {'ES1', 'EC1'}
        SPKR.attn = 0.0;
        SPLCAL.maxtones = 83.9; % New calibration, 5/1/2010 P. Manis Assumes ES Driver at - 6dB for linearity
        SPLCAL.maxclick = 79.5; % 84.8; 79 is with 6db attenuation ES1...
    case {'MF1'}
        SPKR.attn = 30.0; % for tones... 
        SPLCAL.maxtones = 110.0; % for mf1 speaker
        SPLCAL.maxclick = 108.5; % set with peak 1/4" mic output to match 80dB spl tone at "1e-6"
        % 114.8; % Old calibration 2007-4/30/2010db SPL with 0 dB attenuation (5 V signal)
    otherwise
        fprintf(2, 'Speaker type not known\n');
        return;
end;

% read calibration from the file in the ABR dataset
calpath = 'C:\Users\Experimenters\Desktop\ABR_Code';
load(sprintf('%s\\frequency_%s.cal', calpath, SPKR.id), '-mat'); % get calibration file. Result is in CAL
fprintf(1, '\nLoaded Calibration of %s with %s, on %s\n', CAL.Speaker, CAL.Microphone, CAL.Date);

% RP2.1 sample frequencies
% 0 = 6K, 1 = 12K, 2 = 25k, 3 = 50k, 4 = 100k, 5 = 200k, > 5 is not defined.
samp_cof_flag = 5; % 5 is for ~200 kHz
samp_flist = [6103.5256125, 12210.703125, 24414.0625, 48828.125, ...
    97656.25, 195312.5]; % MRK changed 122107.0312 to 12210.7031225
if(samp_cof_flag > 5)
    samp_cof_flag = 5;
end;

% define stimulus parameter structure
% must be set before setup is called.

STPARS.n_sweeps = 1;
STPARS.amp = 5;  % nominal V output
STPARS.freq = 2000.; %hertz
STPARS.attn = 30.;
STPARS.delay = 50.0;  % milliseconds
STPARS.duration = 100.;  % milliseconds
STPARS.rf = 2.5;  % milliseconds
STPARS.phase0 = 0.;
STPARS.dmod = 0.; % Modulation depth (0-1).
STPARS.fmod = 20.; % Hz modulation
STPARS.ipi = 100.; % milliseconds  
STPARS.np = 1;
STPARS.alternate = 0;
STPARS.nreps = 1;
STPARS.ISI = 2.;  % Seconds
STPARS.sine = 0;  % sin or cosine phase ???
% Other parameters
STPARS.noise.passtype = 'wideband'; % for noise, choices wideband, lowpass, highpass, notch, bandpass and octave
STPARS.noise.f1 = 8000.;  % high pass corner freq
STPARS.noise.f2 = 16000.; % low pass corner
STPARS.noise.ftype = 'butter';
STPARS.noise.order = 8;
STPARS.noise.nstage = 4;
STPARS.noise.clip = [-10., 10.]; % DAC limits for noise
STPARS.acquire_mode = 3; % set to 2 for preview

externalTrigger = 1;
[RP, DA, RZ5D] = setup(samp_cof_flag);  % setup hardware all devices
% Now get the NI card set up.
AO = get_NI(externalTrigger);

if RPActive == 1
    STIM.sample_freq = samp_flist(samp_cof_flag); % get RP2.1 rate 
else
    STIM.sample_freq = 500000.;
    AO.Rate = STIM.sample_freq; % using NI Card, rate set in harware_initialization.m
end

set_attn(120.)

cmd = '';
set(gcf,'currentchar',' ')
while get(gcf,'currentchar')==' '
%while 1
    cmd = input('Stim Controller> ', 's');
    [cmdkey, remain] = strtok(cmd, ' ');
    % fprintf(1, '    cmd: %s\n', cmdkey);
    if strcmp(cmdkey, '')
        continue
    end
    switch cmdkey
         case 'tonepip'            
            if isempty(remain)
                spl = 75.0;
            else
                a = textscan(remain, '%s');
                spl = seq_parse(a{1}{1});
                spl = spl{1};
            end
            % STPARS
            STIM.wave  = tonepip(STIM.sample_freq, STPARS);
            %STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS); 
            set_dbSPL(spl, STPARS.freq);
            one_stim_set(STPARS);
            set_attn(120.);
            stop_stim(RP, DA, AO);
            
        case 'ri'
            fprintf(2, 'RI\n');
            a = textscan(remain, '%s %s');
            STPARS.freq = 1000*str2double(a{1}{1});
            attnlist = seq_parse(a{2}{1});
            attnlist = attnlist{1};
            %fprintf (1, 'RI: points %f\n', STPARS.ISI*RZ5D.dev_SF);
            STIM.wave  = tonepip(STIM.sample_freq, STPARS);
            STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
            plot(STIM.wave);
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_dbSPL(STPARS.attn, STPARS.freq);
                fprintf(2, 'Attenuator: %f  [%d]\n', attnlist(i), i);
                one_stim_set(STPARS);
            end
            set_attn(120.);
            stop_stim(RP, DA, AO);
            
        case {'map', 'fra', 'FRA'}
            fprintf(2, 'Frequency response area map\n');
            a = textscan(remain, '%s %s');
            freqs = seq_parse(a{1}{1});
            freqs = freqs{1};
            attnlist = seq_parse(a{2}{1});
            attnlist = attnlist{1};
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_dbSPL(STPARS.attn, STPARS.freq);
                for j = 1:length(freqs)
                    STPARS.freq = 1000.*freqs(j);
                    STIM.wave  = tonepip(STIM.sample_freq, STPARS);
                    STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
                    fprintf(1, 'F: %7.3f  I: %4.1f\n', STPARS.freq, STPARS.attn);
                    one_stim_set(STPARS);
                end
            end
            set_attn(120.);
            stop_stim(RP, DA, AO);
            
        case 'noise'  % noise rate-intensity 
            %input desired sound levels e.g.- noise 20:10:40
            %TFR added
            a = textscan(remain, '%s');
            attnlist = seq_parse(a{1}{1});
            attnlist = attnlist{1};
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_dbSPL(STPARS.attn, 0.)
                STIM.wave = noise_gen(STIM.sample_freq, STPARS);
                STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
                one_stim_set(STPARS);
            end
            set_attn(120.);
            stop_stim(RP, DA, AO);

         case 'search'  % noise mode for search, don't save data 
            %input desired sound levels e.g.- search 20:10:40
            %TFR added
            a = textscan(remain, '%s');
            attnlist = seq_parse(a{1}{1});
            attnlist = attnlist{1};
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            STPARS.acquire_mode = 2;
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_dbSPL(STPARS.attn,STPARS.freq)
                STIM.wave = noise_gen(STIM.sample_freq, STPARS);
                STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
                one_stim_set(STPARS);
            end
            set_attn(120.);
            stop_stim(RP, DA, AO);

        case {'sam', 'SAM'}  % SAM Rate-intensity, single stimulus condition        
            fprintf(2, 'SAM RI\n');
            a = textscan(remain, '%s %s');
            STPARS.freq = 1000*str2double(a{1}{1});
            attnlist = seq_parse(a{2}{1});
            attnlist = attnlist{1};
            STIM.wave  = samStim(STIM.sample_freq, STPARS);
            STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_dbSPL(STPARS.attn, STPARS.freq)
                one_stim_set(STPARS);
            end
            set_attn(120.);
            stop_stim(RP, DA, AO);
        
         case {'mtf', 'MTF'}  % SAM modulation transfer function          
            fprintf(2, 'SAM Mod Xfer Function\n');
            a = textscan(remain, '%s %s');
            modfreqs = seq_parse(a{1}{1});
            modfreqs = modfreqs{1};
            attnlist = seq_parse(a{2}{1});
            attnlist = attnlist{1};
            STIM.wave  = samStim(STIM.sample_freq, STPARS);
            STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_dbSPL(STPARS.attn, STPARS.freq);
                for j = 1:length(modfreqs)
                    STIM.fmod = modfreqs(j);
                    STIM.wave  = samStim(STIM.sample_freq, STPARS);
                    STIM.wave = build_cycle(STIM.wave, STIM.sample_freq, STPARS);
                    one_stim_set(STPARS);
                end
            end
            set_attn(120.);
            stop_stim(RP, DA, AO);

        case {'fsweep', 'fm', 'fmsweep'}  % expects list of frequencies
            fsw = seq_parse(remain);
            swf = fsw{1};
            for i = 1:length(swf)
                STPARS.freq = swf(i);
                STIM.wave  = tonepip(STIM.sample_freq, STPARS.amp, STPARS.freq, ...
                    STPARS.delay, STPARS.duration, STPARS.rf, ...
                    STPARS.phase0,  ...
                    STPARS.ipi, STPARS.np, ...
                    STPARS.alternate);
                tstart = tic;
                max(STIM.wave)
                present_stim(RP, DA, RZ5D, AO);
                while toc(tstart) < STPARS.ISI   
                end

            end
     %       DA.SetSysMode(0);
            set_attn(120.);
            stop_stim(RP, DA, AO);

        case 'nsweep'  % set number of sweeps
            STPARS.n_sweeps = str2double(remain);
        case {'nreps', 'nrep'}
            STPARS.nreps = str2double(remain);
        case {'del', 'delay'}  % set stimulus delay
            STPARS.delay = str2double(remain);
        case {'dur', 'duration'}
            STPARS.duration = str2double(remain);
        case {'rise', 'rf'}
            STPARS.rf = str2double(remain);
        case 'phase0'
            STPARS.phase0 = str2double(remain);
        case 'ipi'
            STPARS.ipi = str2double(remain);
        case {'ISI', 'isi'}
            STPARS.ISI = str2double(remain);
        case 'np'
            STPARS.np = str2double(remain);
        case 'dmod'
            STPARS.dmod = str2double(remain);
        case 'fmod'
            STPARS.fmod = str2double(remain);
        case {'freq', 'frequency'}
            STPARS.freq = str2double(remain);
        case {'alt', 'alternate'}
            alt = strcmpi(remain, {'off', 'on'});
            if any(alt)
                fprintf(2, 'Alternation: options are on and off; got %s\n', remain)
                break
            end
            if alt(0) == 1
                STPARS.alternate = false;
            end
            if alt(1) == 1
                STPARS.alternate = true;
            end

        case 'show'  % list current stim parameters
            STPARS
            
        case 'quit'
            break;
            
        otherwise
            fprintf(2, 'Unrecognized command: %s\n', cmdkey);
    end %of switch
    
    
end %while loop
DA.SetSysMode(1); % leave in standby
pause(1)
DA.CloseConnection();

fprintf(1, 'StimController ... quitting\n');
return %for StimController
end %of function StimController

function [w] = build_cycle(w, samplefreq, PARS)
% build out the waveform to the cycle time (ISI) time.
% pts = length(w);
% needpts = floor(PARS.ISI*samplefreq) - pts;
% w = vertcat(w, zeros(needpts, 1));
w = w;
end

function one_stim_set(STPARS)
global RP DA RZ5D AO STCOUNT
STCOUNT = 0;
duration = STPARS.ISI*STPARS.nreps + (STPARS.duration+STPARS.delay)/1000.;
%fprintf(2, 'Duration: %d\n', int64(duration));
present_stim(RP, DA, RZ5D, AO);
tstart = tic;
while toc(tstart) < duration
    pause(0.001)
end
toc(tstart)
stop_stim(RP, DA, AO);
fprintf(2, 'Stimcount: %d\n', STCOUNT);
end

function stop_stim(RP, DA, AO)
global RPActive
global STPARS
STPARS.acquire_mode = 3;
if RPActive
    RP.Halt;
else
    AO.stop;
end
DA.SetSysMode(1); % then Standby
end

function [attn] = set_dbSPL(spl, freq)
% interpolate to get the attenuation at the requested frequency
global SPKR
global CAL
if freq > 0  % for single freq or narrow-band stimuli
    splatF = interp1(CAL.Freqs, CAL.maxdB, freq, 'spline');
else
    splatF = interp1(CAL.Freqs, CAL.maxdB, 16000, 'spline');
    
end
attn = splatF-spl+SPKR.attn;
if(attn < 6.)
    fprintf(2, 'Requesting sound louder than available with this speaker\nSetting to 6 dB attn\n');
    attn = 6.;
end;
set_attn(attn)
end


function  present_stim(RP, DA, RZ5D, AO)
global STIM
global STPARS
global RPActive
global Listener

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% It is **essential** that the RZ5D be in Standby (NOT IDLE)
% mode in order to set parameters to the circuit elements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DA.SetSysMode(1)  
% fprintf(1, 'setting ISI to %f\n', STPARS.ISI*RZ5D.dev_SF)
DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
DA.SetTargetVal(RZ5D.Cnt, STPARS.nreps);

if RPActive
    loadRP2(RP, STIM)
    Listener = [];
else
    loadNI(AO, STIM);
end

DA.SetSysMode(STPARS.acquire_mode); % enter mode to start data collection
pause(0.25);
end

function  [RP, DA, RZ5D] = setup(samp_cof_flag)
global STIM
global STPARS
global RPActive

if RPActive == 1
    RP=actxcontrol('rpco.x', [5 5 26 26]);
    if(RP.ConnectRP2('USB',1) == 0)
        error('failed to connect to rp2');
    end;
    STIM.RP2COFFlag = samp_cof_flag;

    if RP.ClearCOF() == 0
        error('failed to clear cof');
    end;
    thisdir = pwd;
    if (RP.LoadCOFsf(['C:\TDT\OpenEx\MyProjects\EPhys_RZ5D_PZ5-32\RCOCircuits\TriggeredWaveformPlayer_RP2.rcx'], ...
           STIM.RP2COFFlag) == 0)
        error ('failed to load TriggeredWaveformPlayer.rcx file');
    end;
    if RPActive == 1
        sfreq=RP.GetSFreq();
        fprintf(1, 'RP2.1 : true sample frequency: %.6f hz\n', sfreq);
        STIM.sample_freq = sfreq;
    end
    RP.Run();

    status = double(RP.GetStatus());
    if bitget(double(status), 1) == 0
        fprintf(2, 'rp_setup: Error connecting to RP2.1\n');
        err = 1;
        return;
    elseif bitget(double(status), 2) == 0
        fprintf(2, 'rp_setup: Error loading circuit to RP2.1\n');
        err = 1;
        return;
    elseif bitget(double(status), 3) == 0
        fprintf(2, 'Error running circuit in RP2.1\n');
        err = 1;
        return;
    else
        % disp('circuit loaded and running');
    end
else
    RP = [];
end

% 
fprintf(1, 'Attempting to Connect to RZ5D\n');
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local')
while DA.CheckServerConnection ==0
    fprintf(1, 'Server Not Connected, reattempting connection \n')
    DA.ConnectServer('Local')
end
RZ5D.device_Name = DA.GetDeviceName(0);
fprintf(1, 'Device found: %s\n', RZ5D.device_Name);

rco_file = DA.GetDeviceRCO(RZ5D.device_Name);
fprintf(1, 'Device RCO/X file: %s\n', rco_file);

keySet =   {0, 1, 3, 5, 7};
valueSet = {'Nothing', 'Connected', 'Connected and loaded', ...
    'Connected and running', 'Connected, loaded and running'};
StatusMap = containers.Map(keySet,valueSet);
RZ5D.device_Status = DA.GetDeviceStatus(RZ5D.device_Name);
% if connected == 1 & RZ5D.device_Name== ' '
%     DA.ConnectServer('Local')
% end
if DA.ConnectServer('Local') == 0 
%     DA.ConnectServer('Local')
%     RZ5D.device_Name = DA.GetDeviceName(0)
%     RZ5D.device_Status = DA.GetDeviceStatus(RZ5D.device_Name);
%     if RZ5D.device_Status == 0
        fprintf(2, 'Cannot connect to RZ5D? \n');
        return;
%     end
end
fprintf(1, '    RZ5D Device Status: %s\n', StatusMap(RZ5D.device_Status));

RZ5D.Period = 'ACQ_16ch.zSwPeriod';
RZ5D.SweepTrigger = 'ACQ_16Ch.SweepTrigger'; % set to 1 to start trigger, 0 to clear
RZ5D.Cnt = 'ACQ_16ch.zSwCount';
RZ5D.SWN = 'ACQ_16ch.SweepNum';
RZ5D.Done = 'ACQ_16ch.SweepDone';
RZ5D.NStim = 'ACQ_16ch.NStim';
RZ5D.ISIms = 'ACQ_16ch.ISIms';

RZ5D.dev_SF = DA.GetDeviceSF(RZ5D.device_Name); % get device sample frequency
fprintf(1, '    RZ5D Sample Frequency: %f\n\n', RZ5D.dev_SF);

DA.SetTargetVal(RZ5D.Cnt, 1);
RZ5D.zSwCount = DA.GetTargetVal(RZ5D.Cnt);

DA.SetTargetVal(RZ5D.Period, floor(STPARS.ISI*RZ5D.dev_SF));
set_attn(120.);
return
end


function getTags(dev, dn, type)
tag =  dev.GetNextTag(dn, type, 1);
if ~strcmp(tag, '')
    fprintf(1, 'Type %2d: Tag = %s\n', type, tag);
end
while ~strcmp(tag,'' )
    tag =  dev.GetNextTag(dn, type, 0);
    if strcmp(tag,'' )
        return
    end
    fprintf(1, '         Tag = %s\n', tag);
end
end


function RP=loadRP2(RP, STIM)

RP.SetTagVal('BufSize', floor(length(STIM.wave)));
fprintf(1, 'Buffer size set to: %d\n', RP.GetTagVal('BufSize'));
fprintf(1, 'dataIn: %d\n', RP.GetTagVal('waveform'));
%inputwave=(STIM.wave)'
%RP.WriteTagV('waveform', 0, inputwave)

if ~RP.WriteTagV('waveform', 0, STIM.wave')
    fprintf(2, 'loadRP2: Failed to set waveform\n');
    err = 1;
    return;
end;
RP.Run;
%RP.SoftTrg(1);
%fprintf(1, 'Buffer size intended: %d\n', length(STIM.wave));
%fprintf(1, 'Buffer size loaded: %d\n', RP.GetTagVal('BufSize'));
end

function queueMoreData(src, event)
global STIM AO STCOUNT STPARS

if STCOUNT <= STPARS.nreps-1
    fprintf(2, 'Queueing: count = %d\n', STCOUNT);
    queueOutputData(AO, STIM.wave);
    STCOUNT = STCOUNT + 1;
end
end

function loadNI(AO, STIM)
global Listener STCOUNT STPARS
AO.stop
AO.Rate = STIM.sample_freq;
%fprintf(2, 'len stim.wave: %d, ao rate: %f\n', length(STIM.wave), AO.Rate);

queueOutputData(AO, STIM.wave); % Queue data for output
STCOUNT = 1;
% the next 2 lines were commented out
AO.TriggersPerRun = STPARS.nreps;
%startForeground(AO);
startBackground(AO); % get ni board read to go, then trigger the rp
minnotifyperiod = floor(0.05*AO.Rate);
notifyperiod = floor(0.1*AO.Rate);
if notifyperiod < minnotifyperiod
    notifyperiod = minnotifyperiod;
end
%AO.NotifyWhenScansQueuedBelow = notifyperiod;

%Listener = addlistener(AO,'DataRequired', @queueMoreData);
% queueOutputData(AO, STIM.wave); % wave is FULL
% AO.IsContinuous = true;
% next line was not commented out
% AO.startBackground

end




