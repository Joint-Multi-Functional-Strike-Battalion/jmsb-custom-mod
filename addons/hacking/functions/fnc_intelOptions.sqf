#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_intelOptions

Description:
    What this hack could be made to produce, given where it is happening and
    what the mission currently has. Also keeps the session's choice valid when
    the list changes under it.

    It lived inside FUNC(tabletRefresh), which meant the answer only existed
    while the suite's own dialog was on screen - anything else that wanted to
    offer the same choices had to work them out again and could disagree. It is
    a question about the mission, not about a display.

    WHAT THIS DEVICE CAN BE MADE TO PRODUCE. A package if somebody put one on
    it, plus whatever hunts the mission currently has anything to hunt.

    IT WAS SCOPED BY TAOR, AND IS NOT ANY MORE. FUNC(taorType) asked ALiVE which
    commander held the spot and what kind of war it was fighting - invasion and
    occupation offered the integrated defence network, asymmetric offered the
    leader chain. That question died with ALiVE, and it was the wrong question:
    what a terminal can tell you is a fact about the terminal, which is now
    exactly what a mission maker writes on it.

    AN EMPTY LIST IS STILL POSSIBLE and still says so. A device nobody put a
    package on, on a map with no anti-ship, no jammers and no leaders, has
    nothing to offer - and a button that can only ever say "nothing" teaches
    players to stop reading the list.

Parameters:
    _session : HASHMAP - the tablet session. Optional, default the live one.

Returns:
    ARRAY - [id, label] pairs, capped at TAB_INTEL.

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_session", GVAR(session), [createHashMap]]];

private _avail = [];

if ((_session get "kind") isEqualTo "drone") exitWith {
    // A drone hack does one thing; there is nothing to choose.
    _avail = [["none", "DOWN THE DRONE"]];
    GVAR(intelAvailable) = _avail;
    _session set ["intel", "none"];
    _avail
};

// THE DEVICE DECIDES FIRST, and the ground scopes what is left. jmfsb switched
// the whole menu on FUNC(taorType) - which commander holds this spot and what
// kind of war it is fighting - and a device with nothing to do with any of that
// offered nothing. DIVINER threw the scoping out and made the list flat, so a
// terminal could carry a package wherever it stood.
//
// Both, here. The package is always offered if the device has one, because that
// is a fact about the device. The ALiVE-fed hunts are scoped the way jmfsb
// scoped them, because that split is the point of them: breaking into a phone
// net in a town should tell you about the town.
//
// WITH NO ALiVE, taorType returns "" and NOTHING IS SCOPED OUT - the list is
// flat again and behaves exactly as DIVINER's did. That is why the tests below
// are written as "not the wrong kind of ground" rather than "the right kind".
private _device = _session getOrDefault ["device", objNull];
private _at = if (isNull _device) then {getPosATL player} else {getPosATL _device};
private _war = [_at] call FUNC(taorType);
private _conventional = _war isNotEqualTo "asymmetric";
private _asymmetric   = !(_war in ["invasion", "occupation"]);

// The mission's own intel, if somebody put a package on this device with a
// JMSB - Intel Package module. First in the list because it is the reason to
// hack a terminal rather than a thing you might also get, and never scoped.
if (!isNull _device && {(_device getVariable [QGVAR(package), ""]) isNotEqualTo ""}) then {
    _avail pushBack ["package", "DOWNLOAD FILES"];
};

// --- the integrated defence network -----------------------------------------
// The counts are read as PUBLISHED VARIABLES, not through the adapter's data
// functions: those answer only on the server and this runs on a client. The
// adapter republishes them on a 30s beat. Without ALiVE they never exist, read
// as 0, and those hunts are simply not offered (user, 2026-11-02).
if (_conventional) then {
    if ((missionNamespace getVariable [QEGVAR(adapter_alive,aaCount), 0]) > 0) then {
        _avail pushBack ["aa", "LOCATE AA"];
    };
    // The anti-ship network, split into the launchers and the eyes that feed
    // them - killing one does not kill the other, so they are two hunts. Both
    // read jmfsb's own objects, which is why they outlived the six that read
    // ALiVE's.
    if ((missionNamespace getVariable [QEGVAR(antiship,batteries), []]) isNotEqualTo []) then {
        _avail pushBack ["coastal", "LOCATE ANTI-SHIP"];
    };
    // Our live radar objects OR the adapter's count of ALiVE's radar profiles -
    // FUNC(productLocateRadar) merges both pools, so either one is enough to
    // put the button up.
    if ((missionNamespace getVariable [QEGVAR(antiship,radars), []]) isNotEqualTo []
        || {(missionNamespace getVariable [QEGVAR(adapter_alive,radarCount), 0]) > 0}) then {
        _avail pushBack ["radar", "LOCATE RADAR"];
    };
    if ((missionNamespace getVariable [QEGVAR(adapter_alive,artyCount), 0]) > 0) then {
        _avail pushBack ["arty", "LOCATE ARTILLERY"];
    };
    // The rear: where the men not on the line sleep, and where what feeds the
    // line comes from.
    if ((missionNamespace getVariable [QEGVAR(adapter_alive,campCount), 0]) > 0) then {
        _avail pushBack ["camp", "LOCATE CAMP"];
    };
    if ((missionNamespace getVariable [QEGVAR(adapter_alive,hubCount), 0]) > 0) then {
        _avail pushBack ["hub", "LOCATE LOGISTICS"];
    };
};

// The jammers holding the quiet up. Never scoped - a jammer is a jammer
// whichever kind of war is being fought around it, and a hand-placed Jammer
// Site owes nothing to a commander.
if ((missionNamespace getVariable ["jmfsb_jamming_zoneCount", 0]) > 0) then {
    _avail pushBack ["jam", "LOCATE JAMMER"];
};

// --- the leader chain -------------------------------------------------------
if (_asymmetric) then {
    if ((missionNamespace getVariable ["jmfsb_leaders_upCount", 0]) > 0) then {
        _avail pushBack ["leader", "TRACE NETWORK"];
    };
    if (!isNil QEFUNC(adapter_alive,installations)
        && {[] call EFUNC(common,aliveLoaded)}
        && {([] call EFUNC(adapter_alive,installations)) isNotEqualTo []}) then {
        _avail pushBack ["installation", "LOCATE INSTALLATION"];
    };
};

if (count _avail > TAB_INTEL) then { _avail = _avail select [0, TAB_INTEL] };
GVAR(intelAvailable) = _avail;

// Keep the selection valid when the list changes under it.
//
// AN EMPTY LIST LEAVES THE SELECTION ALONE. Blanking it made the session carry
// no product, which a gate in FUNC(tabletAction) then refused to start on - and
// a hack that will not begin reads as a broken hack, not as a considered
// refusal. The scoping decides what is OFFERED; it does not decide whether the
// suite works.
private _intel = _session get "intel";
if (_avail isNotEqualTo [] && {(_avail findIf { (_x select 0) isEqualTo _intel }) < 0}) then {
    _session set ["intel", (_avail param [0, ["", ""]]) select 0];
};

_avail
