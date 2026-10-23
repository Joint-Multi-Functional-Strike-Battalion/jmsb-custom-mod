// WHY DOES THE 157 SPITFIRE SHOW NO RETICLE AND NO XM157 - run in the debug console (LOCAL EXEC), then look
// through the scope within 5 seconds and hold it there.
//
// The 157 Spitfires (addons/compatibility/xm157_spitfire, tools/gen_spitfire_157.py) are CBA scripted optics with
// ACE's XM157 display (weaponInfoType "ace_xm157_info"). That display draws the reticle and the 157 data, and CBA
// hides all of it whenever it decides the optic is not in use. This says which link of that chain is missing:
//   - the optic on the gun and whether it is one of ours
//   - the camera view (GUNNER = looking through it) and the optic mode (the RMR red dot carries no XM157 by design)
//   - CBA's "Use PIP optics" and the game's PIP video setting (jmfsb's cba_settings default the CBA one to OFF)
//   - whether CBA loaded the scripted-optic display at all, and whether the engine shows its optic element (154)
//
// Paste, Local Exec, aim, read the hint (and the RPT: one [JMSB-OPTIC] line per item, and the clipboard).

[] spawn {
    hint "JMSB optic check: look through the scope now (5 s)";
    sleep 5;
    private _optic = (primaryWeaponItems player) param [2, ""];
    private _cfg = configFile >> "CfgWeapons" >> _optic;
    private _display = uiNamespace getVariable ["cba_optics_ScriptedOpticDisplay", displayNull];
    private _lines = [
        ["optic", _optic],
        ["ours (157)", (_optic find "_157") > -1],
        ["weaponInfoType", getText (_cfg >> "weaponInfoType")],
        ["CBA_ScriptedOptic block", isClass (_cfg >> "CBA_ScriptedOptic")],
        ["cameraView", cameraView],
        ["optics mode (getOpticsMode)", player getOpticsMode 1],
        ["cba_optics_usePipOptics", missionNamespace getVariable ["cba_optics_usePipOptics", "unset"]],
        ["isPiPEnabled (video)", isPiPEnabled],
        ["CBA scripted display loaded", !isNull _display],
        ["engine optic element 154 shown", if (isNull _display) then {"no display"} else {ctrlShown (_display displayCtrl 154)}],
        ["CBA thinks optic in use", missionNamespace getVariable ["cba_optics_IsUsingOptic", "unset"]],
        ["ace_xm157 loaded", isClass (configFile >> "CfgPatches" >> "ace_xm157")],
        ["jmfsb 157 compat loaded", isClass (configFile >> "CfgPatches" >> "jmfsb_compatibility_xm157_spitfire")]
    ];
    private _text = _lines apply {format ["%1: %2", _x select 0, _x select 1]};
    {diag_log text format ["[JMSB-OPTIC] %1", _x]} forEach _text;
    copyToClipboard (_text joinString endl);
    hint (_text joinString "\n");
};
