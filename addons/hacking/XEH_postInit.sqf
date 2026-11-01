#include "script_component.hpp"

// Intel marker from a successful hack. The server picks the target and sends one
// event; each machine builds the marker locally, rather than the server issuing
// four global marker commands.

// Tablet state. Deliberately outside the display: it is what lets a hack be
// paused by closing the screen and resumed by reopening it.
GVAR(devices) = [];
GVAR(intelAvailable) = [];
GVAR(lastScan) = -1e9;
GVAR(tabletPFH) = -1;

// THE SESSION IS THE SUITE'S, NOT THE DIALOG'S. It was created inside
// FUNC(tabletOpen), so it existed only once this addon's own screen had been
// opened - and the tacpad's INTRUSION app never opens that screen. Every tick it
// ran, FUNC(tabletAdvance) found no session and returned on its first line, so
// the device list was never scanned: the tile said a tower was in range and the
// app said NOTHING IN RANGE, for as long as the mission lasted.
GVAR(session) = createHashMapFromArray [
    ["device", objNull], ["kind", ""], ["intel", "picture"], ["action", HACK_ACTION_DEFAULT],
    ["running", false], ["progress", 0], ["time", 60], ["range", 20], ["last", 0]
];

// THE SERVER'S HACK LEDGER (review S7): when it saw each hack start, what is
// broken already, when each tower was last hacked, when each man last banked.
// localNamespace, not missionNamespace - no client can publicVariable over it.
// A finished hack is checked and acted on by FUNC(srvHackComplete), reached by
// remoteExec; the CBA events that deleted any object and pulled any product
// for any side are gone.
if (isServer) then {
    localNamespace setVariable [QGVAR(srvStarts), createHashMap];
    localNamespace setVariable [QGVAR(srvDone), createHashMap];
    localNamespace setVariable [QGVAR(srvTowerAt), createHashMap];
    localNamespace setVariable [QGVAR(srvDepositAt), createHashMap];
};

// --- Phase 2 admin test commands + HUD placement ---------------------------



// PRODUCTS AND RESULTS COME FROM THE SERVER ALONE (review S7): it sends
// FUNC(renderProduct) (through FUNC(sendProduct)) and FUNC(pickResult) by
// remoteExec, and each takes them only from the server. The side filter lives
// on the receiving client, so the enemy never draws them. The "render",
// "pickResult" and "product" CBA events are gone; jmfsb_leaders calls
// FUNC(sendProduct) too.

// RF REACH: a client with the HACK board open asks, the server answers that
// client only, by remoteExec to FUNC(rfReached), taken only from the server
// (review S7). The ask stays a CBA event (the tacpad's HACK board raises it):
// it carries no trust - the answer is the named man's own reach, sent to his
// machine alone - and is answered at most every RF_REACH_MIN_GAP per man,
// because each answer casts RF budgets. See FUNC(rfReach).
if (isServer) then {
    [QGVAR(rfReachAsk), {
        params [["_unit", objNull, [objNull]]];
        if (isNull _unit || {!isPlayer _unit}) exitWith {};
        private _asked = localNamespace getVariable [QGVAR(srvRfAsked), createHashMap];
        private _key = _unit call BIS_fnc_netId;
        if ((CBA_missionTime - (_asked getOrDefault [_key, -RF_REACH_MIN_GAP])) < RF_REACH_MIN_GAP) exitWith {};
        _asked set [_key, CBA_missionTime];
        localNamespace setVariable [QGVAR(srvRfAsked), _asked];
        [[_unit] call FUNC(rfReach)] remoteExecCall [QFUNC(rfReached), _unit];
    }] call CBA_fnc_addEventHandler;

    // REMOTE HACKING IS A SETTING, NOT A MODULE. The enable and the range used
    // to be published by an Eden module; every other rh_* value already falls
    // back to its macro default at the reader, so the switch and the one number
    // a mission actually tunes are all that needs writing.
    [{
        if !(GVAR(remoteEnable)) exitWith {};
        missionNamespace setVariable [QGVAR(rh_max_range), GVAR(remoteRange) max 50, true];
        missionNamespace setVariable [QGVAR(remoteHackEnabled), true, true];
        INFO_1("remote unit hack online - %1 m range",GVAR(remoteRange) max 50);
    }] call EFUNC(common,runAfterSettingsInit);

    // Scanner alarms live here so they fire with the setter gone. Clients arm,
    // delete and clear by remoteExec (FUNC(srvAlarmAdd), FUNC(srvAlarmDelete),
    // FUNC(srvAlarmsClear)); the list is in localNamespace and the public copy
    // is for screens (review S7). The ring goes out by remoteExec from the
    // server alone (FUNC(alarmRing)). A witnessed pop hack is decided in
    // FUNC(srvHackStart) - the "popSeen", "alarmsClear" and "alarmDelete" CBA
    // events are gone. The tacpad's TIMER app uses the same two functions, so
    // the "alarmAdd" event and the publicVariable delete path are gone too.
};

// --- Phase 3 admin test commands -------------------------------------------

["hack.state", "dump the intrusion session AND the screen driving it", {
    params ["", "_caller"];

    private _s = missionNamespace getVariable [QGVAR(session), createHashMap];
    private _dev = _s getOrDefault ["device", objNull];

    [format [
        "session: running %1 | kind %2 | intel '%3' | device %4 | dist %5 m | range %6 | time %7 s | progress %8",
        _s getOrDefault ["running", "-"],
        _s getOrDefault ["kind", "-"],
        _s getOrDefault ["intel", "-"],
        [typeOf _dev, "NONE"] select (isNull _dev),
        [round (player distance _dev), -1] select (isNull _dev),
        _s getOrDefault ["range", "-"],
        _s getOrDefault ["time", "-"],
        _s getOrDefault ["progress", "-"]
    ], _caller] call EFUNC(common,debugReply);

    [format [
        "clock:   last %1 | now %2 | in range %3",
        _s getOrDefault ["last", "-"],
        CBA_missionTime,
        [_dev, _s] call FUNC(tabletInRange)
    ], _caller] call EFUNC(common,debugReply);

    // THE OTHER HALF, AND THE HALF THAT HAS BEEN WRONG EVERY TIME. A session can
    // be running perfectly while nothing on screen advances, because the thing
    // that calls FUNC(tabletAdvance) is a per-frame handler owned by the tacpad
    // app - and it has died three separate ways: a variable name that nothing
    // wrote, a guard that removed it on its first tick, and a redraw hold that
    // never expired. If the bar is stuck, this line says whether anything is
    // driving it at all.
    [format [
        "screen:  app '%1' | group %2 | hack PFH %3 | devices %4",
        uiNamespace getVariable [QEGVAR(tacpad,appCurrent), "-"],
        ["NULL", "up"] select !isNull (uiNamespace getVariable [QEGVAR(tacpad,appGroup), controlNull]),
        uiNamespace getVariable [QEGVAR(tacpad_apps,hackPFH), "-"],
        count (missionNamespace getVariable [QGVAR(devices), []])
    ], _caller] call EFUNC(common,debugReply);

    [format [
        "gates:   canHack %1 | scanner %2 | remote hack %3",
        [player] call FUNC(canHack),
        [player] call FUNC(hasScanner),
        missionNamespace getVariable [QGVAR(remoteHackEnabled), false]
    ], _caller] call EFUNC(common,debugReply);

    nil
}, true] call EFUNC(common,addDebugCommand);

["hack.product", "render one product now: hack.product aa|arty|coastal|radar|jam|leader|installation", {
    params ["_args", "_caller"];
    private _p = toLower (_args param [0, "aa"]);
    [_p, getPosASL _caller, side group _caller, _caller] call FUNC(serverPick);
    format ["ran product '%1'", _p]
}] call EFUNC(common,addDebugCommand);

["hack.spent", "list or clear the spent EW zone set: hack.spent [clear]", {
    params ["_args"];
    if (toLower (_args param [0, ""]) isEqualTo "clear") exitWith {
        GVAR(spentZones) = [];
        "spent zone set cleared"
    };
    private _s = missionNamespace getVariable [QGVAR(spentZones), []];
    if (_s isEqualTo []) then { "no zones spent yet" } else { _s joinString ", " }
}] call EFUNC(common,addDebugCommand);

// --- Phase 4 admin test commands -------------------------------------------

["hack.fail", "force the remote-hack failure package on me", {
    params ["_args", "_caller"];
    [_caller, getPosASL _caller] call FUNC(remoteHackFail);
    "failure package fired - check behaviour of nearby enemy groups / ew.zones for a temp zone"
}] call EFUNC(common,addDebugCommand);

["hack.devices", "list what the tablet can currently see", {
    params ["_args", "_caller"];
    private _d = [_caller] call FUNC(scanDevices);
    if (_d isEqualTo []) exitWith { "nothing hackable in range" };
    (_d apply {
        _x params ["_o", "_kind", "_label", "_dist", "_range"];
        format ["%1 %2 %3m/%4m", _kind, _label, round _dist, round _range]
    }) joinString "  |  "
}, true] call EFUNC(common,addDebugCommand);

// THE HAND-HELD SCANNER, its stopwatch, and the alarm dial. The device was
// removed once and asked back: a thing you hold up while walking is not the
// same as a screen you stop and open. All three gate on GVAR(scannerVariable),
// which is wider than the terminal on purpose - reading warning lamps is
// passive, so the terminal counts as a scanner but not the other way round.
if (hasInterface) then {
    ["1st Joint Multi-Functional Strike Battalion", QGVAR(scannerKey), ["Toggle Signal Scanner", "Shows or hides the hand-held scanner."],
    {
        [player] call FUNC(scannerToggle);
        true
    }, {false}, [0x16, [false, true, false]]] call CBA_fnc_addKeybind;   // Ctrl+U, rebindable
    // Off the H cluster: ACE medical lives there.

    // One key does all three jobs - press to start, press to stop, press again
    // to clear - so it can be worked without looking at the screen.
    ["1st Joint Multi-Functional Strike Battalion", QGVAR(timerKey),
    ["Scanner Stopwatch", "Start, stop, then clear the scanner's stopwatch. Needs the scanner on you; it keeps counting whether or not the screen is up."],
    {
        if !([player] call FUNC(hasScanner)) exitWith { false };
        call FUNC(scannerTimer);
        true
    }, {false}, [0x16, [false, true, true]]] call CBA_fnc_addKeybind;   // Ctrl+Shift+U, rebindable

    // The alarm: press to add 5 minutes, stop pressing to arm, press to shut
    // it up when it rings. Server-wide by design - one person sets it and
    // every scanner in the mission goes off.
    ["1st Joint Multi-Functional Strike Battalion", QGVAR(alarmKey),
    ["Scanner Alarm", "Each press adds 5 minutes; it arms itself when you stop pressing. When it goes off, EVERY scanner on the server beeps. Press while ringing to silence yours. Needs the scanner on you."],
    {
        if !([player] call FUNC(hasScanner)) exitWith { false };
        call FUNC(scannerAlarm);
        true
    }, {false}, [0x16, [true, true, false]]] call CBA_fnc_addKeybind;   // Shift+Ctrl+U, rebindable

    // Unbound on purpose: wiping every alarm on the net is not something to
    // sit next to the key that sets one.
    ["1st Joint Multi-Functional Strike Battalion", QGVAR(alarmClearKey),
    ["Clear Scanner Alarms", "Cancels every armed scanner alarm, server-wide. Unbound by default."],
    {
        if !([player] call FUNC(hasScanner)) exitWith { false };
        GVAR(alarmRingUntil) = -1;
        if (GVAR(alarms) isEqualTo []) exitWith { true };
        [] remoteExecCall [QFUNC(srvAlarmsClear), SERVER_OWNER];
        ["Alarm", "All alarms cleared.", [0.914, 0.651, 0.235, 1]] call EFUNC(notify,notify);
        true
    }, {false}, [0, [false, false, false]]] call CBA_fnc_addKeybind;

    // The handset in the equipment menu, for anyone who would rather point
    // than remember three chords. Every entry is the same code path as its
    // keybind - the menu is another way in, never another behaviour.
    private _scanner = [QGVAR(scannerMenu), "Signal Scanner", QPATHTOF(data\hackphone_icon.paa),
        {[_player] call FUNC(scannerToggle)}, { [_player] call FUNC(hasScanner) }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "ACE_Equipment"], _scanner] call ace_interact_menu_fnc_addActionToObject;

    private _menuPath = ["ACE_SelfActions", "ACE_Equipment", QGVAR(scannerMenu)];

    private _watch = [QGVAR(scannerStopwatch), "Stopwatch: Start / Stop / Clear", "",
        { call FUNC(scannerTimer) }, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, _menuPath, _watch] call ace_interact_menu_fnc_addActionToObject;

    // Only offered while a ring is actually going, so the menu never shows a
    // button that would do nothing.
    private _silence = [QGVAR(scannerSilence), "Silence Alarm", "",
        { GVAR(alarmRingUntil) = -1 }, { time < GVAR(alarmRingUntil) }] call ace_interact_menu_fnc_createAction;
    [player, 1, _menuPath, _silence] call ace_interact_menu_fnc_addActionToObject;

    // Presets rather than the keybind's +5 dial: a menu that has to be
    // reopened for every press can't dial, but it can hold a row of buttons.
    private _setAlarm = [QGVAR(scannerAlarmMenu), "Set Alarm (all scanners)", "",
        {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, _menuPath, _setAlarm] call ace_interact_menu_fnc_addActionToObject;

    {
        private _preset = [format [QGVAR(alarmPreset%1), _x], format ["%1 minutes", _x], "",
        {
            params ["", "", "_min"];
            [_min * 60] remoteExecCall [QFUNC(srvAlarmAdd), SERVER_OWNER];
            ["Alarm", format ["Alarm armed: %1 min, all scanners.", _min],
                [0.914, 0.651, 0.235, 1]] call EFUNC(notify,notify);
        }, {true}, {}, _x] call ace_interact_menu_fnc_createAction;
        [player, 1, _menuPath + [QGVAR(scannerAlarmMenu)], _preset] call ace_interact_menu_fnc_addActionToObject;
    } forEach [5, 10, 15, 30, 60];

    // NO MOVE ACTION HERE ANY MORE. It drove jmfsb's own drag-and-save, which
    // meant the handset was moved by a jmfsb-specific gesture that knew nothing
    // about where the player had put the rest of their screen. It is registered
    // as an IGUI grid now - see CfgUIGrids.hpp - so it is dragged in
    // Options > Game > Layout alongside the HUD slots and the stamina bar.

    // NOTHING LISTENS FOR A MOVE. The Layout editor raises no event, so a
    // position changed there is picked up the next time the handset is opened -
    // FUNC(scannerLayout) reads the grid every time it runs. One toggle, not a
    // guess at an event the engine does not send.
};

// Worth having precisely because the draw is meant to be opaque to the mission
// maker: this is the only way to see which candidates won without playing it.
// THE KEY THAT SHUTS IT UP. An alarm that can only be waited out is an alarm a
// section turns the volume slider to zero for, and then never hears again.
// Unbound by default - it is one key in a suite that already asks for several,
// and the man who wants it will bind it the first time it goes off.
if (hasInterface) then {
    ["1st Joint Multi-Functional Strike Battalion", QGVAR(silenceKey),
        ["Silence alarm", "Stops the alarm beeping on your machine. The alarm stays on the section's roster and nobody else is silenced - it has already fired, this only ends the noise afterwards."],
        {
            if !([] call FUNC(alarmSilence)) exitWith {false};
            ["Alarm", "Silenced.", [0.6, 1, 0.6, 1]] call EFUNC(notify,notify);
            true
        },
        {false},
        [-1, [false, false, false]]
    ] call CBA_fnc_addKeybind;
};

["hack.taor", "which commander holds the ground you are on, and what it will offer", {
    params ["_args", "_caller"];

    if (isNil "jmfsb_adapter_alive_fnc_commanders") exitWith {"no ALiVE adapter - no commanders, so no products"};

    private _at = getPosATL _caller;
    private _type = [_at] call FUNC(taorType);

    [format ["at %1: %2", mapGridPosition _at,
        [format ["'%1' ground", _type], "nobody's ground - the hack offers nothing"] select (_type isEqualTo "")
    ], _caller] call EFUNC(common,debugReply);

    {
        _x params ["_side", "_ctype"];
        ([_side] call jmfsb_adapter_alive_fnc_taorFor) params [["_taor", []], ["_black", []]];
        [format ["  %1 %2 - taor [%3] blacklist [%4]", _side, _ctype,
            [_taor joinString " ", "whole map"] select (_taor isEqualTo []),
            [_black joinString " ", "none"] select (_black isEqualTo [])
        ], _caller] call EFUNC(common,debugReply);
    } forEach (call jmfsb_adapter_alive_fnc_commanders);

    nil
}, true] call EFUNC(common,addDebugCommand);

["hack.alarm", "scanner alarms: hack.alarm <minutes> arms one, ring fires one now, clear wipes them, no args lists", {
    params ["_args", "_caller"];
    private _arg = toLower (_args param [0, ""]);
    switch (true) do {
        case (_arg isEqualTo "ring"): {
            [name _caller] remoteExecCall [QFUNC(alarmRing), 0];
            "rang every scanner on the server"
        };
        case (_arg isEqualTo "clear"): {
            [] call FUNC(srvAlarmsClear);
            "cleared all armed alarms"
        };
        case (_arg isNotEqualTo ""): {
            [(parseNumber _arg) * 60, name _caller] call FUNC(alarmAdd);
            format ["armed an alarm for %1 min", parseNumber _arg]
        };
        default {
            private _a = localNamespace getVariable [QGVAR(alarms), []];
            if (_a isEqualTo []) exitWith { "no alarms armed" };
            (_a apply {
                _x params ["_id", "_at", "_name"];
                format ["#%1 %2s (%3)", _id, round (_at - CBA_missionTime), _name]
            }) joinString "  |  "
        };
    };
}] call EFUNC(common,addDebugCommand);

["hack.scan", "print one scanner sweep", {
    ([] call FUNC(scannerRead)) params ["_ds", "_dd", "_dir", "_jam", "_chan", "_freq", "_mesh"];
    format ["drone %1 (%2) | jam %3 | mesh %4 | %5 %6",
        ["clear", "WARN", "ALERT"] select _ds,
        if (_dd < 0) then { "-" } else { format ["brg %1, %2m", _dir, round _dd] },
        _jam toFixed 2, _mesh, _chan, _freq]
}, true] call EFUNC(common,addDebugCommand);

// Read-only: the ISR flag belongs to the mission framework, so this reports
// what it sees and never writes it.
["hack.isr", "report your ISR operator flag", {
    private _var = EGVAR(common,isrVariable);
    format ["%1 on %2 = %3 (set by the mission, not by jmfsb)",
        _var, name player, player getVariable [_var, false]]
}, true] call EFUNC(common,addDebugCommand);

// --- the intel tally: deposit -> counter -> hint ---------------------------
// The tally (banked, hint tier, ids hinted) is the server's, in localNamespace
// (review S7); missionNamespace GVAR(banked) is a public copy for screens.
if (isServer) then {
    localNamespace setVariable [QGVAR(banked), 0];

    // WHOSE WAR IS WHOSE, cached once. Which side yields phones and which
    // yields radios is the commanders' controltype, read through the adapter -
    // never a faction list kept here. Commanders do not change mid-mission, so
    // this is built once and read on every death.
    GVAR(sideControl) = createHashMap;
    // Once the adapter is ready, once only - not the ready CBA event any
    // client could raise again (review R1).
    if (isNil QEFUNC(adapter_alive,whenReady)) exitWith {};
    [{
        if (isNil "jmfsb_adapter_alive_fnc_commanders") exitWith {};
        {
            _x params ["_side", "_ctype"];
            GVAR(sideControl) set [str _side, _ctype];
        } forEach (call jmfsb_adapter_alive_fnc_commanders);
        INFO_1("body intel by side: %1",GVAR(sideControl));

        // THE TALLY IS WAR STATE. Banked items, the hint tier and the ids
        // already hinted ride in ALiVE's persistence beside the profiles and
        // objectives they point at, so a campaign that reloads its war does
        // not reload it with the intel economy reset to zero. Loaded once
        // here; written wherever they change.
        if (!isNil "jmfsb_adapter_alive_fnc_getData") then {
            private _banked = [QGVAR(banked)] call jmfsb_adapter_alive_fnc_getData;
            if (!isNil "_banked") then {
                if (_banked isEqualType 0) then {
                    localNamespace setVariable [QGVAR(banked), _banked];
                    missionNamespace setVariable [QGVAR(banked), _banked, true];
                };
            };
            private _tier = [QGVAR(hintTier)] call jmfsb_adapter_alive_fnc_getData;
            if (!isNil "_tier") then { if (_tier isEqualType 0) then { localNamespace setVariable [QGVAR(hintTier), _tier] } };
            private _hinted = [QGVAR(hintedIds)] call jmfsb_adapter_alive_fnc_getData;
            if (!isNil "_hinted") then { if (_hinted isEqualType []) then { localNamespace setVariable [QGVAR(hintedIds), _hinted] } };
            private _b = localNamespace getVariable [QGVAR(banked), 0];
            private _t = localNamespace getVariable [QGVAR(hintTier), 0];
            private _n = count (localNamespace getVariable [QGVAR(hintedIds), []]);
            INFO_3("intel tally restored: banked %1, tier %2, %3 hinted",_b,_t,_n);
        };
    }] call EFUNC(adapter_alive,whenReady);

    // A deposit is banked by FUNC(srvDeposit), reached by remoteExec: the
    // server counts the man's own intel (review S7).
};

// BODY INTEL, ON EVERY MACHINE (review B20): killed fires only where the man
// is local, so AI on a headless client needs the handler there. The decision
// is the server's - FUNC(onBodyKilled) sends it on.
["CAManBase", "killed", {[_this select 0] call FUNC(onBodyKilled)}] call CBA_fnc_addClassEventHandler;
