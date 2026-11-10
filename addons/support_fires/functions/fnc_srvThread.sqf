#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a CALL FOR FIRE filed to a battery's box - the "thread" code this
 * addon hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING step 6;
 * user: "per the doc i want to use the messaging system to call ai support").
 * The core has asked the issuer's tasking gate and his side already; this
 * finds the battery by its id (a dedicated server has no `player` for
 * FUNC(assets)) and asks its own questions again. A cruise missile or
 * loitering munition launcher's card is FUNC(threadStrike)'s (2026-11-01).
 *
 * THE CARD, field by field (EFUNC(support,readOrder), kind "fire"):
 *   Warno 1        ADJUST - one adjusting round, the battery holds for the
 *                  observer; FIRE FOR EFFECT, SUPPRESS - the whole order, then
 *                  it holds; IMMEDIATE SUPPRESSION - the whole order at the
 *                  battery's quickest. None ticked: ADJUST
 *   Warno 2        the first number in it is how many guns, else all
 *   the target     the point the reader worked out from any of the three
 *                  calls for fire (user, 2026-11-02): CFF GRID's grid, CFF
 *                  POLAR's direction and distance from the observer, CFF
 *                  SHIFT's shift from its known point - all answered alike.
 *                  None: CANTCO "NO TARGET LOCATION"
 *   Engagement     the shell, when carried - else CANTCO "NO STORES <shell>";
 *                  none ticked, the battery's first. Its number is rounds per
 *                  gun, up to the module's Max Rounds Per Gun
 *   Danger Close   the card's own threshold (`dangerClose`, 600 m) - CANTCO
 *                  "DANGER CLOSE NOT ACKNOWLEDGED" without the tick
 *   Shape, End     TARGET SHAPE (user, 2026-11-02; FUNC(threadShape)): POINT
 *                  (none), AREA (the size its radius), LINEAR (to the far end,
 *                  or the size at the attitude), CREEPING (a walk to the far
 *                  end, or the size along the attitude) - the module's Sheaf
 *                  Types allow each, else CANTCO "SHEAF NOT AVAILABLE"; the
 *                  ends are checked for range and danger close too
 *   Method         METHOD OF FIRE (user, 2026-11-02; FUNC(threadMethod)):
 *                  INTERVAL n S, n VOLLEYS, or CONTINUOUS FOR n MIN, within
 *                  Max Interval / Max Repeats / Max Continuous Fire
 *   Control        AT MY COMMAND - laid, WILCO, then it waits for CONFIRM
 *                  (FUNC(threadReply)); TIME ON TARGET - the first round lands
 *                  at the TOT line's time (HHMM, HHMMSS or +M minutes from
 *                  now, game time), else CANTCO "NO TOT" / "CANNOT MAKE TOT";
 *                  CANNOT OBSERVE - an adjust is fired for effect; anything
 *                  else - fire when ready
 * Busy, rearming, spent, out of range: the reach card's words (FUNC(reach)) -
 * TASKED, COOLDOWN n S, NO STORES, OUT OF RANGE n/max KM, TOO CLOSE n/min KM.
 *
 * ACCEPTED: WILCO "ETA m:ss - <mission> - <rounds> - <method> - <shape> - TOF n S - <target>" in the
 * thread, and the battery fires (FUNC(threadFire)) - or, AT MY COMMAND, asks
 * for it (FUNC(threadPrompt)). Said here, at the filing, inside the core's
 * receipt hold: the battery's first answer is the one "ROGER, WILCO - ETA ..."
 * (EFUNC(support,srvReply)), as every asset's is. A REQUEST ON STATION is
 * CANTCO "NOT AN AIR ASSET" (user, 2026-11-02). The rest is FUNC(threadVolley) (SHOT, SPLASH,
 * the prompts) and FUNC(threadReply) (the observer's calls).
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fire <ARRAY>
 *
 * Example:
 * ["fires:0", _thread, _message, _issuer] call jmfsb_support_fires_fnc_srvThread
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]]
];

if (!isServer) exitWith {[]};
// The support core's own call, from its messaging hook - never a client's.
if (isRemoteExecuted) exitWith {
    WARNING_1("srvThread: refused - remote call from machine %1",remoteExecutedOwner);
    []
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, WHY_LOST]};

// A REQUEST ON STATION IS NOT A FIRE MISSION (user, 2026-11-02: "on station is
// not a fire mission its just an order to get in the air"): no gun or launcher
// takes it - CANTCO, never read as a call for fire.
private _order = [_thread, _message] call EFUNC(support,readOrder);
private _kind = _order getOrDefault ["kind", ""];
if (_kind isEqualTo ORDER_STATION) exitWith {[false, WHY_NOT_AIR]};

// A cruise missile or loitering munition launcher (2026-11-01): one launch.
private _type = _logic getVariable [QGVAR(type), ""];
if (_type in [TYPE_CRUISE, TYPE_LOITER]) exitWith {[_assetId, _thread, _message, _issuer] call FUNC(threadStrike)};
if (_type isNotEqualTo TYPE_ARTY) exitWith {[]};

if (_kind isNotEqualTo ORDER_FIRE) exitWith {[]};

private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {[false, WHY_NO_TARGET]};

// BUSY, REARMING, SPENT, OUT OF RANGE - the reach card's words.
([_assetId, _target] call FUNC(reach)) params ["_can", "", "_why"];
if (!_can) exitWith {[false, _why]};

// THE SHELL: the card's when the battery carries it, else its first.
private _ordnance = [_logic] call FUNC(ordnance);
if (_ordnance isEqualTo []) exitWith {[false, WHY_NO_STORES]};
private _shell = _order getOrDefault ["shell", ""];
private _ordIndex = 0;
if (_shell isNotEqualTo "") then {
    private _kindAt = SHELL_KINDS findIf {(_x select 0) isEqualTo _shell};
    private _kind = "";
    if (_kindAt >= 0) then {_kind = (SHELL_KINDS select _kindAt) select 1};
    _ordIndex = _ordnance findIf {(_x select 2) isEqualTo _kind};
};
if (_ordIndex < 0) exitWith {[false, format [WHY_NO_STORES_OF, _shell]]};

// THE GUNS the card asks for, of the battery's.
private _gunCount = _logic getVariable [QGVAR(gunCount), 1];
private _gunsWanted = _order getOrDefault ["guns", 0];
private _guns = [_gunCount, _gunsWanted min _gunCount] select (_gunsWanted > 0);

// TARGET SHAPE (user, 2026-11-02): the sheaf the card's Shape line asks for,
// and the point the mission is aimed at - a line given by its ends is aimed
// at its middle.
([_logic, _order, _guns] call FUNC(threadShape)) params ["_shapeWhy", ["_aim", []], ["_sheafType", SHEAF_CONVERGED], ["_sheaf", 0], ["_attitude", -1], ["_length", 0], ["_shapeWords", ""], ["_points", []]];
if (_shapeWhy isNotEqualTo "") exitWith {[false, _shapeWhy]};

// DANGER CLOSE (doc 5.3, D5): the card's own threshold - at every point of
// the shape, each one also in range.
private _side = _logic getVariable [QGVAR(side), west];
private _pointWhy = "";
{
    private _range = [_logic, _x] call FUNC(inRange);
    if (_range isNotEqualTo "") exitWith {_pointWhy = toUpper _range};
    private _check = +_order;
    _check set ["target", _x];
    ([_check, _side] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy"];
    if (!_safe) exitWith {_pointWhy = _unsafeWhy};
} forEach _points;
if (_pointWhy isNotEqualTo "") exitWith {[false, _pointWhy]};
// CFF SHIFT's UP / DOWN: the guns are laid for the known point's height plus
// it; a target at another height is missed long or short (FUNC(layHeight)).
([_logic, _order, _aim] call FUNC(layHeight)) params ["_landing", "_miss"];
if (_miss isNotEqualTo 0) then {
    private _missWord = ["short", "long"] select (_miss > 0);
    INFO_3("%1 laid for the known point's height: lands %2 m %3",_assetId,round abs _miss,_missWord);
};
_target = _landing;

// METHOD OF FIRE (user, 2026-11-02): interval, volleys, continuous fire.
([_logic, _order] call FUNC(threadMethod)) params ["_methodWhy", ["_interval", 0], ["_repeat", 0], ["_continuous", -1], ["_methodWords", []]];
if (_methodWhy isNotEqualTo "") exitWith {[false, _methodWhy]};

// THE MISSION. An observer who cannot see the rounds cannot adjust them.
private _control = _order getOrDefault ["control", ""];
private _mission = _order getOrDefault ["mission", ""];
if (_mission isEqualTo "") then {_mission = MISSION_ADJUST};
if (_control isEqualTo CONTROL_CANNOT && _mission isEqualTo MISSION_ADJUST) then {_mission = MISSION_FFE};
private _call = [ADJ_FFE, ADJ_ROUND] select (_mission isEqualTo MISSION_ADJUST);

// THE ORDER as the board's parameter array, read the board's way
// (FUNC(readOpts)): the round, rounds per gun and guns from the card; the
// sheaf, interval and repeats the shape and the method ask for (2026-11-02),
// held to the module's limits as the board's steppers are; no delay, alone.
private _prm = [];
_prm resize (SLOT_ADJUST + 1);
_prm set [SLOT_ORD, _ordIndex];
private _rounds = _order getOrDefault ["rounds", -1];
if (_rounds > 0) then {_prm set [SLOT_ROUNDS, _rounds]};
_prm set [SLOT_GUNS, _gunsWanted];
_prm set [SLOT_ADJUST, _call];
_prm set [SLOT_SHEAF, round _sheaf];
_prm set [SLOT_SHEAF_TYPE, [_sheafType, SHEAF_PARALLEL] select (_sheafType isEqualTo SHEAF_LINEAR)];
_prm set [SLOT_INTERVAL, _interval];
_prm set [SLOT_REPEAT, _repeat];
private _opts = [_logic, _prm] call FUNC(readOpts);
if (_opts isEqualTo []) exitWith {[false, WHY_NO_STORES]};
// Past what a stepper can ask: the linear sheaf, the attitude and length of
// a line or a walk, and a continuous fire's rounds per gun.
_opts set [OPT_SHEAF, _sheaf];
_opts set [OPT_SHEAF_TYPE, _sheafType];
_opts set [OPT_ATTITUDE, _attitude];
_opts set [OPT_LENGTH, _length];
if (_continuous > 0) then {_opts set [OPT_ROUNDS, _continuous]};
// AIRBURST (user, 2026-11-02, from the Tun Firesupport review): HE with the
// airburst fuze - FUNC(virtualRound) bursts it over the ground.
private _airburst = _shell isEqualTo SHELL_AIRBURST;
_opts set [OPT_FUZE, ["", FUZE_AIRBURST] select _airburst];

// THE TIME: the arc's time of flight, and the wait before the first round.
private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _ball = [_origin distance2D _target, _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV], _logic getVariable [QGVAR(highAngle), true], RISE(_origin,_target)] call FUNC(ballistics);
private _tof = (_ball param [1, 0]) max VA_DESCENT_TIME;
(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0], ["_respMax", 0]];
private _wait = _respMin + random (_respMax - _respMin);
if (_mission isEqualTo MISSION_IMMEDIATE || _control isEqualTo CONTROL_COMMAND) then {_wait = _respMin};

// TIME ON TARGET: the first round lands at the TOT line's time of day
// (FUNC(threadTot), shared with the cruise missile launcher since 2026-11-01).
private _when = [_wait + _tof] call EFUNC(support,etaText);
private _totWhy = "";
if (_control isEqualTo CONTROL_TOT) then {
    ([_order getOrDefault ["tot", ""], _tof, _respMin] call FUNC(threadTot)) params ["_totWait", "_totWhen", "_why"];
    _totWhy = _why;
    _wait = _totWait;
    _when = _totWhen;
};
if (_totWhy isNotEqualTo "") exitWith {[false, _totWhy]};
if (_control isEqualTo CONTROL_COMMAND) then {_when = WHEN_COMMAND};

// WILCO's words: when, what, the rounds, the method and the shape
// (2026-11-02: "4 GUNS x 3 HE - INTERVAL 20 S - 3 VOLLEYS"), the time of
// flight, the target.
(_ordnance select _ordIndex) params ["_roundName"];
if (_airburst) then {_roundName = format [WORDS_AIRBURST, _roundName]};
_opts params ["", "_perGun"];
private _what = (MISSION_WORDS select {(_x select 0) isEqualTo _mission}) param [0, ["", ""]];
private _load = format ["%1 GUNS x %2 %3", _guns, _perGun, _roundName];
if (_call isEqualTo ADJ_ROUND) then {_load = format ["1 RD %1", _roundName]};
private _words = [_when, _what select 1, _load] + _methodWords + [_shapeWords, format ["TOF %1 S", round _tof]];
if (_order getOrDefault ["dcTick", false]) then {_words pushBack WORD_DANGER_CLOSE};
private _desc = _order getOrDefault ["description", ""];
if (_desc isNotEqualTo "") then {_words pushBack (toUpper (_desc select [0, DESCRIPTION_MAX]))};
private _wilco = (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP;

// LAID: the battery's mission, its thread and the order it fires.
private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
[_logic] call FUNC(openMission);
_logic setVariable [QGVAR(thread), _threadId];
_logic setVariable [QGVAR(threadOrder), createHashMapFromArray [
    ["target", _target],
    ["opts", _opts],
    ["call", _call],
    ["wait", _wait],
    ["observer", _order getOrDefault ["observer", objNull]],
    ["observerPos", _order getOrDefault ["observerPos", []]],
    ["observed", _control isNotEqualTo CONTROL_CANNOT],
    ["dcTick", _order getOrDefault ["dcTick", false]],
    ["dangerClose", _order getOrDefault ["dangerClose", 0]],
    ["issuer", _issuer],
    // RECORD AS TARGET (2026-11-02): [name, point] once recorded.
    ["recorded", []]
]];
// A new mission asks nothing yet (FUNC(threadPrompt)'s last question).
_logic setVariable [QGVAR(promptAsked), []];
_logic setVariable [QGVAR(status), STATUS_LAID, true];
INFO_4("%1 call for fire %2 on %3 for %4",_callsign,_mission,mapGridPosition _target,name _issuer);

[_assetId, "ACCEPTED", _wilco, _callsign, false, _threadId] call EFUNC(support,state);

if (_control isEqualTo CONTROL_COMMAND) exitWith {
    [_logic, PROMPT_COMMAND, ANSWERS_COMMAND] call FUNC(threadPrompt);
    [true, ""]
};
[_logic, _call, _issuer] call FUNC(threadFire);
[true, ""]
