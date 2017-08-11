% Hardware interaction routines

% set_attn controls the PA5 Programmable attenuator

%
%----------------------------------------------------------------------------
%****************************************************************************
%----------------------------------------------------------------------------
function set_attn(attn)
global PA5
if((attn > 120.0) || (attn < 0.0)) % out of range : set to maximum attenuation
    attn = 120.0;
end;

if(isempty(PA5) || ~ishandle(PA5))
    fprintf(2, 'Attempting to connect to PA5 Attenuators: ');
    PA5=actxcontrol('PA5.x', [1 1 1 1]);
    if(PA5.ConnectPA5('USB', 1) == 0)
        fprintf(2, ' ... failed to connect to PA5\n');
        return;
    end;
    fprintf(2, 'PA5 Connection OK\n');
end;
fprintf(2, 'Must be connected to a PA5 already\n')
PA5.SetAtten(attn);
return;