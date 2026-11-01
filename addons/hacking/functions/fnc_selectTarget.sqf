#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_selectTarget

Description:
    Puts one object on the HACK board as the selected device, without a card
    slot - the way in for an ACE action on the thing itself (the jamming
    addon's HACK on a jammer terminal, user 2026-10-24: "the jammers need to
    have a local ace interface to disable or hack"). The same session fields
    FUNC(tabletSelectDevice) sets from a card; the range is left to the hack
    range setting (FUNC(tabletInRange)).

    Refuses while a hack is running, as the card pick does: swapping the
    target mid-intrusion would throw the progress away.

Parameters:
    _obj  : OBJECT - the device.
    _kind : STRING - "tower" | "drone" | "wreck" | "unit". Optional, "tower".

Returns:
    BOOL - selected.

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_obj", objNull, [objNull]], ["_kind", "tower", [""]]];

if (isNull _obj) exitWith { false };
if (isNil QGVAR(session)) exitWith { false };
if (GVAR(session) get "running") exitWith { false };

GVAR(session) set ["device", _obj];
GVAR(session) set ["kind", _kind];
GVAR(session) set ["action", HACK_ACTION_DEFAULT];
GVAR(session) set ["range", 0];
GVAR(session) set ["progress", _obj getVariable [QGVAR(progress), 0]];

true
