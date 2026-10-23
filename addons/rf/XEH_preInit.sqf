#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// THE REGISTRY. Server-authoritative; the maps exist on every machine so a
// read never meets nil, but only the server fills them.
GVAR(nodes) = createHashMap;        // node id -> Node
GVAR(nets) = createHashMap;         // net id -> Net
GVAR(links) = createHashMap;        // net id -> source id -> peer id -> [quality, hops, lastHop]
GVAR(edgeCache) = createHashMap;    // "a|b|band" -> [posA, posB, time, loss dB]
GVAR(sent) = createHashMap;         // client id -> the slice it was last sent
GVAR(prevLinks) = createHashMap;    // "node|net" -> links last announced
GVAR(debugEdges) = [];
GVAR(sky) = createHashMap;          // node id -> [antenna ASL, time, open sky] (SAT nodes)
GVAR(satFade) = 0;                  // this tick's SAT rain fade, dB

// THE HOOKS. EW (and anything else) registers here; RF never knows what EW is.
GVAR(noiseSources) = [];            // code: [posASL, band, net] -> [[dBm, spreadApplies], ...]
GVAR(listeners) = [];               // code: [emitters] once per tick

// THE CLIENT SLICE, as received, and its index for jmfsb_rf_fnc_link/reach.
GVAR(slice) = [];
GVAR(sliceIndex) = createHashMap;   // "node|net" -> [peer id -> [quality, hops, lastHop], reach ids]

// THE PROFILES, from the one table in script_component.hpp.
GVAR(profiles) = createHashMap;
{
    _x params ["_id", "_bands", "_tx", "_sens", "_gain", "_hops", "_relay", "_spread", "_battery"];
    GVAR(profiles) set [_id, createHashMapFromArray [
        ["id", _id],
        ["bands", _bands],
        ["txPowerDbm", _tx],
        ["rxSensDbm", _sens],
        ["antennaGainDb", _gain],
        ["pattern", RF_PATTERN_OMNI],
        ["sectorDeg", 0],
        ["hopLimit", _hops],
        ["relayCapable", _relay],
        ["spreadGainDb", _spread],
        ["batteryWh", _battery]
    ]];
} forEach RF_PROFILES;

// Item / bag class -> its RF profile ("" = not a set), FUNC(itemProfile).
GVAR(itemProfiles) = createHashMap;

GVAR(bands) = createHashMap;
// Band -> [[[low, high] MHz, ...], channel MHz] (RF_BAND_MHZ), and the
// frequencies already worked out, "id|band" -> MHz (FUNC(netFreq)).
GVAR(bandMhz) = createHashMap;
{
    GVAR(bandMhz) set [_x select 0, [_x select 1, _x select 2]];
} forEach RF_BAND_MHZ;
GVAR(freqs) = createHashMap;
#include "initSettings.inc.sqf"
[] call FUNC(updateBands);

ADDON = true;
