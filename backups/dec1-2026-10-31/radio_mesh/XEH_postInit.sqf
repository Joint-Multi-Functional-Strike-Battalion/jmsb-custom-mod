#include "script_component.hpp"

// Client only: ACRE evaluates the signal of every transmission on the machine
// that hears it, so the relay table and the signal function live on every
// client. The server routes nothing.
if (!hasInterface) exitWith {};

GVAR(hasACRE) = isClass (configFile >> "CfgPatches" >> "acre_main")
    && {!isNil "acre_api_fnc_setCustomSignalFunc"}
    && {!isNil "acre_sys_signal_fnc_getSignalCore"};

if (!GVAR(hasACRE)) exitWith {
    INFO_1("ACRE2 not loaded - %1 is inert",QUOTE(ADDON));
};

// The relay table, rebuilt on a slow cadence; the signal function reads it.
[LINKFUNC(refreshNodes), GVAR(refresh) max 1, []] call CBA_fnc_addPerFrameHandler;

// THE ONE CUSTOM SIGNAL FUNCTION ACRE ALLOWS. jmfsb_jamming used to register
// its own (vanilla signal scaled by the jam level); it stands down when this
// addon is loaded and fnc_signal applies the same jam level after routing.
[{ _this call FUNC(signal) }] call acre_api_fnc_setCustomSignalFunc;
INFO_2("ACRE mesh routing armed - relays %1, refresh %2s",GVAR(nodeRadios),GVAR(refresh));
