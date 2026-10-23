#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// --- SERVER STATE. The maps exist on every machine so a read never meets
// nil; only the server fills them.
GVAR(rfEmitters) = [];              // RF's listener snapshot, this RF tick
GVAR(firstSeen) = createHashMap;    // RF node id -> time first heard
GVAR(lastTx) = createHashMap;       // RF node id -> time it last carried traffic
GVAR(lastEmitters) = createHashMap; // emitter id -> emitter, as of the last DF tick
GVAR(jammers) = createHashMap;      // jammer id -> jammer (FUNC(jamSet))
GVAR(jamAutoAt) = 0;                // when AUTO jammers are next looked at (FUNC(jamAuto))
GVAR(jamPowerAt) = -1;              // when the power systems were last run (FUNC(jamPower))
GVAR(external) = createHashMap;     // emitter id -> [object, bands, dBm, intent, side] (FUNC(addEmitter))
GVAR(nextExternal) = 0;
GVAR(decoys) = createHashMap;       // RF node id -> [prop, operator uid, battery out at]
GVAR(nextDecoy) = 0;
GVAR(tracks) = createHashMap;       // side -> track id -> track
GVAR(trackIndex) = createHashMap;   // "side|emitter id" -> track id
GVAR(nextTrack) = 0;
GVAR(threats) = createHashMap;      // player uid -> [[time, kind, detail, advice], ...]
GVAR(dfOnYouAt) = createHashMap;    // emitter id -> time DF ON YOU was last told
GVAR(spotTold) = createHashMap;     // "uid|jammer id" -> time SPOT JAM was last told
GVAR(spoof) = createHashMap;        // player uid / AI man's hash -> [drift m, heading, warned, unit, is player]
GVAR(spoofNodes) = createHashMap;   // group hash -> [group, spoofed until, hacker side] (FUNC(spoofNode))
GVAR(aiSets) = createHashMap;       // group hash -> [time, man, profile] (FUNC(aiSet))
GVAR(aiDispatchAt) = createHashMap; // side -> time it last sent a drone or QRF to a fix (FUNC(aiReact))
GVAR(aiSide) = "";                  // the enemy side whose AI runs EW, as RF writes it (FUNC(tick))
GVAR(aiSideAt) = -AI_SET_REFRESH_S; // when it was last worked out
GVAR(sent) = createHashMap;         // client id -> the slice it was last sent

// --- CLIENT STATE. His slice (FUNC(receiveSlice)) and the app's own choices.
GVAR(slice) = [];
GVAR(mine) = [];
GVAR(tab) = TAB_OVERVIEW;
GVAR(mapLayer) = true;
GVAR(decoyProfile) = "handheld";
GVAR(pfh) = -1;
GVAR(iconFix) = getText (configFile >> "CfgMarkers" >> MAP_MARKER_FIX >> "icon");
GVAR(iconJam) = getText (configFile >> "CfgMarkers" >> MAP_MARKER_JAM >> "icon");

// THE EW TILE, offered to tacpad_apps' band (FUNC(tile)).
if (!isNil QEGVAR(tacpad_apps,tileProviders)) then {
    EGVAR(tacpad_apps,tileProviders) set [APP_ID, FUNC(tile)];
};

#include "initSettings.inc.sqf"

ADDON = true;
