#include "script_component.hpp"
/*
 * Author: Jacco Douma, JMSB
 * Draws one pass of group markers on this machine. Every marker is local and
 * every position is computed locally off the group's own units - what travels
 * the network is nothing but the handful of group variables a leader sets, so
 * the update rate costs no bandwidth at all.
 *
 * Who sees whom is a code match, not a side check. A group TRANSMITS on its
 * encrypt codes and LISTENS on its decrypt codes; a marker is drawn when one of
 * the viewer's codes appears in the target's transmit list. A group with no
 * codes at all falls back to its own side's name, which is what makes the
 * default behaviour "everyone on my side" without any setup.
 *
 * A logged-in admin bypasses the lot - see FUNC(isAdmin).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_bft_fnc_draw
 *
 * Public: No
 */

private _playerGroup = group ACE_player;
private _playerSide = side _playerGroup;

// Admin god view: every group, every name, no obfuscation. GVAR(adminView) is
// the admin's own switch, so they can drop back to the player picture.
private _godView = GVAR(adminGodView) && GVAR(adminView) && {[ACE_player] call FUNC(isAdmin)};

// What this player can hear on: everything the group listens to, plus everything
// it transmits on - you can always read your own net.
private _myCodes = (_playerGroup getVariable [QGVAR(decryptCodes), []]) +
    (_playerGroup getVariable [QGVAR(encryptCodes), [str _playerSide]]);

// DATA DENIAL TAKES THE OTHER GROUPS OFF THE MAP (user, 2026-08-31). A tracker
// is a data product: it arrives over the same link TAC//MSG uses, so a hub that
// denies that link has to take the picture with it, or jamming reads as "the
// messages stopped" and nothing else.
//
// ONE DEFINITION OF DENIED, not a second copy of the band. The state comes from
// EFUNC(messaging,linkState), which already answers "what is the data link doing
// where I am standing" off the jamming registry's own field strength - so the
// handset saying DENIED and the map going empty are the same fact, and neither
// can drift from the other. No messaging addon, or no jamming: the link is up.
//
// YOUR OWN GROUP IS NOT DENIED. Self location is local - your men know where
// they are without asking anyone - so the member marks below survive, and the
// only thing that goes is everybody you were reading over the net. That is the
// whole point of the effect: you can still see yourself, you have just lost
// everyone else. An admin in god view keeps the full picture.
private _dataDenied = false;
if (!_godView && {!isNil "jmfsb_messaging_fnc_linkState"}) then {
    _dataDenied = (([] call jmfsb_messaging_fnc_linkState) param [0, 0]) >= 2;
};

private _index = 0;
private _memberGroups = [];

{
    private _group = _x;

    if (units _group isEqualTo []) then {continue};

    // AN UNCONFIGURED GROUP DRAWS unless the mission said None. This
    // defaulted off in "Player" mode, which made every AI-only friendly
    // group invisible out of the box - and because the setting sits SAVED
    // in player profiles, changing the addon default fixed nobody. The
    // README's promise is a side tracker with no setup; the default-when-
    // unset now keeps it whatever an old profile still carries.
    if (!_godView && {!(_group getVariable [QGVAR(visible), GVAR(autoEnable) > 0])}) then {continue};

    if (!_godView && _group isNotEqualTo _playerGroup) then {
        // The link is down: nothing arrives from off your own group. Checked
        // before the code test because a denied link does not care whose net
        // it was - see _dataDenied above.
        if (_dataDenied) then {continue};

        // Not our own group: we need a code in common with what they transmit.
        private _theirCodes = _group getVariable [QGVAR(encryptCodes), [str side _group]];
        if ((_myCodes arrayIntersect _theirCodes) isEqualTo []) then {continue};
    };

    // YOUR OWN GROUP'S MARKER IS NOISE ON YOUR OWN MAP. It sits on top of you,
    // big enough to hide the ground you are actually reading, and it tells you
    // nothing you do not already know. This is the VIEWER'S draw, not the
    // group's transmit: everyone else on the net still gets your marker, and
    // your own men still get their member marks further down. An admin in god
    // view keeps it - that picture is meant to be complete.
    if (!_godView && GVAR(hideOwnGroup) && _group isEqualTo _playerGroup) then {continue};

    private _markerPos = [_group] call FUNC(getGroupPosition);
    private _markerShape = [_group] call FUNC(getGroupMarkerShape);
    private _markerType = _group getVariable [QGVAR(type), "inf"];
    private _markerColor = _group getVariable [QGVAR(color), [side _group, true] call BIS_fnc_sideColor];
    private _markerText = groupId _group;

    // Another side sharing a net still does not get to read our call signs off
    // the map: they get an unknown icon and the side's name.
    if (!_godView && GVAR(fuzzOtherSides) && {side _group isNotEqualTo _playerSide}) then {
        _markerType = "unknown";
        _markerText = str (side _group);
        _markerColor = [side _group, true] call BIS_fnc_sideColor;
    };

    // Named by index rather than by group: two groups can carry the same
    // groupId, and createMarkerLocal returns "" on a name that already exists.
    //
    // DELETED FIRST, AND CHECKED AFTER. A pass that threw halfway leaves a
    // marker behind under a name this pass is about to ask for; the engine then
    // answers "" and every setMarker command after it throws - which killed the
    // whole tracker, because the throw took the loop's own reschedule with it.
    // One marker that cannot be made is one group not drawn this second.
    private _name = format ["%1_%2", QGVAR(marker), _index];
    _index = _index + 1;

    deleteMarkerLocal _name;
    private _marker = createMarkerLocal [_name, _markerPos];
    if (_marker isEqualTo "") then {continue};

    _marker setMarkerShapeLocal "ICON";
    _marker setMarkerTypeLocal format ["%1_%2", _markerShape, _markerType];
    _marker setMarkerTextLocal _markerText;
    _marker setMarkerColorLocal _markerColor;

    if (_group isNotEqualTo _playerGroup) then {
        // Faded means one-way: we can see them, they cannot see us. Knowing that
        // before you call for support is the point of showing it at all.
        private _theirCodes = (_group getVariable [QGVAR(encryptCodes), [str side _group]]) +
            (_group getVariable [QGVAR(decryptCodes), []]);
        private _myTransmit = _playerGroup getVariable [QGVAR(encryptCodes), [str _playerSide]];
        _marker setMarkerAlphaLocal ([0.6, 1] select ((_theirCodes arrayIntersect _myTransmit) isNotEqualTo []));
    };

    // Member marks belong only to groups whose call signs we may read -
    // never to a fuzzed side; a dot per man would undo the fuzz.
    if (_godView || {side _group isEqualTo _playerSide}) then {
        _memberGroups pushBack _group;
    };

    GVAR(markers) pushBack _marker;
} forEach allGroups;

// ------------------------------------------------------------- members -----
// THE MEN, NOT ONLY THE GROUP - but as the vanilla unit icon, not as
// markers: the rotating iconman circle with its baked-in facing wedge and
// the name beside it, drawn live by FUNC(drawMembers) on the map's own
// Draw event. This pass only decides WHO that is; markers cannot rotate
// with a man's facing and a marker per man per second was churn for a
// worse picture.
GVAR(memberUnits) = [];
if (GVAR(memberMarkers) > 0) then {
    private _mGroups = [[_playerGroup], _memberGroups] select (GVAR(memberMarkers) > 1);
    if (!(_playerGroup in _mGroups) && {!isNull _playerGroup}) then {
        _mGroups pushBack _playerGroup;
    };
    {
        GVAR(memberUnits) append (units _x select {alive _x});
    } forEach _mGroups;
    // YOU ARE NOT ALWAYS THE MARK THE MAP ALREADY SHOWS, AND THIS ASSUMED
    // YOU WERE. The line was `- [ACE_player]`, unconditionally, on the
    // reasoning that the engine draws your own icon so a second one would be
    // a duplicate. That is true on a preset with extended map content ON.
    // A milsim preset turns it OFF (`mapContent = 0`) - which is the whole
    // point of one: you navigate by compass and GPS, not by watching yourself
    // move. DIVINER no longer ships such a preset - the `difficulty` addon was
    // dropped as out of scope, and `jmfsb` still has it - and a server may be
    // running one anyway. With map content off the engine draws nothing, BFT
    // then removed the only other source, and the man looking at the map could
    // see his squad, his group marker and every tracked group on the island
    // EXCEPT HIMSELF.
    //
    // So it is asked rather than assumed. The no-duplicate intent is intact on
    // any preset that does draw you, and a mission that turns map content back
    // on needs no setting changed here.
    if (difficultyOption "mapContent" > 0) then {
        GVAR(memberUnits) = GVAR(memberUnits) - [ACE_player];
    };
};

// WHO IS TALKING, for the member rings - read here, on the slow tick, so the
// per-frame draw only looks it up. Game voice (jmfsb_voice_fnc_talking) names
// every man the local player hears and the net; a net of kind "direct" is
// direct voice, any other a radio net. The local player's own speech is the
// engine's getPlayerChannel (the Direct channel = direct voice). Radio wins
// over direct. No jmfsb_voice, or the rings off: an empty table, every man
// silent.
// KEYED BY hashValue, NOT BY THE UNIT. An object cannot be a hashmap key: every
// lookup threw "Type Object" - over five thousand errors in one session's RPT
// (2026-10-20), from the map draw and the walking view. Each entry is
// [unit, state] so a reader that walks the table still has the man.
GVAR(memberVoice) = createHashMap;
if (GVAR(memberVoiceRings) && {!isNil QEFUNC(voice,talking)}) then {
    private _kinds = createHashMap;
    {_kinds set [_x param [0, ""], _x param [2, ""]]} forEach ([ACE_player] call EFUNC(voice,nets));
    {
        _x params [["_unit", objNull, [objNull]], ["_net", "", [""]]];
        if (isNull _unit) then {continue};
        private _state = [VOICE_RADIO, VOICE_DIRECT] select ((_kinds getOrDefault [_net, ""]) isEqualTo VOICE_KIND_DIRECT);
        private _had = (GVAR(memberVoice) getOrDefault [hashValue _unit, [objNull, VOICE_NONE]]) select 1;
        GVAR(memberVoice) set [hashValue _unit, [_unit, _state max _had]];
    } forEach ([] call EFUNC(voice,talking));
    private _own = getPlayerChannel ACE_player;
    if (_own >= 0) then {
        GVAR(memberVoice) set [hashValue ACE_player, [ACE_player, [VOICE_RADIO, VOICE_DIRECT] select (_own isEqualTo VON_CHANNEL_DIRECT)]];
    };
};

// Fewer marks than the last pass leaves orphans under the higher index
// names - the delete-first at creation only ever covers names this pass
// reuses. Swept every pass; this also closes the latent leak when groups
// disband.
private _prev = missionNamespace getVariable [QGVAR(lastMarkerCount), 0];
for "_i" from _index to (_prev - 1) do {
    deleteMarkerLocal format ["%1_%2", QGVAR(marker), _i];
};
missionNamespace setVariable [QGVAR(lastMarkerCount), _index];

// ---------------------------------------------------------- virtual -----
// THE FRIENDLIES THAT ARE NOT GROUPS. ALiVE simulates most of a side's
// forces without spawning them; those are no group this pass can walk, but
// the commander's COP knows where they are and says so to their own side.
// Drawn faded, unnamed, from that picture - a tracker that showed only the
// spawned quarter of the army was lying by omission.
private _vIndex = 0;
if (GVAR(showVirtual) && {!isNil "jmfsb_adapter_alive_fnc_virtualFriendlies"}) then {
    private _prefix = switch (_playerSide) do {
        case west: {"b"};
        case east: {"o"};
        case independent: {"n"};
        default {"n"};
    };
    private _types = createHashMapFromArray [
        ["infantry", "inf"], ["motor", "motor_inf"], ["mech", "mech_inf"],
        ["armor", "armor"], ["art", "art"], ["aa", "air"], ["at", "inf"], ["air", "plane"]
    ];
    {
        _x params ["_at", "_type", "_count"];
        private _name = format ["%1_%2", QGVAR(vmarker), _vIndex];
        _vIndex = _vIndex + 1;
        deleteMarkerLocal _name;
        private _m = createMarkerLocal [_name, _at];
        if (_m isEqualTo "") then {continue};
        _m setMarkerShapeLocal "ICON";
        _m setMarkerTypeLocal format ["%1_%2", _prefix, _types getOrDefault [_type, "unknown"]];
        _m setMarkerColorLocal ([_playerSide, true] call BIS_fnc_sideColor);
        _m setMarkerAlphaLocal 0.4;
        _m setMarkerTextLocal "";
    } forEach ([_playerSide] call jmfsb_adapter_alive_fnc_virtualFriendlies);
};
private _vPrev = missionNamespace getVariable [QGVAR(lastVirtualCount), 0];
for "_i" from _vIndex to (_vPrev - 1) do {
    deleteMarkerLocal format ["%1_%2", QGVAR(vmarker), _i];
};
missionNamespace setVariable [QGVAR(lastVirtualCount), _vIndex];
