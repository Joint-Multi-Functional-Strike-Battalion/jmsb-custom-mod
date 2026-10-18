#include "script_component.hpp"
/*
 * Author: BaerMitUmlaut, CPL.Brostrom.A
 * This function setup radios and apply radio channel to them on server and player.
 * Needs to be in init.sqf
 *
 * Arguments:
 * Nothing
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call ymf_fnc_gear_setupRadios
 *
 * Public: No
 */

if (!EGVAR(Patches,usesACRE) && !EGVAR(Patches,usesTFAR)) exitWith {};
if (!EGVAR(Settings,enableRadios)) exitWith {};

// ACRE
if (EGVAR(patches,usesACRE)) exitWith {
    if (count allMissionObjects "acre_api_basicMissionSetup" > 0)  exitWith {};
    if (count allMissionObjects "acre_api_nameChannels" > 0)       exitWith {};

    SHOW_INFO("GearRadio","Setting up ACRE preset...");

    private _noProgram = jmfsbFR_radio_acreNoProgram; // config: radios that work differently and don't need programming
    // NB: a radio with no label field gets frequencies only - see jmfsbFR_radio_acreLabelField

    // remove non-programmable radios from the programming list
    private _srradios = []; private _mrradios = []; private _lrradios = [];
    {
        if (!(_x in _noProgram)) then {_srradios pushBackUnique _x};
    } forEach jmfsbFR_radio_srRadios;
    {
        if (!(_x in _noProgram)) then {_mrradios pushBackUnique _x};
    } forEach jmfsbFR_radio_mrRadios;
    {
        if (!(_x in _noProgram)) then {_lrradios pushBackUnique _x};
    } forEach jmfsbFR_radio_lrRadios;

    // define unused channels
    private _usedSRchannels = []; private _usedMRchannels = []; private _usedLRchannels = [];
    {_usedSRchannels pushBackUnique (_x#0);} forEach jmfsbFR_radio_srChannels;
    {_usedMRchannels pushBackUnique (_x#0);} forEach jmfsbFR_radio_mrChannels;
    {_usedLRchannels pushBackUnique (_x#0);} forEach jmfsbFR_radio_lrChannels;

    // SETUP CONFIG ///////////////////////////////////////////////////////////////////////////////////

    private _labelField = jmfsbFR_radio_acreLabelField; // config: which preset field holds the channel label, per radio

    {
        private _radioClass = _x;
        private _chanList = [];
        private _usedList = [];
        private _power = -1;
        if (_radioClass in _srradios) then {
            _chanList = jmfsbFR_radio_srChannels;
            _usedList = _usedSRchannels;
            _power = jmfsbFR_radio_srPower;
        };
        if (_radioClass in _mrradios) then {
            _chanList = jmfsbFR_radio_mrChannels;
            _usedList = _usedMRchannels;
            _power = jmfsbFR_radio_mrPower;
        };
        if (_radioClass in _lrradios) then {
            _chanList = jmfsbFR_radio_lrChannels;
            _usedList = _usedLRchannels;
            _power = jmfsbFR_radio_lrPower;
        };
        // get the field property relevant to the radio
        private _field = "";
        {
            if (_radioClass == _x#0) then {_field = _x#1};
        } forEach _labelField;

        // GROW THE PRESET IF THE PLAN NEEDS MORE CHANNELS THAN IT HOLDS.
        // ACRE ships the 148 with 32 channels (its 152 and 117F get 100), and
        // acre_api_fnc_setPresetChannelField refuses a channel the preset does
        // not already have - so a plan that runs past 32 silently loses its tail.
        //
        // A preset's channel list is a plain ARRAY OF ACRE HASHES (their
        // HASHLIST_* macros are [] / pushBack / select - main\script_macros.hpp),
        // and a hash is a namespace. So a new channel is a deep copy of an
        // existing one, which carries every field ACRE expects already filled in;
        // the loop below then writes frequency, power and label over it.
        private _highest = 0;
        {_highest = _highest max (_x#0)} forEach _chanList;

        if (_highest > 0 && {!isNil "acre_main_fnc_fastHashCopy"}) then {
            private _preset = [_radioClass, "default"] call acre_api_fnc_getPresetData;
            if (!isNil "_preset") then {
                private _channels = _preset getVariable ["channels", []];
                private _had = count _channels;
                if (_had > 0 && _had < _highest) then {
                    private _template = _channels select 0;
                    for "_i" from _had to (_highest - 1) do {
                        _channels pushBack (_template call acre_main_fnc_fastHashCopy);
                    };
                    _preset setVariable ["channels", _channels];
                    INFO_3("GearRadio","%1 preset grown from %2 to %3 channels",_radioClass,_had,count _channels);
                };
            };
        };

        {
            private _channel = _x#0;
            private _freq = _x#1;
            private _label = toUpper (_x#2); 

            // set frequencies
            [_radioClass, "default", _channel, "frequencyTX", _freq] call acre_api_fnc_setPresetChannelField;
            [_radioClass, "default", _channel, "frequencyRX", _freq] call acre_api_fnc_setPresetChannelField;

            if (_field != "") then { // radios with no label field (343, SEM52) are freq-only

                // // if the radio is a 148, append channel num to label (isn't on display)
                // if (_radioClass == "ACRE_PRC148") then {
                //     _label = format ["0%2-%1", _label, _channel];
                // };

                // set label
                [_radioClass, "default", _channel, _field, _label] call acre_api_fnc_setPresetChannelField;

            };
        } forEach _chanList;

        // how many channels this radio has - both sweeps below need it
        private _numChannels = 100;
        { if (_radioClass == _x#0) exitWith {_numChannels = _x#1}; } forEach jmfsbFR_radio_acreChannelCount;

        // NEVER PAST WHAT THE PRESET HOLDS. With no count in the plan the default
        // is 100, and the 148's preset has 64: both sweeps below wrote channels
        // 65-100 and ACRE logged a warning for every one of them, twice
        // (2026-10-17 RPT). The preset - grown above if the plan needed it - is
        // the radio's real channel count.
        private _presetNow = [_radioClass, "default"] call acre_api_fnc_getPresetData;
        if (!isNil "_presetNow") then {
            private _have = count (_presetNow getVariable ["channels", []]);
            if (_have > 0) then {_numChannels = _numChannels min _have};
        };

        // TRANSMIT POWER IS SWEPT ACROSS EVERY CHANNEL (2026-09-01), not only
        // the ones the plan names. Power is a per-channel preset field, and
        // writing it inside the plan loop left two holes: a man who turned to
        // any channel the plan did not list transmitted at ACRE stock, and a
        // radio with NO plan at all never had it written once. The second hole
        // is the 343 - its block scheme is DERIVED from group_setup rather than
        // listed here (see fn_getRadioChannel), so jmfsbFR_radio_srPower was
        // simply inert. -1 still means "leave ACRE stock".
        // A CHANNEL MAY NAME ITS OWN POWER (2026-09-02), as a fourth element in
        // the plan row: [channel, freq, name, mW]. That is how one radio class
        // carries two radios' worth of behaviour - ACRE stores power per
        // CHANNEL and its presets are per CLASS, so a low-power set and a
        // satcom set cannot be two different 117Fs without cloning the radio.
        // They are two channel sets on the same one, and the rack a man is
        // looking at decides which he is on. Anything the plan does not name
        // stays at the tier's power.
        if (_power > 0) then {
            for "_i" from 1 to _numChannels do {
                private _chanPower = _power;
                {
                    if ((_x select 0) isEqualTo _i) exitWith {_chanPower = _x param [3, _power]};
                } forEach _chanList;
                [_radioClass, "default", _i, "power", _chanPower] call acre_api_fnc_setPresetChannelField;
            };
        };

        // THE CHANNEL GROUPS - the 148's GR knob (2026-09-02). A group is a
        // list of channel indices and nothing more, so this carves the flat
        // plan into banks a man can turn between: four channels to a group,
        // one group to a platoon. ACRE's own default is two groups of sixteen.
        //
        // Only the SR tier is given one, and only when the mission writes the
        // list; every other radio keeps ACRE's groups. Indices go over the wire
        // 0-BASED - the plan is written 1-based like every other channel number
        // in this file, and converted here rather than in the mission.
        if (_radioClass in _srradios && {!isNil "jmfsbFR_radio_srGroups"} && {jmfsbFR_radio_srGroups isNotEqualTo []}) then {
            private _preset = [_radioClass, "default"] call acre_api_fnc_getPresetData;
            if (isNil "_preset") then {
                SHOW_WARNING_1("GearRadio","%1 has no default preset - channel groups not written",_radioClass);
            } else {
                private _groups = [];
                {
                    _x params ["_label", "_chans"];
                    _groups pushBack [_label, _chans apply {_x - 1}];
                } forEach jmfsbFR_radio_srGroups;

                // ACRE's preset data is a NAMESPACE and getPresetData hands
                // back the live one, so this writes straight into it. That is
                // exactly what ACRE's own HASH_SET macro expands to - spelled
                // out because the macro is theirs and not ours to include, and
                // it saves copying the whole preset back through the API.
                _preset setVariable ["groups", _groups];
                INFO_2("GearRadio","%1 programmed with %2 channel group(s)",_radioClass,count _groups);
            };
        };

        // label unused channels (skipped for freq-only radios like the 343)
        if (_field != "") then {
            for "_i" from 1 to _numChannels do {
                if (!(_i in _usedList)) then {
                    private _label = "";
                    if (_radioClass == "ACRE_PRC148") then {
                        _label = format ["UNUSED-%1", _i];
                    } else {
                        _label = "UNUSED";
                    };
                    [_radioClass, "default", _i, _field, _label] call acre_api_fnc_setPresetChannelField;
                };
            };
        };

    } forEach (_srradios + _mrradios + _lrradios);
};

// TFAR - push the SW/LR channel plans as the side defaults so issued radios inherit them.
// (Per-radio tuning to the player's own net happens in fn_setRadioChannel.)
if (EGVAR(patches,usesTFAR)) exitWith {
    ["west", "sr", jmfsbFR_radio_tfarSrFreqs] call TFAR_fnc_setSideRadioSettings;
    ["west", "lr", jmfsbFR_radio_tfarLrFreqs] call TFAR_fnc_setSideRadioSettings;
    SHOW_INFO("GearRadio","TFAR side radio frequencies set.");
};

SHOW_CHAT_ERROR("GearRadio","Fatal");
