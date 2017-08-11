% Uses TDEVAcc methods. Somewhat limited, but sufficient to set up triggers
%
function []=StimController(varargin)

global AO
global SPLCAL HARDWARE STIM
% designate the sample frequency
% 0 = 6K, 1 = 12K, 2 = 25k, 3 = 50k, 4 = 100k, 5 = 200k, > 5 is not defined.
samp_cof_flag = 5; % 4 is for 100 kHz
samp_flist = [6103.5256125, 122107.03125, 24414.0625, 48828.125, ...
    97656.25, 195312.5];
if(samp_cof_flag > 5)
    samp_cof_flag = 5;
end;
RP=actxcontrol('rpco.x', [5 5 26 26]);
if(invoke(RP, 'connectrp2', 'usb', 1) == 0)
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
sfreq=RP.GetSFreq();
fprintf(1, 'RP2.1 : true sample frequency: %.6f hz\n', sfreq);
STIM.sample_freq = sfreq;
RP.Run();

status = double(RP.GetStatus());
if bitget(double(status), 1) == 0;
    fprintf(2, 'rp_setup: Error connecting to RP2.1\n');
    err = 1;
    return;
elseif bitget(double(status), 2) == 0;
    fprintf(2, 'rp_setup: Error loading circuit to RP2.1\n');
    err = 1;
    return;
elseif bitget(double(status), 3) ==0
    fprintf(2, 'Error running circuit in RP2.1\n');
    err = 1;
    return;
else
    % disp('circuit loaded and running');
end
sfreq=RP.GetSFreq();
fprintf(1, 'RP2.1 : true sample frequency: %.6f hz\n', sfreq);


DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');
device_Name = DA.GetDeviceName(0);
rco_file = DA.GetDeviceRCO(device_Name);
fprintf(1, 'Device RCO/X file: %s\n', rco_file);
device_Status = DA.GetDeviceStatus(device_Name);
fprintf(1, 'Device Status: %d\n', device_Status);
% getTags(DA, device_Name, 68);
% getTags(DA, device_Name, 73);
% getTags(DA, device_Name, 76);
% getTags(DA, device_Name, 80);
% getTags(DA, device_Name, 83);
% getTags(DA, device_Name, 65);
tag_Pd = 'ACQ_16ch.zSwPeriod';
tag_Cnt = 'ACQ_16ch.zSwCount';
tag_SWN = 'ACQ_16ch.SweepNum';
tag_Done = 'ACQ_16ch.SweepDone';
dev_SF = DA.GetDeviceSF(device_Name); % get device sample frequency
zSwPeriod = DA.GetTargetVal(tag_Pd);
fprintf(1, 'zSwPeriod (s): %f\n', zSwPeriod/dev_SF);
zSwCount = DA.GetTargetVal(tag_Cnt);
fprintf(1, 'zSwCount: %f\n', zSwCount);
DA.SetTargetVal(tag_Pd, 1*dev_SF);
zSwPeriod = DA.GetTargetVal(tag_Pd);
fprintf(1, 'reset zSwPeriod (s): %f\n', zSwPeriod/dev_SF);
DA.SetTargetVal(tag_Cnt, 10);

set_attn(120.);
% Now get the NI card set up.
get_running_hardware();
hardware_initialization();
STIM
n_sweeps = 1;
amp = 5.;
freq = 1000.;
delay = 0.01;
duration = 200.;
rf=2.5;
phase0 = 0.;
sampfreq = STIM.sample_freq;
ipi = 0.1;
np = 1;
alternate = 0;
%STIM.wave = noise_gen(duration, 'wideband',sampfreq);
STIM.wave  = tonepip(amp, freq, delay, duration, rf, phase0,...
    sampfreq, ipi, np, alternate);
%loadNI();

set_attn(30.);
pause (0.25);
loadRP2(RP, STIM)
sfreq=RP.GetSFreq();
fprintf(1, 'RP2.1 : true sample frequency: %.6f hz\n', sfreq);

DA.SetSysMode(2); % preview mode
zSWN = DA.GetTargetVal(tag_SWN);
fprintf(1, 'zSwCount: %d\n', zSWN);

pause(1)
while ~DA.GetTargetVal(tag_Done)
%    zSWN = DA.GetTargetVal(tag_SWN);
    fprintf(2, 'mode: %d\n', DA.GetSysMode());
    if DA.GetTargetVal(tag_Done) || DA.GetSysMode() == 0
        DA.SetSysMode(1); % Standby first
        disp 'idle in while loop'
        break;
    end
    pause(1)
end
zSWN = DA.GetTargetVal(tag_SWN);
fprintf(2, 'Final Sweep Count: %d\n', zSWN);
fprintf(2, 'Triggers Executed: %d\n ', AO.TriggersExecuted);
fprintf(1, 'Buffer size loaded: %d\n', RP.GetTagVal('BufSize'));
fprintf(1, 'Buffer Position: %d\n', RP.GetTagVal('BufPos'));

disp 'end while loop'
set_attn(120.);
DA.SetSysMode(0); % then Idle
pause(2)
DA.CloseConnection();
RP.Halt()


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

function loadNI()
global STIM AO
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

function loadRP2(RP, STIM)

RP.SetTagVal('BufSize', floor(length(STIM.wave)));
RP.WriteTagV('waveform',0,STIM.wave');
if RP.WriteTagV('dataIn', 0, STIM.wave')
   fprintf(2, 'loadRP2: Failed to set waveform\n');
   err = 1;
   return;
end;
fprintf(1, 'dataIn: %d\n', RP.GetTagVal('waveform'));
figure(2);
plot(STIM.wave);


% RP.SoftTrg(1);
fprintf(1, 'Buffer size intended: %d\n', length(STIM.wave));
fprintf(1, 'Buffer size loaded: %d\n', RP.GetTagVal('BufSize'));
end





