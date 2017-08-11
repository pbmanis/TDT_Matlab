% Uses TDEVAcc methods. Somewhat limited, but sufficient to set up triggers
%
function []=StimController2(varargin)

global AO
global SPLCAL HARDWARE STIM STPARS RZ5D

fprintf(2, 'StimController2.m [using RZ5D, RP2.1]\n');


% designate the sample frequency
% 0 = 6K, 1 = 12K, 2 = 25k, 3 = 50k, 4 = 100k, 5 = 200k, > 5 is not defined.
samp_cof_flag = 4; % 4 is for 100 kHz
samp_flist = [6103.5256125, 12210.703125, 24414.0625, 48828.125, ...
    97656.25, 195312.5]; % MRK changed 122107.0312 to 12210.7031225
if(samp_cof_flag > 5)
    samp_cof_flag = 5;
end;
STIM.sample_freq = samp_flist(samp_cof_flag); % get RP2.1 rate

STPARS.n_sweeps = 1;
STPARS.amp = 5.;
STPARS.freq = 1000.;
STPARS.attn = 30.;
STPARS.delay = 0.01;  % seconds
STPARS.duration = 50.;  % milliseconds
STPARS.rf = 2.5;  % milliseconds
STPARS.phase0 = 0.;
STPARS.sampfreq = STIM.sample_freq;
STPARS.ipi = 0.1;
STPARS.np = 1;
STPARS.alternate = 0;
STPARS.ISI = 3.;  % Seconds

[RP, DA, RZ5D] = setup(samp_cof_flag);  % setup hardware all devices
finish=false;

% load figure character to check for stop
set(gcf,'CurrentCharacter','@')

while ~finish
    cmd = input('Stim Controller2 > ', 's');
    [cmdkey, remain] = strtok(cmd, ' ')
%     fprintf(1, '    cmd: %s\n', cmdkey);
    if strcmp(cmdkey, '')
        continue
    end
% set general stimulus parameters as appropriate
  
    switch cmdkey
        
        case 'search'
            oldISI = STPARS.ISI;
            STPARS.ISI = 1;
            STPARS.duration = 30;
            fprintf(2, 'SEARCH\n');
%             a = seq_parse(remain);
%             Lmax = 10^(100./20.);
%             Attnmax = 100.;
            fprintf(1, 'duration: %f\n', STPARS.duration);
            keyp = false;
            pflag = false;
            DA.SetSysMode(1); % put in standby mode first
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            show_sweepPeriod(DA, RZ5D);
            DA.SetSysMode(3); % enter mode to start data collection
            search_stim
            
%             for i = 1:10
%                 STPARS.attn = a{1};
%                 set_attn(STPARS.attn);
                STIM.wave = noise_gen(STPARS.duration, 'wideband', STPARS.sampfreq);
%                 if pflag == false
%                     figure(1); plot(STIM.wave);
%                     pflag = true;
%                 end;
                tstart = tic;
                loadNI(STIM,AO);
                present_stim(RP, DA, RZ5D, 2);  % use preview mode
                while toc(tstart) < 10000*STPARS.ISI
                    keyp = check_keys();
                    if keyp == true
                        break
                    end
                end
                if keyp == true
                    break
                end
            %end
            DA.SetSysMode(1);
            set_attn(120.);
            disp 'Done'
            STPARS.ISI = oldISI;  % restore

        case 'ri'
            fprintf(2, 'RI\n');
            [f, remain] = strtok(remain, ' ');
            a = seq_parse(remain);
            STPARS.freq = 1000*str2double(f);
            attnlist = a{1};
            fprintf (1, 'RI: points %f\n', STPARS.ISI*RZ5D.dev_SF);
            STIM.wave  = tonepip(STPARS.amp, STPARS.freq, ...
                STPARS.delay, STPARS.duration, STPARS.rf, ...
                STPARS.phase0, STPARS.sampfreq, ...
                STPARS.ipi, STPARS.np, ...
                STPARS.alternate);
            DA.SetSysMode(1); % put in standby mode first
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            show_sweepPeriod(DA, RZ5D);
            DA.SetSysMode(3); % enter mode to start data collection

            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_attn(STPARS.attn);
                fprintf(2, 'attn: %f  [%d]\n', attnlist(i), i);
%                 sf = (10.^((Attnmax - STPARS.attn)/20.))/Lmax;
                tstart = tic;
                %loadNI(STIM, AO);
                present_stim(RP, DA, RZ5D, 3);
                %                if i == 1
                while toc(tstart) < STPARS.ISI
                    keyp = check_keys();
                    if keyp == true
                        break
                    end
                end
                if keyp == true
                    break;
                end
                
            end
            DA.SetSysMode(1)
            set_attn(120.);
            disp 'Done'
            
        case 'map'
            fprintf(2, 'Map\n');
            [f] = seq_parse(remain);
            fl = f{1};
            al = f{2};
            fprintf(1, 'Map sequence: %s\n', remain);
%             Lmax = 10^(100./20.);
%             Attnmax = 100.;
            keyp = false;
            DA.SetSysMode(1); % put in standby mode first
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            show_sweepPeriod(DA, RZ5D);
            DA.SetSysMode(3); % enter mode to start data collection

            for i = 1:length(al)
                STPARS.attn = al(i);
                set_attn(STPARS.attn);
                STPARS.freq = 1000.*fl(i);
                fprintf(1, 'Freq: %9.1f  Attn: %6.1f\n', STPARS.freq, STPARS.attn);
                STIM.wave  = tonepip(STPARS.amp, STPARS.freq, ...
                    STPARS.delay, STPARS.duration, STPARS.rf, ...
                    STPARS.phase0, STPARS.sampfreq, ...
                    STPARS.ipi, STPARS.np, ...
                    STPARS.alternate);
                plot(STIM.wave);
                tstart = tic;
                loadNI(STIM, AO);
                present_stim(RP, DA, RZ5D, 3);
                while toc(tstart) < STPARS.ISI
                    keyp = check_keys();
                    if keyp == true
                        break;
                    end
                end
                if keyp == true
                    break;
                end
            end
            DA.SetSysMode(1);
            set_attn(120.);
            disp 'Done'

        case 'noise'  % noise rate-intensity
            %TFR added
            fprintf(2, 'Noise\n');
            a = seq_parse(remain);
            attnlist = a{1};
%             Lmax = 10^(100./20.);
%             Attnmax = 100.;
            fprintf(1, 'duration: %f\n', STPARS.duration);
% set cycle time in coresweep control PulseTrain2 element
            DA.SetSysMode(1); % put in standby mode first
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            show_sweepPeriod(DA, RZ5D);
            DA.SetSysMode(3); % enter mode to start data collection
            for i = 1:length(attnlist)
                STPARS.attn = attnlist(i);
                set_attn(STPARS.attn);
                %                sf = (10.^((Attnmax - STPARS.attn)/20.))/Lmax;
                STIM.wave = noise_gen(STPARS.duration, 'wideband', STPARS.sampfreq);
                tstart = tic;
                present_stim(RP, DA, RZ5D, 3);
                if i == length(attnlist)
                    break;
                end
                 while toc(tstart) < STPARS.ISI
                    keyp = check_keys();
                    if keyp == true
                        break
                    end
                end
                if keyp == true
                    break;
                end
            end
            DA.SetSysMode(1);
            set_attn(120.);
            disp 'Done'
            
        case 'sam'
            fprintf(2, 'SAM\n');
            [fmod, remain] = strtok(remain, ' ');
            [fc, remain] = strtok(remain, ' ');
            attns = seq_parse(remain);
            al = attns{1};
            fm = str2num(fmod);
            fl = str2num(fc);
            
            DA.SetSysMode(1); % put in standby mode first
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            show_sweepPeriod(DA, RZ5D);
            DA.SetSysMode(3); % enter mode to start data collection
            for i = 1:length(al)
                STPARS.attn = al(i);
                set_attn(STPARS.attn);
                STPARS.freq = 1000.*fl;
                fprintf(1, 'SAM: F = %9.1f Attn = %6.1f  fm = %5.1f\n',... 
                        STPARS.freq, STPARS.attn, fm);
                STIM.wave  = samStim(fm, STPARS.amp, STPARS.freq, ...
                    STPARS.delay, STPARS.duration, STPARS.rf, ...
                    STPARS.phase0, STPARS.sampfreq, ...
                    STPARS.ipi, STPARS.np, ...
                    STPARS.alternate);
                figure(78); plot(STIM.wave);
                tstart = tic;
                present_stim(RP, DA, RZ5D, 3);

                while toc(tstart) < STPARS.ISI
                    keyp = check_keys();
                    if keyp == true
                        break
                    end
                end
                if keyp == true
                    break;
                end
                
            end
            DA.SetSysMode(1);
            set_attn(120.);
            disp 'Done'
            
        case 'fsweep'  % frequency sweep: attn, freqseq. expect list of frequencies
            [attn, remain] = strtok(remain, ' ');
            STPARS.attn = str2num(attn);
            fsw = seq_parse(remain);
            swf = fsw{1};
            set_attn(STPARS.attn)
            DA.SetSysMode(1); % put in standby mode first
            DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
            show_sweepPeriod(DA, RZ5D);
            DA.SetSysMode(3); % enter mode to start data collection

            for i = 1:length(swf)
                STPARS.freq = swf(i);
                STIM.wave  = tonepip(STPARS.amp, STPARS.freq, ...
                    STPARS.delay, STPARS.duration, STPARS.rf, ...
                    STPARS.phase0, STPARS.sampfreq, ...
                    STPARS.ipi, STPARS.np, ...
                    STPARS.alternate);
                tstart = tic;
                present_stim(RP, DA, RZ5D, 3);
                while toc(tstart) < STPARS.ISI
                    keyp = check_keys();
                    if keyp == true
                        break
                    end
                end
                if keyp == true
                    break;
                end
            end
            DA.SetSysMode(1);
            set_attn(120.);
            disp 'Done'
            
        case 'nsweep'  % set number of sweeps
            STPARS.n_sweeps = str2double(remain);

        case 'delay'  % set stimulus delay
            STPARS.delay = str2double(remain);
        
        case {'dur', 'duration'}
            STPARS.duration = str2double(remain);
        
        case 'rise'
            STPARS.rf = str2double(remain);
        
        case 'phase0'
            STPARS.phase0 = str2double(remain);
        
        case 'ipi'
            STPARS.ipi = str2double(remain);
        
        case {'ISI', 'isi'}
            STPARS.ISI = str2double(remain);
        
        case 'np'
            STPARS.np = str2double(remain);
        
            
        case {'alt', 'alternate'}
            alt = strcmpi(remain, {'off', 'on'});
            if any(alt)
                fprintf(2, 'Alternation: options are on and off; got %s\n', remain);
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
    end
end

DA.SetSysMode(1); % then standby
DA.CloseConnection();
RP.Halt()
fprintf(1, 'StimController ... quitting\n');
return
end

function [finish] = check_keys()
finish = false;
k=get(gcf,'CurrentCharacter');
if k~='@' %has it changed from the dummy character?
    set(gcf,'CurrentCharacter','@');%reset the character
    %now process the key as required
    if k=='q',
        finish=true;
        return;
    end
end
end


function present_stim(RP, DA, RZ5D, mode)
% mode is 0 (idle), 1 (standby), 2 (preview) or 3 (record)
global STIM
global STPARS

loadRP2(RP, STIM);
% % set cycle time in coresweep control PulseTrain2 element
% DA.SetSysMode(1); % put in standby mode first
% DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
% show_sweepPeriod(DA, RZ5D);
% if mode == 0  % dont' allow idle, only standby
%     mode = 1;
% end
% DA.SetSysMode(mode); % enter mode to start data collection
end


function show_sweepPeriod(DA, RZ5D)
RZ5D.zSwPeriod = DA.GetTargetVal(RZ5D.Period);
fprintf(1, 'zSwPeriod  points (N): %d\n', RZ5D.zSwPeriod);
end

function  [RP, DA, RZ5D] = setup(samp_cof_flag)
global STIM
global STPARS

RP=actxcontrol('rpco.x', [5 5 26 26]);
if(invoke(RP, 'connectrp2', 'usb', 1) == 0)
    error('failed to connect to rp2');
end;
STIM.RP2COFFlag = samp_cof_flag;

if RP.ClearCOF() == 0
    error('failed to clear cof');
end;
% thisdir = pwd;
if (RP.LoadCOFsf(['C:\TDT\OpenEx\MyProjects\EPhys_RZ5D_PZ5-32\RCOCircuits\TriggeredWaveformPlayer_RP2.rcx'], ...
        STIM.RP2COFFlag) == 0)
    
    error ('failed to load TriggeredWaveformPlayer.rcx file');
end;
sfreq=RP.GetSFreq();
fprintf(1, 'RP2.1 : true sample frequency: %.6f hz\n', sfreq);
STIM.sample_freq = sfreq;
RP.Run();

status = double(RP.GetStatus());
if bitget(double(status), 1) == 0;
    fprintf(2, 'rp_setup: Error connecting to RP2.1\n');
%     err = 1;
    return;
elseif bitget(double(status), 2) == 0;
    fprintf(2, 'rp_setup: Error loading circuit to RP2.1\n');
%     err = 1;
    return;
elseif bitget(double(status), 3) ==0
    fprintf(2, 'Error running circuit in RP2.1\n');
%     err = 1;
    return;
else
    % disp('circuit loaded and running');
end
sfreq=RP.GetSFreq();
fprintf(1, 'RP2.1 : true sample frequency: %.6f hz\n', sfreq);

%-----------------------------------------------------------------------
fprintf(1, 'Connecting to RZ5D\n');
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');
RZ5D.device_Name = DA.GetDeviceName(0);
rco_file = DA.GetDeviceRCO(RZ5D.device_Name);
fprintf(1, 'Device RCO/X file: %s\n', rco_file);
RZ5D.device_Status = DA.GetDeviceStatus(RZ5D.device_Name);
fprintf(1, 'Device Status: %d\n', RZ5D.device_Status);

RZ5D.Period = 'ACQ_16ch.zSwPeriod';
RZ5D.Reset = 'ACQ_16ch.Reset';
RZ5D.Enable = 'ACQ_16ch.Enable';
RZ5D.SweepTrigger = 'ACQ_16Ch.SweepTrigger'; % set to 1 to start trigger, 0 to clear
RZ5D.Cnt = 'ACQ_16ch.zSwCount';
RZ5D.SWN = 'ACQ_16ch.SweepNum';
RZ5D.Done = 'ACQ_16ch.SweepDone';
RZ5D.dev_SF = DA.GetDeviceSF(RZ5D.device_Name); % get device sample frequency
fprintf(1, 'RZ5D Sample Frequency: %f\n', RZ5D.dev_SF);

DA.SetTargetVal(RZ5D.Period, STPARS.ISI*RZ5D.dev_SF);
DA.SetTargetVal(RZ5D.Cnt, 0);
RZ5D.zSwCount = DA.GetTargetVal(RZ5D.Cnt);
fprintf(1, 'zSwCount: %f\n', RZ5D.zSwCount);
DA.SetSysMode(1)


set_attn(120.);
% Now get the NI card set up.
%get_running_hardware();
%hardware_initialization();

return
end



% function getTags(dev, dn, type)
% tag =  dev.GetNextTag(dn, type, 1);
% if ~strcmp(tag, '')
%     fprintf(1, 'Type %2d: Tag = %s\n', type, tag);
% end
% while ~strcmp(tag,'' )
%     tag =  dev.GetNextTag(dn, type, 0);
%     if strcmp(tag,'' )
%         return
%     end
%     fprintf(1, '         Tag = %s\n', tag);
% end
% end

function loadNI(STIM, AO)

return
stop(AO);
delete(AO.channel);
a=get(AO);
if(isempty(a.Channel)) % only add if a channel does not already exist.
    addchannel(AO, 0);
end;
set(AO, 'samplerate', STIM.NIFreq); % STIM.nifreq is in samples per second.
set(AO, 'triggertype', 'HwDigital');
set(AO, 'HwDigitalTriggerSource', 'PFI0');
set(AO, 'TriggerCondition', 'NegativeEdge');
set(AO, 'bufferingmode', 'auto');
%set(AO, 'TriggerRepeat', 1);
%set(AO, 'bufferingconfig', [length(STIM.wave) STIM.StimPerSweep]);
set(AO, 'timeout', 5); % no stimuli will be more than 2 seconds long
set(AO, 'OutOfDataMode', 'DefaultValue');
set(AO.Channel, 'DefaultChannelValue', 0);
putdata(AO, STIM.wave);
start(AO); % get ni board read to go, then trigger the rp
end

function [err] = loadRP2(RP, STIM)
%trying this out
%loadNI(STIM, AO);
err = 0;
RP.SetTagVal('BufSize', floor(length(STIM.wave)));
% fprintf(1, 'Buffer size set to: %d\n', RP.GetTagVal('BufSize'));

if ~RP.WriteTagV('waveform', 0, STIM.wave')
    fprintf(2, 'loadRP2: Failed to set waveform\n');
    err = 1;
    return;
end;
%figure(2);
%plot(STIM.wave);

end





