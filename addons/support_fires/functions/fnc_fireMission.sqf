#include "script_component.hpp"
/*
 * Author: JMSB
 * A fire mission for a battery, on the server - Simplex's fire mission with
 * virtual rounds. The order is checked once more (the round still carried,
 * the target still in range), the wait before the first round is drawn (the
 * module's random response time plus the DELAY asked for), and the battery's
 * part is scheduled (FUNC(fireVirtual)).
 *
 * COORDINATED. When the request asked for it, every battery that can join
 * (FUNC(partners)) opens its own mission on the same target with the same
 * round, rounds, sheaf, delay, interval and repeat, and all of its guns. Each
 * calls its own SHOT and SPLASH and cools down on its own; a CHECK FIRE on the
 * tasked battery stops them all (FUNC(abort)).
 *
 * The target is marked on the map for the side until the mission ends
 * (FUNC(mark)), and the requester gets one acknowledgement with what will
 * happen and when.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: [kind, rounds per gun, sheaf (m), guns (0 all), name, sheaf type, delay, interval, repeat, coordinate] <ARRAY>
 * 3: Requester <OBJECT>
 * 4: Mission token <NUMBER>
 * 5: Asset id <STRING>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, ["he", 2, 50, 0, "HE", 0, 0, 0, 0, 0], player, 1, "fires:1"] call jmfsb_support_fires_fnc_fireMission
 *
 * Public: No
 */

params ["_logic", "_target", "_opts", "_requester", "_token", "_assetId"];
_opts params [
    ["_kind", "", [""]], "", ["_sheaf", 0, [0]], "", ["_name", "", [""]],
    ["_sheafType", SHEAF_CONVERGED, [0]], ["_delay", 0, [0]], "", "", ["_coordinate", 0, [0]]
];

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
// A refusal here changes nothing on the asset: its new token simply has no
// mission behind it.
private _refuse = {
    params ["_why"];
    [_assetId, false, format ["%1: %2", _callsign, _why], _requester] call EFUNC(support,ack);
};

private _stock = _logic getVariable [QGVAR(stock), []];
private _index = _stock findIf {(_x select 3) isEqualTo _kind};
(if (_index < 0) then {[]} else {_stock select _index}) params [["_label", _name], ["_left", 0], ["_cls", ""]];
if (_left isEqualTo 0 || _cls isEqualTo "") exitWith {[format ["no %1 left", _name]] call _refuse};

private _range = [_logic, _target] call FUNC(inRange);
if (_range isNotEqualTo "") exitWith {[_range] call _refuse};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0], ["_respMax", 0]];
private _wait = _respMin + random (_respMax - _respMin) + (0 max _delay);

private _plan = [_logic, _target, _opts, _token, _wait] call FUNC(fireVirtual);
if (_plan isEqualTo []) exitWith {["cannot fire that mission"] call _refuse};
_plan params ["_shots", "_guns", "_eta", "_volleys"];

// THE BATTERIES THAT JOIN, each on its own mission with its own entry for the
// same shell class and every one of its guns.
private _joined = [];
if (_coordinate > 0) then {
    {
        private _partner = _x;
        private _pStock = _partner getVariable [QGVAR(stock), []];
        private _pIndex = _pStock findIf {(_x select 2) == _cls};
        private _pKind = (if (_pIndex < 0) then {[]} else {_pStock select _pIndex}) param [3, ""];
        private _pToken = [_partner] call FUNC(openMission);
        private _pOpts = +_opts;
        _pOpts set [0, _pKind];
        _pOpts set [3, 0];
        _pOpts set [9, 0];
        private _pPlan = [_partner, _target, _pOpts, _pToken, _wait] call FUNC(fireVirtual);
        if (_pPlan isNotEqualTo []) then {
            _joined pushBack [_partner, _pToken];
            _shots = _shots + (_pPlan select 0);
            _eta = _eta max (_pPlan select 2);
        };
    } forEach ([_logic, _cls, _target] call FUNC(partners));
};
_logic setVariable [QGVAR(partners), _joined];

[_logic, _target, format ["%1 - %2 %3", _callsign, _label, SHEAF_WORDS param [_sheafType, ""]], _sheaf] call FUNC(mark);

if (_wait >= 1) then {
    [QGVAR(say), [_logic, format ["fire mission received - shot in %1 sec", round _wait], "normal"]] call CBA_fnc_globalEvent;
};

private _with = _joined apply {(_x select 0) getVariable [QGVAR(callsign), "FIRES"]};
[_assetId, true, format [
    "%1 - %2 rounds %3, %4 %5 m, %6 guns%7%8. Shot in %9 sec, time of flight %10 sec",
    _callsign, _shots, _label, SHEAF_WORDS param [_sheafType, ""], round _sheaf, _guns,
    ["", format [", %1 volleys", _volleys]] select (_volleys > 1),
    ["", format [", with %1", _with joinString ", "]] select (_with isNotEqualTo []),
    round _wait, round _eta
], _requester] call EFUNC(support,ack);
