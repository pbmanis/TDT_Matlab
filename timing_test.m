% Testing timing from CoreSweepControl.

function []=timing_test(varargin)

fprintf(2, 'timing_test.m [using RZ5D]\n');

ISI = 3.0;
[DA, RZ5D] = setup();  % setup hardware all devices
for i = 1:3
    % would set up stimuli here - skipping for test purposes
    load_timing(DA, RZ5D, ISI, 2); % Set up the requested timing
    tstart = tic;  % wait for finish... 
    while toc(tstart) < ISI
    end;
    % show_sweepCount(DA, RZ5D);
end

DA.SetSysMode(1); % then leave it in standby.
DA.CloseConnection();
return
end

function load_timing(DA, RZ5D, ISI, mode)
% mode is 0 (idle), 1 (standby), 2 (preview) or 3 (record)
% set cycle time in coresweep control PulseTrain2 element

DA.SetSysMode(1); % put in standby mode first
DA.SetTargetVal(RZ5D.Period, ISI*RZ5D.dev_SF);
show_sweepPeriod(DA, RZ5D);
DA.SetSysMode(mode); % enter mode to start data collection
end


function show_sweepPeriod(DA, RZ5D)

RZ5D.zSwPeriod = DA.GetTargetVal(RZ5D.Period);
fprintf(1, 'zSwPeriod  points (N): %d\n', RZ5D.zSwPeriod);
end

function show_sweepCount(DA, RZ5D)
RZ5D.zSwCount = DA.GetTargetVal(RZ5D.Cnt);
fprintf(1, 'Sweep Count: %f\n', RZ5D.SweepNum);
end

function  [DA, RZ5D] = setup(samp_cof_flag)

fprintf(1, 'Connectinog to RZ5D\n');
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');
DA.SetSysMode(1); % make sure is in standby mode first
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
DA.SetTargetVal(RZ5D.Cnt, 0);
RZ5D.SweepNum = 'ACQ_16ch.zSwNum';
RZ5D.Done = 'ACQ_16ch.SweepDone';
RZ5D.dev_SF = DA.GetDeviceSF(RZ5D.device_Name); % get device sample frequency
fprintf(1, 'RZ5D Sample Frequency: %f\n', RZ5D.dev_SF);


return
end
