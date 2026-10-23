#include "script_component.hpp"
/*
 * Author: JMSB
 * The combat-support assets ALiVE is offering, as neutral rows for
 * TAC//SUPPORT. Read from the NEO radio registry ALiVE's own tablet reads -
 * NEO_radioLogic's per-side arrays, entries [veh, group, callsign, fsm] -
 * verified against the WORKSHOP sup_combatsupport.pbo the game actually
 * loads (the ALiVE.OS checkout is a newer dev tree and is not the authority).
 * The adapter is the only addon allowed to know these names.
 *
 * STATUS is ALiVE's own token, passed through lowercased so the app can say
 * what the unit is really doing. The FSMs write MISSION / RTB / SMOKE /
 * SMOKECONF / CARGO / MOVE / RESPONSE / NOAMMO, and "" / NONE when free -
 * only "MISSION" counted as busy before, so a helo inbound on a pickup read
 * as idle and the RTB button never armed mid-task.
 *
 * THE "alive" SUPPORT PROVIDER'S ROW LIST - registered with
 * EFUNC(support,registerProvider) in XEH_postInit; the support core merges it
 * with every other provider's. Ids are "alive:<type>:<index>" (NEO) and
 * "alive:ato" (the ATO), the prefix being the provider kind the core routes on.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Assets <ARRAY> of [id, type "cas"|"transport"|"arty", callsign, platform,
 * status "idle"|lowercased FSM token, ordnance [[type, rounds left], ...] -
 * arty only, [] for air, alive gun count - arty only, 0 for air, the airframe
 * <OBJECT> - air only, objNull for arty; a provider may leave it off]
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_supportAssets
 *
 * Public: No
 */

// THE ATO ROW. ALiVE's air tasking order takes CAS requests from the side
// that publishes it (GVAR(atoPub), see XEH_postInit); it is listed whether or
// not NEO combat support is running, because the two are separate modules.
private _side = side group player;
private _out = [];
if ((toUpper str _side) in (missionNamespace getVariable [QGVAR(atoPub), []])) then {
    _out pushBack [SUPPORT_ATO_ID, "cas", "ALiVE ATO", "CAS (experimental)", "idle", [], 0];
};

if (isNil "NEO_radioLogic") exitWith {_out};

{
    _x params ["_arrName", "_type", "_statusVar"];
    private _typeName = _type;
    private _statusName = _statusVar;

    {
        _x params [["_veh", objNull], "", ["_callsign", ""], ["_extra", []]];
        if (isNull _veh || {!alive _veh}) then {continue};

        // An ARTY entry is [LEADER, group, callsign, guns[], rounds, fsm] -
        // element 0 is the battery leader, a man, and the rounds ledger
        // lives on him. The platform name comes off the first gun; the
        // ledger gives the app only ordnance the battery actually carries.
        private _ordnance = [];
        private _guns = 0;
        private _platform = getText (configOf _veh >> "displayName");
        if (_typeName isEqualTo "arty") then {
            _ordnance = (_veh getVariable ["NEO_radioArtyBatteryRounds", []]) select {(_x param [1, 0]) >= 1};
            if (_extra isEqualType [] && {_extra isNotEqualTo []}) then {
                _platform = getText (configOf (_extra param [0, objNull]) >> "displayName");
                _guns = {alive _x} count _extra;
            };
        };

        private _raw = toUpper (_veh getVariable [_statusName, ""]);
        private _status = ["idle", toLower _raw] select (_raw isNotEqualTo "" && _raw isNotEqualTo "NONE");

        _out pushBack [
            format ["%1:%2:%3", SUPPORT_KIND, _typeName, _forEachIndex],
            _typeName,
            _callsign,
            _platform,
            _status,
            _ordnance,
            _guns,
            // The airframe itself, for the app's map marker and its
            // PASSENGERS list - an engine object, no ALiVE name crosses the
            // seam with it. A battery's element 0 is its leader, a man, so
            // artillery hands over nothing.
            [_veh, objNull] select (_typeName isEqualTo "arty")
        ];
    } forEach (NEO_radioLogic getVariable [format [_arrName, _side], []]);
} forEach [
    // ALiVE's own spelling of the transport array - "Trasport" - is theirs
    // to keep and ours to match.
    ["NEO_radioCasArray_%1", "cas", "NEO_radioCasUnitStatus"],
    // the FSM writes the status under the SAME missing-n spelling as the
    // array - reading the correctly-spelt name meant transport never read
    // "tasked" and the RTB button never armed
    ["NEO_radioTrasportArray_%1", "transport", "NEO_radioTrasportUnitStatus"],
    ["NEO_radioArtyArray_%1", "arty", "NEO_radioArtyUnitStatus"]
];

_out
