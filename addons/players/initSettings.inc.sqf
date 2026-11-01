// CBA Settings [ADDON: jmfsb_players]
//
// OFF BY DEFAULT, AND THAT IS THE POINT. Reading a squad tag means asking the
// engine for the player's squad, and the engine answers that by resolving the
// squad's logo as well - a file it caches under
// <profile>\Squads\<nick>\<hash>.paa and re-reads every frame it fails to load.
// The 2026-08-31 build put 19,870 "Cannot load texture ...squads\jmfsb\*.paa"
// lines in a 21-minute RPT, one per rendered frame, and every session before it
// had none. Nothing in the mission needs a squad tag badly enough to pay that,
// so the lookup only happens when somebody asks for it.
//
// Turning it on is safe wherever the squad.xml a player is using actually
// resolves; see the addon README.
[
    QGVAR(enableClanTag), "CHECKBOX",
    [
        "Use squad tags in names",
        "Reads each player's squad.xml tag and puts it in front of their name. Off (the default) leaves the profile name untouched and never asks the engine for squad data - which also stops the engine trying to draw a squad logo it may not have on disk."
    ],
    ["JMSB - Mission & Admin", "Players"],
    false,
    true
] call CBA_fnc_addSetting;
