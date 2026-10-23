#include "script_component.hpp"
/*
 * Author: JMSB
 * Who is talking now, for the squad list's TX / VOX flags, the ON BOARD rail
 * and the talking chip: everyone the voice API says the player hears
 * (jmfsb_voice_fnc_talking), and the player himself while he transmits (the
 * jmfsb_voice_talk event, kept in GVAR(talkSelf) by XEH_postInit). A net of
 * kind "direct" is direct voice (VOX); any other net is a radio net (TX).
 *
 * Built once per frame and kept, because three readers ask in the same frame.
 * Empty when the voice addon is not loaded - the flags then simply never show.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * hashValue of the unit -> [unit, VOICE_RADIO or VOICE_DIRECT, net id] <HASHMAP>
 *
 * Example:
 * private _talk = [] call jmfsb_devices_fnc_voiceTalkers
 *
 * Public: No
 */

GVAR(talkersCache) params [["_frame", -1, [0]], ["_cached", createHashMap, [createHashMap]]];
if (_frame isEqualTo diag_frameNo) exitWith {_cached};

private _out = createHashMap;
if (!isNil QEFUNC(voice,talking) && {!isNil QEFUNC(voice,netState)}) then {
    private _kinds = createHashMap;
    {
        _kinds set [_x param [0, ""], _x param [2, ""]];
    } forEach ([] call EFUNC(voice,netState));

    private _heard = [] call EFUNC(voice,talking);
    private _me = call CBA_fnc_currentUnit;
    if (GVAR(talkSelf) isNotEqualTo "" && {!isNull _me}) then {
        _heard pushBack [_me, GVAR(talkSelf)];
    };

    {
        _x params [["_unit", objNull, [objNull]], ["_netId", "", [""]]];
        if (isNull _unit) then {continue};
        private _how = [VOICE_RADIO, VOICE_DIRECT] select ((_kinds getOrDefault [_netId, ""]) isEqualTo VOICE_KIND_DIRECT);
        // A radio net wins over direct voice when a man is heard on both.
        private _had = (_out getOrDefault [hashValue _unit, [objNull, 0]]) select 1;
        if (_how > _had) then {
            _out set [hashValue _unit, [_unit, _how, _netId]];
        };
    } forEach _heard;
};

GVAR(talkersCache) = [diag_frameNo, _out];
_out
