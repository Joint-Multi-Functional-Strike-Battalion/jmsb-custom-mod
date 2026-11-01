#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_renderProduct

Description:
    Client end of every intel product. The server sends it to everyone by
    remoteExec (FUNC(sendProduct)) and
    the side filter is applied HERE, so an enemy client never draws the markers -
    and there is exactly one place that decides how intel looks.

    All drawing goes through the shared jmfsb_common renderers, so products can
    only differ in the snapshot they carry.

Parameters:
    _kind : STRING - "circle" or "icons".
    ...   : the payload for that kind, side last.

Author:
    JMSB
---------------------------------------------------------------------------- */
params ["_kind"];

// Taken only from the server (FUNC(sendProduct), by remoteExec): no client
// can draw false intel on his side's maps (review S7).
if (!hasInterface || {!([] call EFUNC(common,fromServer))}) exitWith {};

private _lifetime = [QGVAR(cfg_intel_lifetime)] call FUNC(hackSetting);
private _alpha = [QGVAR(cfg_intel_alpha)] call FUNC(hackSetting);
private _fade = [QGVAR(cfg_intel_fade)] call FUNC(hackSetting);

switch (_kind) do {
    case "circle": {
        _this params ["", "_id", "_pos", "_radius", "_colour", "_icon", "_label", "_side"];
        if (side group ACE_player isNotEqualTo _side) exitWith {};
        [_id, _pos, _radius, _colour, _alpha, _lifetime, _fade, _icon, _label] call EFUNC(common,renderIntelCircle);
    };
    case "icons": {
        _this params ["", "_id", "_rows", "_colour", "_side"];
        if (side group ACE_player isNotEqualTo _side) exitWith {};
        [_id, _rows, _colour, 1, _lifetime, _fade] call EFUNC(common,renderIntelIcons);
    };
};
