#include "script_component.hpp"

if (!hasInterface) exitWith {};

// The way in is the TAC//MSG and SETTINGS buttons declared into the map
// display itself - see dialog.hpp. A keybind was tried and it was the wrong
// answer: the reader belongs on the map screen where the traffic is.
//
// The keybind stays available but unbound by default, for anyone who wants it.
["1st Joint Multi-Functional Strike Battalion", QGVAR(readerKey), ["Open Message Reader", "Opens the TAC//MSG reader. Also on the TAC//MSG button on the map screen."],
{
    if (!GVAR(enabled)) exitWith {false};
    [] call FUNC(openReader);
    true
}, {false}, [-1, [false, false, false]]] call CBA_fnc_addKeybind;

// THE READER INSIDE THE TABLET IS AN APP, and leaves like one - ESC, CLOSE, a
// map press, a tile opening something else, the device closing. Its group goes
// with the app; the display it was drawn on does not, so the reader's "is it
// open" (GVAR(reader) not null) is dropped here, or every message arriving
// would redraw a reader that is not there and NEW would think it was open.
[QGVAR(appClosed), {
    params [["_app", "", [""]]];
    if (_app isNotEqualTo READER_APP) exitWith {};
    private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
    if (isNull _display) exitWith {};
    private _root = _display displayCtrl IDC_RD_ROOT;
    if (!isNull _root) then {ctrlDelete _root};
    uiNamespace setVariable [QGVAR(reader), displayNull];
}] call CBA_fnc_addEventHandler;

// The map opening and closing drives the always-on readouts. Those are a
// glance, not a screen: the tiles and the squad rail are looked at, and
// anything you press lives in a dialog.
addMissionEventHandler ["Map", {
    params ["_opened"];

    // IN TABLET MODE THE MAP IS A MAP. The suite lives inside the device
    // jmfsb_devices opens, and nothing is built here - see shared.inc.hpp on
    // the host, and FUNC(hostDisplay).
    if (HOST_DEVICE) exitWith {};

    if (!_opened) exitWith {
        [] call FUNC(close);
    };

    // The display is not guaranteed to exist the instant the event fires, and a
    // panel built against a null display is a silent no-show rather than an
    // error - so wait for it rather than assume it.
    [{!isNull (findDisplay IDD_MAP)}, {
        [] call FUNC(open);
    }, [], 1] call CBA_fnc_waitUntilAndExecute;
}];

// A MODE CHANGE TAKES THE SUITE DOWN WHEREVER IT IS. Whatever was built was
// built for the other host, and the next open - map or device - builds it
// again. Back on the map at once if the map is what is open.
[QGVAR(displayMode_changed), {
    [] call FUNC(close);
    [] call FUNC(setHost);
    if (HOST_NATIVE && {!isNull (findDisplay IDD_MAP)}) then {
        [] call FUNC(open);
    };
}] call CBA_fnc_addEventHandler;

// THE SERVER'S REFUSAL, ONTO THE PANE. The client validates before it sends and
// draws its own answer beside SEND, but the server validates again - a thread
// that closed while the card was open, a template that changed - and that answer
// arrives later, as an event. Without this it went only to the notification
// stack, which is an RscTitles layer and therefore behind this dialog: the send
// appeared to work and the message simply never existed.
//
// A hook on messaging's cltReject, which takes its call only from the server -
// not the CBA event it used to be, which any client could raise to fake a
// refusal on every screen (review S7).
if (!isNil QEFUNC(messaging,onReject)) then {
    [{
        params [["_templateId", "", [""]], ["_why", "", [""]]];

        GVAR(composeError) = _why;

        // Put the card back, with everything that was in it. Only when the player
        // has not already started composing something else - restoring over a
        // half-written report to explain a refusal of the last one is worse than
        // the refusal.
        if (!GVAR(composeOn) && {GVAR(composePending) isNotEqualTo []}) then {
            GVAR(composePending) params ["_thread", "_template", "_values", "_grids", "_to", ["_cc", ""], ["_pin", []]];
            GVAR(composeThread) = _thread;
            GVAR(composeTemplate) = _template;
            GVAR(composeValues) = _values;
            GVAR(composeGridText) = _grids;
            GVAR(composeTo) = _to;
            GVAR(composeCc) = _cc;
            GVAR(composePin) = _pin;
            GVAR(composeOn) = true;
        };

        GVAR(composePending) = [];

        if (!isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {
            {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
        };
    }] call EFUNC(messaging,onReject);
};

// TRAFFIC ARRIVING REDRAWS THE READER. Nothing did this, and it is the whole of
// "I send to a channel and it does not show up" and "a quick reply does not
// appear until I touch the marker dropdown" - the message was delivered and
// indexed correctly every time; the screen in front of the player was simply
// never told. Touching a dropdown forced a redraw, which is why that one
// interaction appeared to fix it.
//
// BOTH PATHS, and that is the half that was missed even where a listener
// existed. FUNC(cltReceive) runs the onReceive hooks for traffic addressed to
// you and raises `indexRefreshed` for a QUIET update - a filing into a shared
// box you can read but were not addressed on. Your own copy of a message you
// just sent to a channel arrives on the quiet path, so listening only to
// arrivals meant the sender never saw their own traffic.
//
// Arrivals come through messaging's onReceive hook, which only cltReceive runs
// and cltReceive takes its call only from the server - not the `received` CBA
// event it used to be, which any client could raise (review S7). The quiet
// `indexRefreshed` event stays: it only redraws from this player's own index.
private _fnc_readerRedraw = {
    if (!isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    };
};
[QEGVAR(messaging,indexRefreshed), _fnc_readerRedraw] call CBA_fnc_addEventHandler;

if (!isNil QEFUNC(messaging,onReceive)) then {
    [_fnc_readerRedraw] call EFUNC(messaging,onReceive);

    // FLASH TRAFFIC PUTS A BANNER OVER WHATEVER IS ON SCREEN - the reader, the
    // map or the device (handoff 1a; FUNC(readerFlash) decides where). Only
    // traffic that arrived for this player, never his own copy, and only
    // FLASH: a callout by name already escalates the notification, and a
    // banner per callout would be the double notification the user asked to
    // be rid of.
    [{
        params [["_message", createHashMap, [createHashMap]], ["_entry", createHashMap, [createHashMap]]];
        if (!GVAR(enabled)) exitWith {};
        if ((_entry getOrDefault ["priority", ""]) isNotEqualTo "high") exitWith {};
        if ((getPlayerUID player) in (_message getOrDefault ["readBy", []])) exitWith {};
        [[_entry, _message]] call FUNC(readerFlash);
    }] call EFUNC(messaging,onReceive);
};

// A scheme change repaints what is already on screen. Judging a colour you
// cannot see until you reopen the map is guessing, not choosing.
{
    [_x, {
        if (!isNull (HOST_DISPLAY)) then {
            [] call FUNC(repaint);
        };
    }] call CBA_fnc_addEventHandler;
} forEach [QGVAR(scheme_changed), QGVAR(opacity_changed)];

// A SIZE CHANGE IS A REBUILD, NOT A REPAINT. Panel geometry comes out of
// FUNC(place), so nothing already on screen can grow or shrink by being
// recoloured - the suite is put up again at the new size.
[QGVAR(uiScale_changed), {
    if (!isNull (HOST_DISPLAY)) then {
        [] call FUNC(open);
    };
}] call CBA_fnc_addEventHandler;

// A SCHEME ID THAT WAS RENAMED (2026-10-08: Night Brass became JMSB Night) is
// still in a profile saved before the rename; CBA warns about it on every
// start (RPT, 2026-10-30) and falls back to the default, which is that same
// scheme. Rewritten once, in the profile's own store, through CBA's hash API
// and only when the store is the hash CBA keeps there, so the next start is
// quiet. CBA has already read the store this session: this is for the next.
// CBA keeps [value, priority] under the lower-case setting name - not the
// bare value (the first cut compared the pair to a string and never matched;
// the warning stayed, RPT 2026-10-31).
private _store = profileNamespace getVariable [CBA_PROFILE_STORE, []];
if ([_store] call CBA_fnc_isHash) then {
    private _entry = [_store, toLower QGVAR(scheme)] call CBA_fnc_hashGet;
    if (!isNil "_entry" && {_entry isEqualType []} && {(_entry param [0, ""]) isEqualTo SCHEME_LEGACY}) then {
        _entry set [0, SCHEME_DEFAULT];
        [_store, toLower QGVAR(scheme), _entry] call CBA_fnc_hashSet;
        profileNamespace setVariable [CBA_PROFILE_STORE, _store];
        saveProfileNamespace;
        INFO_2("scheme '%1' in the profile is now '%2'",SCHEME_LEGACY,SCHEME_DEFAULT);
    };
};
