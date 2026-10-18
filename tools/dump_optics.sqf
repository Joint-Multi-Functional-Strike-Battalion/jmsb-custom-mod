// Dump every optic's class tree, for tools/gen_nvg_optics.py (user,
// 2026-10-17: "make all scopes in the arsenal nvg compatible").
//
//   RUN IN THE DEBUG CONSOLE (Eden or in-mission) with the JMSB modset loaded.
//   Paste the whole file, execute. The lines go to the RPT and the clipboard;
//   paste the clipboard into tools/_dump/optics.txt (or point the generator at
//   the .rpt), then run  python tools/gen_nvg_optics.py
//
// WHY A GAME DUMP. Adding "NVG" to a scope's vision modes is a config patch,
// and a patch has to restate every class on the way down - the optic, its
// ItemInfo, its OpticsModes, the mode - with exactly the parent each was
// written with, or it re-parents them. Mod and DLC configs are binarized or
// encrypted; the game is the one place all of them can be read.
//
// Every optic in the load order - obfuscated PBOs included, which
// tools/optics_from_pbos.py cannot read off disk. One line per class on the
// way from each optic up to the root:
//   CLASS;name;parent;mod;patch|patch|...
// and one per nested class on the optics path that the class writes ITSELF
// (not inherits) - its path, its parent, and for a mode whether it writes its
// own visionMode and what that is:
//   NEST;owner;ItemInfo;parent
//   NEST;owner;ItemInfo/OpticsModes;parent
//   NEST;owner;ItemInfo/OpticsModes/<mode>;parent;<0|1>;Normal|NVG|Ti

private _out = [];
private _seen = createHashMap;

private _fnc_parent = {
    params ["_cfg"];
    private _base = inheritsFrom _cfg;
    [configName _base, ""] select (isNull _base)
};
private _fnc_own = {
    params ["_cfg"];
    (configProperties [_cfg, "true", false]) apply {configName _x}
};

{
    private _cfg = _x;
    while {!isNull _cfg && {!(configName _cfg in _seen)}} do {
        private _name = configName _cfg;
        _seen set [_name, true];
        _out pushBack format ["CLASS;%1;%2;%3;%4", _name, [_cfg] call _fnc_parent, configSourceMod _cfg, (configSourceAddonList _cfg) joinString "|"];

        private _info = _cfg >> "ItemInfo";
        if ("ItemInfo" in ([_cfg] call _fnc_own) && {isClass _info}) then {
            _out pushBack format ["NEST;%1;ItemInfo;%2", _name, [_info] call _fnc_parent];
            private _modes = _info >> "OpticsModes";
            if ("OpticsModes" in ([_info] call _fnc_own) && {isClass _modes}) then {
                _out pushBack format ["NEST;%1;ItemInfo/OpticsModes;%2", _name, [_modes] call _fnc_parent];
                {
                    private _mode = _x;
                    private _ownVision = "visionMode" in ([_mode] call _fnc_own);
                    _out pushBack format [
                        "NEST;%1;ItemInfo/OpticsModes/%2;%3;%4;%5",
                        _name, configName _mode, [_mode] call _fnc_parent,
                        [0, 1] select _ownVision,
                        (getArray (_mode >> "visionMode")) joinString "|"
                    ];
                } forEach (configProperties [_modes, "isClass _x", false]);
            };
        };

        _cfg = inheritsFrom _cfg;
    };
} forEach ("getNumber (_x >> 'ItemInfo' >> 'type') == 201" configClasses (configFile >> "CfgWeapons"));

// AND THE FULL TREE of the classes named below (any part of a class name or a
// display name, any case) - what a generator building ON a mod's classes needs
// (first use: the 157 versions of SPS Equipment's Vortex Spitfires, whose PBO
// is obfuscated - nothing outside the game should unpack it):
//   CLS;<path>;<parent>;<own 0|1>
//   VAL;<path>;<name>;<own 0|1>;<value as str>
private _patterns = ["spitfire"];
private _fnc_walk = {
    params ["_cfg", "_path", "_own"];
    private _base = inheritsFrom _cfg;
    _out pushBack format ["CLS;%1;%2;%3", _path, [configName _base, ""] select (isNull _base), [0, 1] select _own];
    private _mine = [_cfg] call _fnc_own;
    {
        private _name = configName _x;
        private _isOwn = _name in _mine;
        if (isClass _x) then {
            [_x, _path + "/" + _name, _isOwn] call _fnc_walk;
        } else {
            private _value = if (isArray _x) then {getArray _x} else {if (isNumber _x) then {getNumber _x} else {getText _x}};
            _out pushBack format ["VAL;%1;%2;%3;%4", _path, _name, [0, 1] select _isOwn, str _value];
        };
    } forEach configProperties [_cfg, "true", true];
};

{
    private _name = toLower configName _x;
    private _display = toLower getText (_x >> "displayName");
    if (_patterns findIf {(_name find _x) >= 0 || {(_display find _x) >= 0}} >= 0) then {
        [_x, "CfgWeapons/" + configName _x, true] call _fnc_walk;
    };
} forEach ("true" configClasses (configFile >> "CfgWeapons"));

{diag_log text ("OPTICS;" + _x)} forEach _out;
copyToClipboard (_out joinString endl);
hint format ["%1 lines - on the clipboard and in the RPT", count _out];
