#include "script_component.hpp"
/*
 * Author: JMSB
 * Draws the tracked members on the map: a circle in his fire team's colour
 * with a pointer that turns with his heading, his member number inside it,
 * a dark outline under it, his name beside it, and a ring round it while he
 * is talking (docs/DESIGN_BFT_MEMBERS.md). Runs on the map control's Draw
 * event every frame - the map, the tablet and the phone all hang it - off the
 * member list and voice table FUNC(draw) rebuilds on its own tick; this file
 * decides nothing about WHO, only how they look.
 *
 * THE NUMBER NEVER ROTATES. It is its own drawIcon with a transparent
 * texture and centred text, so the circle can turn under it. It is drawn
 * smaller than the name (MEMBER_NUMBER_TEXT_SIZE) so it sits inside the circle.
 *
 * WHERE HIS GPS SAYS (jmfsb_ew_fnc_gpsOf, when EW is loaded). A tracker is a
 * GPS product: a spoofed man - you included - is drawn at the false fix, a
 * man whose GPS is denied is not drawn at all, and your own dot says GPS
 * SUSPECT while an anti-spoof set flags it.
 *
 * Arguments (Draw event):
 * 0: The map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_bft_fnc_drawMembers}]
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]]];

if (!GVAR(enabled) || GVAR(memberMarkers) isEqualTo 0) exitWith {};
private _members = GVAR(memberUnits);
if (isNil "_members" || {_members isEqualTo []}) exitWith {};

// The ACE3 / vanilla team colours, and whether the number on them is dark.
private _teams = createHashMapFromArray [
    ["MAIN", [[1, 1, 1, 1], true]],
    ["RED", [[0.90, 0.22, 0.21, 1], false]],
    ["GREEN", [[0.26, 0.63, 0.28, 1], false]],
    ["BLUE", [[0.12, 0.53, 0.90, 1], false]],
    ["YELLOW", [[0.99, 0.85, 0.21, 1], true]]
];
private _voice = missionNamespace getVariable [QGVAR(memberVoice), createHashMap];
private _ew = !isNil QEFUNC(ew,gpsOf);

{
    if (isNull _x || {!alive _x}) then {continue};

    private _pos = getPosATLVisual _x;
    private _flag = "";
    if (_ew) then {
        ([_x] call EFUNC(ew,gpsOf)) params ["_state", "_offset"];
        _pos = [[], _pos vectorAdd [_offset select 0, _offset select 1, 0]] select (_state isNotEqualTo GPS_STATE_NOFIX);
        if (_state isEqualTo GPS_STATE_SUSPECT && _x isEqualTo ACE_player) then {_flag = GPS_SUSPECT_TAG};
    };
    if (_pos isEqualTo []) then {continue};
    private _dir = getDirVisual _x;
    (_teams getOrDefault [assignedTeam _x, _teams get "MAIN"]) params ["_fill", "_darkText"];

    // Down, not out: an unconscious man is drawn at half strength.
    private _alpha = [1, MEMBER_DOWN_ALPHA] select (lifeState _x isEqualTo "INCAPACITATED");
    _fill = (_fill select [0, 3]) + [_alpha];

    // 1. the voice ring - red on a radio net, magenta in direct voice
    private _talking = (_voice getOrDefault [hashValue _x, [objNull, VOICE_NONE]]) select 1;
    if (GVAR(memberVoiceRings) && _talking > VOICE_NONE) then {
        _map drawIcon [MEMBER_RING, [RING_DIRECT, RING_RADIO] select (_talking isEqualTo VOICE_RADIO), _pos, MEMBER_SIZE, MEMBER_SIZE, 0, "", 0];
    };

    // 2. the outline, 3. the body - both turn with him
    _map drawIcon [MEMBER_OUTLINE, MEMBER_OUTLINE_RGBA, _pos, MEMBER_SIZE, MEMBER_SIZE, _dir, "", 0];

    // The name rides on the body, beside the circle - the name only, no
    // skills after it (user, 2026-10-22: "on the map remove the skill and
    // trait").
    private _label = name _x + _flag;
    _map drawIcon [MEMBER_BODY, _fill, _pos, MEMBER_SIZE, MEMBER_SIZE, _dir, _label, 1, MEMBER_TEXT_SIZE, "RobotoCondensed", "left"];

    // 4. the number, upright, in the middle of the circle
    _map drawIcon [
        MEMBER_BLANK,
        [[1, 1, 1, _alpha], [0.13, 0.12, 0.11, _alpha]] select _darkText,
        _pos, 0, 0, 0,
        str ([_x] call FUNC(memberNumber)),
        0, MEMBER_NUMBER_TEXT_SIZE, "RobotoCondensedBold", "center"
    ];
} forEach _members;
