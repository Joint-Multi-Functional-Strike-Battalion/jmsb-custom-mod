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

// ARTY, the artillery team's calculator (user, 2026-10-25), and the
// counter-battery radar's last fix, which jmfsb_reaction sends the team with
// its TAC//MSG report: kept here for the tile and the calculator's RADAR FIX.
["arty", FUNC(appArty)] call EFUNC(tacpad,registerApp);
[QEGVAR(reaction,cbFix), {
    params [["_pos", [], [[]]], ["_at", 0, [0]], ["_what", "", [""]]];
    if (_pos isEqualTo []) exitWith {};
    GVAR(artyFix) = [_pos, _at, _what];
}] call CBA_fnc_addEventHandler;

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
// BOTH PATHS. This listened to arrivals only, which is traffic addressed to
// this player - and a message filed to a shared channel reaches its own sender
// on the QUIET path, as `indexRefreshed`. So sending to a channel updated
// nothing on screen until something else forced a redraw.
//
// Arrivals come through messaging's onReceive hook, run only by its
// server-checked cltReceive - not the `received` CBA event any client could
// raise (review S7).
private _fnc_readerRebuild = {
    if (!isNull (HOST_DISPLAY)) then {
        ["reader"] call EFUNC(tacpad,rebuild);
    };
};
[QEGVAR(messaging,indexRefreshed), _fnc_readerRebuild] call CBA_fnc_addEventHandler;
if (!isNil QEFUNC(messaging,onReceive)) then {
    [_fnc_readerRebuild] call EFUNC(messaging,onReceive);
};

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

// NO TAC//SUPPORT APP (user, 2026-11-01, docs/DESIGN_SUPPORT_MESSAGING.md
// step 9: "no support interface. The support system stays. The JTAC requests
// support by sending a message to the asset"). Support is called from TAC//MSG.
//
// THE DELIVERY RECEIPT from the support core stays: a provider's asset
// consumed an order, or never did, and the notify rail says so. A local hook,
// not a CBA event (review R1): any client could raise the old
// jmfsb_support_ack event on every machine.
if (!isNil QEFUNC(support,onAck)) then {
    [{
        params [["_assetId", ""], ["_ok", true], ["_said", ""]];
        ["SUPPORT", _said, ["high", "normal"] select _ok] call EFUNC(messaging,notify);
    }] call EFUNC(support,onAck);
};

["settings", FUNC(appSettings)] call EFUNC(tacpad,registerApp);
// LOG - the notices log as an app again (user, 2026-11-09: "add back in the
// logs app"): the MENU row and the LOG tile open the reader's LOG view.
[LOG_APP, FUNC(appLog)] call EFUNC(tacpad,registerApp);
// The tablet bar's MENU: every app and the settings (user, 2026-10-30).
[MENU_APP, FUNC(appMenu)] call EFUNC(tacpad,registerApp);

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
