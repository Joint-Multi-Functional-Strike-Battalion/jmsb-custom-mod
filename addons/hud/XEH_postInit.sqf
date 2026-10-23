#include "script_component.hpp"

if (!hasInterface) exitWith {};

// The layer goes up once settings are in and stays up. Putting it up per readout
// would fight every other title layer in the mod for the same channel.
["CBA_settingsInitialized", {
    [] call FUNC(open);
    [] call FUNC(draw);
}] call CBA_fnc_addEventHandler;

// ENABLED, AND WANTED ON THIS HOST. In tablet mode the HUD is off unless the
// player asked to keep it - see the showInTablet setting - so a display-mode
// change is the same event as the switch: whichever way it went, the answer to
// "should the slots be up" may have turned over.
{
    [_x, {
        if (GVAR(enabled) && {HOST_NATIVE || GVAR(showInTablet)}) then {
            [] call FUNC(open);
            [] call FUNC(draw);
        } else {
            [] call FUNC(close);
        };
    }] call CBA_fnc_addEventHandler;
} forEach [QGVAR(enabled_changed), QEGVAR(tacpad,displayMode_changed)];

// A SCHEME CHANGE REPAINTS THIS TOO. The HUD is drawn in the tacpad's colours,
// so a player switching to Night Olive on the map screen must not come back to a
// grey HUD.
{
    [_x, {[] call FUNC(draw)}] call CBA_fnc_addEventHandler;
} forEach [QEGVAR(tacpad,scheme_changed), QEGVAR(tacpad,uiScale_changed)];

// Tidiness, not a safety net. The mission display takes the slots with it when
// it goes, so this only keeps the stored handle honest.
addMissionEventHandler ["Ended", {[] call FUNC(close)}];

// GETTING OUT OF THE WAY, EVERY FRAME, FOR ANYTHING.
//
// This was a "Map" mission event handler and nothing else, which covered the
// map and left every dialog in the mod uncovered - the admin console had the
// SCANNER slot printed across its UTILITIES and ADMIN ACTIONS rows. A mission
// event handler can only answer for the one event it is named after, and there
// is no "a dialog opened" event to name; the engine will only answer the
// question when asked. So it is asked, once a frame, by FUNC(hidden).
//
// AFFORDABLE BECAUSE IT DOES NOTHING. FUNC(setShown) compares one boolean
// against the last one and returns - the controls are touched only on the frame
// the answer turns over, which is twice per screen the player opens.
//
// The map rule moved into FUNC(hidden) with it rather than staying here as a
// second copy: the tick below asks the same question, and two copies of a rule
// are how a HUD ends up hidden and still redrawing.
[{[] call FUNC(setShown)}, 0, []] call CBA_fnc_addPerFrameHandler;

// ONE LOOP FOR BOTH SLOTS. A scanner sweep and a countdown do not need the same
// cadence, but two handlers redrawing the same layer would be two chances to
// leave one running - and a second is fast enough for anything on a HUD.
[{
    if (!GVAR(enabled)) exitWith {};

    // NO MISSION, NO HUD. The slots live on the mission display now and die
    // with it, so this is only here to drop the stale handle.
    if (isNull player) exitWith {
        if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
            [] call FUNC(close);
        };
    };
    if ([] call FUNC(hidden)) exitWith {};

    // NO "IS IT UP?" GUARD. FUNC(draw) raises the HUD when it finds no
    // display, and this tick is what makes that a recovery rather than a
    // one-shot: a mission that came up too slowly for the opener gets its
    // HUD a second later instead of never.
    [] call FUNC(draw);
}, 1, []] call CBA_fnc_addPerFrameHandler;

// THE ARBITER for "not resized / no icons" reports: says in one line whether
// this build carries the grid re-read at all, what the Layout editor actually
// saved, and where the control really is - so a stale-build test and a real
// failure can never be confused again.
["hud.state", "dump both HUD slots: layout-editor grid vars vs live control position", {
    private _display = uiNamespace getVariable [QGVAR(display), displayNull];
    // Bump this when a hud fix lands, so a test run can prove in one command
    // which code it is actually exercising.
    private _out = [format [
        "hud code level: 4 (slots on mission display) | display46: %1 | stored: %2",
        !isNull (findDisplay 46),
        !isNull _display
    ]];

    {
        private _idc = _x;
        private _grid = ["grid_jmfsb_hudLeft", "grid_jmfsb_hudRight"] select _forEachIndex;
        private _ctrl = _display displayCtrl _idc;

        private _vars = ["X", "Y", "W", "H"] apply {
            private _v = profileNamespace getVariable [format ["IGUI_%1_%2", _grid, _x], "unset"];
            if (_v isEqualType 0) then {_v toFixed 3} else {_v}
        };

        _out pushBack format [
            "%1: saved [%2] | ctrl %3",
            _grid,
            _vars joinString " ",
            if (isNull _ctrl) then {"NULL"} else {(ctrlPosition _ctrl) apply {_x toFixed 3}}
        ];
    } forEach [IDC_HUD_LEFT, IDC_HUD_RIGHT];

    _out joinString "  ||  "
}, true] call EFUNC(common,addDebugCommand);

// --- The way in -------------------------------------------------------------
// THE BRACKETS, BECAUSE THE SLOTS ARE LEFT AND RIGHT. [ is the left slot and ]
// is the right one, which is a mapping nobody has to be told twice and one that
// survives forgetting it for a month.
//
//   SHIFT + [ / ]   on and off
//   ALT   + [ / ]   step through the readouts
//
// SHIFT IS THE ONE PRESSED MOST, so it gets the simpler job. Turning a slot off
// to see the ground under it is a thing done constantly; changing which readout
// is in it is a thing done once a patrol.
//
// Both bracket keys are free in vanilla Arma with those modifiers, and CBA shows
// a conflict if a mission or another mod disagrees.
{
    _x params ["_id", "_slot", "_dik", "_shift", "_alt", "_title", "_tip", "_code"];

    ["1st Joint Multi-Functional Strike Battalion", _id, [_title, _tip], _code, {false}, [_dik, [_shift, false, _alt]]] call CBA_fnc_addKeybind;
} forEach [
    [QGVAR(toggleLeft), HUD_SLOT_LEFT, DIK_LBRACKET, true, false,
        "HUD - left slot on/off",
        "Turns the left HUD slot off, and back on to whatever it was showing. Position both slots in Options > Game > Layout.",
        {[HUD_SLOT_LEFT] call FUNC(toggle); true}],

    [QGVAR(toggleRight), HUD_SLOT_RIGHT, DIK_RBRACKET, true, false,
        "HUD - right slot on/off",
        "Turns the right HUD slot off, and back on to whatever it was showing.",
        {[HUD_SLOT_RIGHT] call FUNC(toggle); true}],

    [QGVAR(cycleLeft), HUD_SLOT_LEFT, DIK_LBRACKET, false, true,
        "HUD - cycle left slot",
        "Steps the left HUD slot through DRONES, JAMMING, RADIO, SCANNER, SQUAD, TIMER and off.",
        {[HUD_SLOT_LEFT] call FUNC(cycle); true}],

    [QGVAR(cycleRight), HUD_SLOT_RIGHT, DIK_RBRACKET, false, true,
        "HUD - cycle right slot",
        "Steps the right HUD slot through DRONES, JAMMING, RADIO, SCANNER, SQUAD, TIMER and off.",
        {[HUD_SLOT_RIGHT] call FUNC(cycle); true}]
];
