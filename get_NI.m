function [AO] = get_NI(externalTrigger)
%% get the NI device and create and analog output channel
%%

devices = daq.getDevices();
AO = daq.createSession('ni');
devchk = addAnalogOutputChannel(AO,'Dev1', 0, 'Voltage');
if externalTrigger  == 1
    addTriggerConnection(AO, 'External', 'Dev1/PFI0', 'StartTrigger');
    AO.Connections(1).TriggerCondition = 'RisingEdge';
end
return

     