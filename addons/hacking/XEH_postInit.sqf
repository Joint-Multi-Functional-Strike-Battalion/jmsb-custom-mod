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

// Server-authoritative silent removal of a hacked drone (+ its virtual crew).
if (isServer) then {
    [QGVAR(deleteDrone), {
        private _drone = _this;
        if (isNull _drone) exitWith {};
        { deleteVehicle _x } forEach (crew _drone);
        deleteVehicle _drone;
    }] call CBA_fnc_addEventHandler;
};

// --- Phase 2 admin test commands + HUD placement ---------------------------



// Product render + result, one event each. The side filter lives on the
// receiving client (see FUNC(renderProduct)), so the enemy never draws them.
[QGVAR(render), { _this call FUNC(renderProduct) }] call CBA_fnc_addEventHandler;

[QGVAR(pickResult), {
    params ["_msg", "_side"];
    if (!hasInterface || {side group ACE_player isNotEqualTo _side}) exitWith {};
    ["Hack", _msg, [0.914, 0.651, 0.235, 1]] call EFUNC(notify,notify);
}] call CBA_fnc_addEventHandler;

// RF REACH: a client with the HACK board open asks, the server answers that
// client only. See FUNC(rfReach).
[QGVAR(rfReached), {
    params [["_list", [], [[]]]];
    GVAR(rfReach) = _list;
    GVAR(rfReachTime) = CBA_missionTime;
}] call CBA_fnc_addEventHandler;

if (isServer) then {
    [QGVAR(rfReachAsk), {
        params [["_unit", objNull, [objNull]]];
        if (isNull _unit) exitWith {};
        [QGVAR(rfReached), [[_unit] call FUNC(rfReach)], _unit] call CBA_fnc_targetEvent;
    }] call CBA_fnc_addEventHandler;

    [QGVAR(pick), { _this call FUNC(serverPick) }] call CBA_fnc_addEventHandler;
    [QGVAR(remoteFail), { _this call FUNC(remoteHackFail) }] call CBA_fnc_addEventHandler;

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

    // Scanner alarms live here so they fire with the setter gone. Clearing
    // empties the list; each armed alarm's waiter notices its id missing and
    // stands down by itself.
    [QGVAR(alarmAdd), { _this call FUNC(alarmAdd) }] call CBA_fnc_addEventHandler;
    [QGVAR(alarmsClear), {
        if (GVAR(alarms) isEqualTo []) exitWith {};
        GVAR(alarms) = [];
        publicVariable QGVAR(alarms);
    }] call CBA_fnc_addEventHandler;
    // A witnessed pop hack: the nearest settlement remembers. Who keeps that
    // ledger and how is the adapter's business - this says what happened and
    // where, on the server, because that is where the population system reads
    // it. Without the adapter answering nobody is keeping score, so the hack is
    // logged as witnessed and goes otherwise unremarked - which is what a
    // mission with no civilian model can honestly do with it.
    [QGVAR(popSeen), {
        params [["_pos", [], [[]]], ["_sideStr", "", [""]]];
        if (_pos isEqualTo [] || _sideStr isEqualTo "") exitWith {};
        if (isNil QEFUNC(adapter_alive,bumpHostility)) exitWith {
            INFO_2("pop hack witnessed at %1 by a civilian hostile to %2",mapGridPosition _pos,_sideStr);
        };

        private _now = [_pos, _sideStr, POP_HOSTILITY_BUMP] call EFUNC(adapter_alive,bumpHostility);
        if (_now < 0) exitWith {};

        INFO_2("pop hack witnessed - settlement hostility toward %1 now %2",_sideStr,_now);
    }] call CBA_fnc_addEventHandler;

    // One alarm, by id. The waiter notices its id gone and stands down, the
    // same way a clear works - deleting is a clear of one.
    [QGVAR(alarmDelete), {
        params [["_id", -1, [0]]];
        private _i = GVAR(alarms) findIf { (_x select 0) == _id };
        if (_i == -1) exitWith {};
        GVAR(alarms) deleteAt _i;
        publicVariable QGVAR(alarms);
    }] call CBA_fnc_addEventHandler;
};

// The server-wide ring. Every machine gets the event; FUNC(alarmRing) is what
// decides whether this particular pocket has a phone in it.
[QGVAR(alarmRing), { _this call FUNC(alarmRing) }] call CBA_fnc_addEventHandler;

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
        [QGVAR(alarmsClear), []] call CBA_fnc_serverEvent;
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
            [QGVAR(alarmAdd), [_min * 60, name player]] call CBA_fnc_serverEvent;
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
            [QGVAR(alarmRing), [name _caller]] call CBA_fnc_globalEvent;
            "rang every scanner on the server"
        };
        case (_arg isEqualTo "clear"): {
            [QGVAR(alarmsClear), []] call CBA_fnc_serverEvent;
            "cleared all armed alarms"
        };
        case (_arg isNotEqualTo ""): {
            [QGVAR(alarmAdd), [(parseNumber _arg) * 60, name _caller]] call CBA_fnc_serverEvent;
            format ["armed an alarm for %1 min", parseNumber _arg]
        };
        default {
            private _a = missionNamespace getVariable [QGVAR(alarms), []];
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

// The hunt products render through the console's own dispatcher, so they obey
// the same lifetime, alpha and fade settings as every other product.
[QGVAR(product), {
    _this call FUNC(renderProduct);
}] call CBA_fnc_addEventHandler;

// --- the intel tally: deposit -> counter -> hint ---------------------------
if (isServer) then {
    GVAR(banked) = 0;
    GVAR(hintSide) = sideUnknown;

    // WHOSE WAR IS WHOSE, cached once. Which side yields phones and which
    // yields radios is the commanders' controltype, read through the adapter -
    // never a faction list kept here. Commanders do not change mid-mission, so
    // this is built once and read on every death.
    GVAR(sideControl) = createHashMap;
    [QEGVAR(adapter_alive,ready), {
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
            if (!isNil "_banked") then { if (_banked isEqualType 0) then { GVAR(banked) = _banked } };
            private _tier = [QGVAR(hintTier)] call jmfsb_adapter_alive_fnc_getData;
            if (!isNil "_tier") then { if (_tier isEqualType 0) then { missionNamespace setVariable [QGVAR(hintTier), _tier] } };
            private _hinted = [QGVAR(hintedIds)] call jmfsb_adapter_alive_fnc_getData;
            if (!isNil "_hinted") then { if (_hinted isEqualType []) then { missionNamespace setVariable [QGVAR(hintedIds), _hinted] } };
            private _t = missionNamespace getVariable [QGVAR(hintTier), 0];
            private _n = count (missionNamespace getVariable [QGVAR(hintedIds), []]);
            INFO_3("intel tally restored: banked %1, tier %2, %3 hinted",GVAR(banked),_t,_n);
        };
    }] call CBA_fnc_addEventHandler;


    ["CAManBase", "killed", LINKFUNC(onBodyKilled)] call CBA_fnc_addClassEventHandler;

    [QGVAR(deposited), {
        params [["_n", 1, [0]], ["_by", objNull, [objNull]]];

        GVAR(banked) = GVAR(banked) + _n;
        // Whoever is banking is who the hints are drawn for.
        if (!isNull _by) then { GVAR(hintSide) = side group _by };

        ["Intel Drop", format ["%1 item(s) banked - %2 of %3.",
            _n, GVAR(banked), GVAR(perHint)]] call EFUNC(notify,broadcast);

        // A batch at a time, so banking twenty at once pays out twice. The
        // deposit's own position rides along - the hint points at the nearest
        // piece of the network, so where you bank decides what you learn about.
        private _at = if (isNull _by) then {[]} else {getPosATL _by};
        while {GVAR(banked) >= GVAR(perHint)} do {
            GVAR(banked) = GVAR(banked) - GVAR(perHint);
            if !([_at] call FUNC(intelHint)) exitWith {
                // Nothing to point at: keep the deposits rather than burning
                // them on a hint that never drew.
                GVAR(banked) = GVAR(banked) + GVAR(perHint);
            };
        };
        if (!isNil "jmfsb_adapter_alive_fnc_setData") then {
            [QGVAR(banked), GVAR(banked)] call jmfsb_adapter_alive_fnc_setData;
        };
    }] call CBA_fnc_addEventHandler;
};
