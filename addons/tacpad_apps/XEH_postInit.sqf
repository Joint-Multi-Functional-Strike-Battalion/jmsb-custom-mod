#include "script_component.hpp"

if (!hasInterface) exitWith {};

// The keys. postInit, not preInit, because CBA_fnc_addKeybind wants the
// keybinding system up - and every key here is a player action anyway.
#include "initKeybinds.inc.sqf"

// Full-size apps a tile or a reader hand-off opens. Anything not registered is
// a no-op rather than an error, so a tile for an app that does not exist yet
// sits there inert instead of throwing.
["comms", FUNC(appComms)] call EFUNC(tacpad,registerApp);

["squad", FUNC(appSquad)] call EFUNC(tacpad,registerApp);
["weather", FUNC(appWeather)] call EFUNC(tacpad,registerApp);

// The other three tiles. Every tile on the band now opens something - a tile
// that logs "no app registered" and does nothing is the exact failure this
// suite has spent the week chasing.

// The whole sweep on one page - the tile band's sixth tile opens it.
["scanner", FUNC(appScanner)] call EFUNC(tacpad,registerApp);

// Drones and jamming are two different things with a page each - the DRONES
// tile opens one, the JAM tile the other. The scanner stays the whole-sweep
// view.
["drones", FUNC(appDrones)] call EFUNC(tacpad,registerApp);
["jam", FUNC(appJamming)] call EFUNC(tacpad,registerApp);

// The player's own clock, off the band.
["timer", FUNC(appTimer)] call EFUNC(tacpad,registerApp);
["radio", FUNC(appRadio)] call EFUNC(tacpad,registerApp);

// A message arriving while the map is open should show up in the docked reader.
//
// BOTH EVENTS. This listened to `received` only, which is traffic addressed to
// this player - and a message filed to a shared channel reaches its own sender
// on the QUIET path, as `indexRefreshed`. So sending to a channel updated
// nothing on screen until something else forced a redraw.
{
    [_x, {
        if (!isNull (HOST_DISPLAY)) then {
            ["reader"] call EFUNC(tacpad,rebuild);
        };
    }] call CBA_fnc_addEventHandler;
} forEach [QEGVAR(messaging,received), QEGVAR(messaging,indexRefreshed)];

// The map closing drops the reader back to the list. A thread left open across
// two map opens is a panel showing something the player has forgotten they
// asked for.
addMissionEventHandler ["Map", {
    params ["_opened"];
    if (!_opened) then {
        GVAR(readerThread) = "";

        // THE SHELL'S VARIABLE, not this addon's. The line below it already had
        // it right; this one was clearing jmfsb_tacpad_apps_appGroup, which
        // nothing reads, and leaving the shell still holding a deleted control.
        uiNamespace setVariable [QEGVAR(tacpad,appGroup), controlNull];

        // And nothing is the open app, so no refresh loop comes back with the
        // map next time - see EFUNC(tacpad,openApp).
        uiNamespace setVariable [QEGVAR(tacpad,appCurrent), ""];
    };
}];

// The intrusion suite, reached from its own tile. It is the interface now -
// hacking's own dialog is gone, and with it fnc_themeTablet, which existed only
// to repaint that dialog in the suite's colours after hacking announced it.
["hack", FUNC(appHack)] call EFUNC(tacpad,registerApp);

// TAC//INTEL - the files a hack recovered, filed against the side that
// recovered them. See EFUNC(hacking,productPackage).
["intel", FUNC(appIntel)] call EFUNC(tacpad,registerApp);

// TAC//SUPPORT - combat support fronted through the support core
// (jmfsb_support), gated by a messaging tag rather than a role tree. One board,
// any number of back ends: every provider registered with
// EFUNC(support,registerProvider) - ALiVE's ATO and NEO combat support through
// the adapter, jmfsb's own CAS drones, support_fires and support_air.
//
// NO SIMPLEX (user, 2026-10-20: "no simplex dependency"). Our own support
// addons replace it; nothing here detects, lists or opens Simplex Support
// Services, and the mod forces none of its settings.
//
// REGISTERED WHEN THE CORE IS LOADED, NOT WHEN ALiVE IS. The core is the
// board's only way in; ALiVE is one optional provider of it, so a mission with
// our own support modules and no ALiVE still gets the board.
if (!isNil QEFUNC(support,assets)) then {
    [SUP_APP, FUNC(appSupport)] call EFUNC(tacpad,registerApp);
};

// THE DELIVERY RECEIPT from the support core: a provider's asset consumed the
// order, or never did. Lands in the support screen's verdict row and the
// notify rail, and forces a redraw so it shows the moment it arrives rather
// than on the next poll tick - the dialog on the vanilla map, the open app on
// the tablet (SUP_SHOWN).
[QEGVAR(support,ack), {
    params [["_assetId", ""], ["_ok", true], ["_said", ""]];
    missionNamespace setVariable [QGVAR(supportFlash), [_said, _ok, CBA_missionTime]];
    ["SUPPORT", _said, ["high", "normal"] select _ok] call EFUNC(messaging,notify);
    if (SUP_SHOWN) then {
        {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    };
}] call CBA_fnc_addEventHandler;

// ON THE TABLET THE BOARD IS SEVERAL TOP-LEVEL CONTROLS, not
// one app group - the map hole between them is the point. FUNC(appFrame)
// replaces only the group, so when any other app takes the screen the rest
// goes here, and the board's hold on the host's map with it.
// On the vanilla map the board is a dialog and its controls die with it.
private _fnc_supportDrop = {
    params [["_keep", "", [""]]];
    if (_keep isNotEqualTo SUP_APP) then {
        private _roots = uiNamespace getVariable [QGVAR(supportRoot), []];
        if (_roots isEqualType controlNull) then {_roots = [_roots]};
        {if (!isNull _x) then {ctrlDelete _x}} forEach _roots;
        uiNamespace setVariable [QGVAR(supportRoot), []];
    };
    if (_keep isNotEqualTo SUP_APP && {(uiNamespace getVariable [QEGVAR(tacpad,appMapClaim), ""]) isEqualTo SUP_APP}) then {
        uiNamespace setVariable [QEGVAR(tacpad,appMapClaim), ""];
    };
};
[QEGVAR(tacpad,appOpened), {
    params [["_app", "", [""]]];
    if (HOST_DEVICE) then {[_app] call _thisArgs};
}, _fnc_supportDrop] call CBA_fnc_addEventHandlerArgs;

// And closing it takes all of it at once, rather than leaving the slabs
// for EFUNC(tacpad,appClose)'s orphan sweep a frame later.
[QEGVAR(tacpad,appClosed), {
    params [["_app", "", [""]]];
    if (HOST_DEVICE && _app isEqualTo SUP_APP) then {[""] call _thisArgs};
}, _fnc_supportDrop] call CBA_fnc_addEventHandlerArgs;
["settings", FUNC(appSettings)] call EFUNC(tacpad,registerApp);

// Each client publishes its own radio state, because only his own client knows
// it - see FUNC(radioState). Five seconds is slower than a man can change net
// and far slower than it matters.
[LINKFUNC(radioPublish), 5, []] call CBA_fnc_addPerFrameHandler;

// THE RADIO BOARD'S RECENT CONTACTS: the people of each call that went live,
// kept off the voice API's call events - see FUNC(radioCalls). The HACK
// board's LOG of the current hack - see FUNC(appHackTrack).
GVAR(radioRecent) = [];
GVAR(radioLast) = ["", -1];
GVAR(hackLog) = [];
[QEGVAR(voice,callState), {_this call FUNC(radioCalls)}] call CBA_fnc_addEventHandler;

// A ring, a call changing state or a net changing redraws the open RADIO board
// at once rather than on its next look (FUNC(appRadio)) - never under a press.
{
    [_x, {
        if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo "radio" && {[] call EFUNC(tacpad,appIdle)}) then {
            {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        };
    }] call CBA_fnc_addEventHandler;
} forEach [QEGVAR(voice,callRing), QEGVAR(voice,callState), QEGVAR(voice,netsChanged)];
