#include "script_component.hpp"
/*
 * Author: JMSB
 * The squad list's lines, one per living member of the player's group in
 * the group's own order: "<N> <NAME>", the number in his fire team's colour
 * (the number jmfsb_bft_fnc_memberNumber gives him everywhere), then his
 * flags.
 *
 * FLAGS (docs/DESIGN_PHONE_WALKING.md, "Map overlays"):
 * - TX red: talking on a radio net; VOX magenta: talking in direct voice.
 *   Read from FUNC(voiceTalkers), the voice API's own talking list - this
 *   file names no radio mod. No voice addon, no TX / VOX.
 * - + red: wounded - ACE's bleeding or unconscious state, or vanilla damage
 *   where ACE medical is absent.
 * - ·· : no RF link to him. A player's RF nodes carry his UID between
 *   underscores (the adapters' "<mod>_<uid>_<kind>" ids), so he is linked
 *   when any node the player reaches carries it. Shown only for players, and
 *   only while the player has RF nodes of his own - an AI or a mission
 *   without RF is unknown, not unlinked.
 *
 * Arguments:
 * 0: RF summary from FUNC(overlayRf) <HASHMAP>
 *
 * Return Value:
 * Structured-text lines <ARRAY of STRINGs>
 *
 * Example:
 * private _lines = [jmfsb_devices_overlayRf] call jmfsb_devices_fnc_overlaySquad
 *
 * Public: No
 */

params [["_rf", createHashMap, [createHashMap]]];

private _unit = call CBA_fnc_currentUnit;
if (isNull _unit || {isNull group _unit}) exitWith {[]};

private _teams = createHashMapFromArray TEAM_HTML;
private _voice = [] call FUNC(voiceTalkers);
private _peers = _rf getOrDefault ["peers", []];
private _haveRf = (_rf getOrDefault ["nodes", []]) isNotEqualTo [];
private _hasBft = !isNil QEFUNC(bft,memberNumber);

private _lines = [];
{
    if (!alive _x) then {continue};

    private _number = if (_hasBft) then {[_x] call EFUNC(bft,memberNumber)} else {_forEachIndex + 1};
    private _flags = [];

    private _talking = (_voice getOrDefault [hashValue _x, [objNull, 0]]) select 1;
    if (_talking isEqualTo VOICE_RADIO) then {
        _flags pushBack format ["<t color='%1'>TX</t>", HTML_TX];
    };
    if (_talking isEqualTo VOICE_DIRECT) then {
        _flags pushBack format ["<t color='%1'>VOX</t>", HTML_VOX];
    };

    private _wounded = lifeState _x isEqualTo "INCAPACITATED"
        || {_x getVariable ["ace_isUnconscious", false]}
        || {(_x getVariable ["ace_medical_woundBleeding", 0]) > 0}
        || {damage _x > WOUNDED_DAMAGE};
    if (_wounded) then {
        _flags pushBack format ["<t color='%1'>+</t>", HTML_TX];
    };

    private _uid = getPlayerUID _x;
    if (_haveRf && _x isNotEqualTo _unit && _uid isNotEqualTo "" && {isPlayer _x}) then {
        private _tag = format ["_%1_", _uid];
        if ((_peers findIf {_tag in _x}) < 0) then {
            _flags pushBack format ["<t color='%1'>%2</t>", HTML_DIM, toString [183, 183]];
        };
    };

    _lines pushBack format [
        "<t font='RobotoCondensedBold' color='%1'>%2</t> <t color='%3'>%4</t> %5",
        _teams getOrDefault [assignedTeam _x, _teams get "MAIN"],
        _number,
        HTML_TEXT,
        [toUpper name _x] call EFUNC(tacpad,xmlSafe),
        _flags joinString " "
    ];
} forEach (units group _unit);

_lines
