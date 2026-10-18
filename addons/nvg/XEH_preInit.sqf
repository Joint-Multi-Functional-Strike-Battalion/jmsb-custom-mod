#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// hmd class -> [mask texture, eye cups] or [] (not a JMSB full-screen goggle),
// so each goggle's config is walked once. See FUNC(maskTexture).
GVAR(maskCache) = createHashMap;

// After the cache: the full-screen setting's change script reads it.
#include "initSettings.inc.sqf"

[
    QGVAR(ACE),
    "CHECKBOX",
    ["Use ACE color preset", "Enable if using ACE"],
    COMPONENT_NAME,
    false,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(Effect),
    "LIST",
    [
        "NVG Effect",
        "Green Phosphor (no effect).\nModern Warfare (greenish tint WP)\nWhite Phosphor (White Phosphor)"
    ],
    COMPONENT_NAME,
    [
        [
            "",
            "gpEffect",
            "wpEffect",
            "mwEffect",
            "afEffect",
            "ofEffect",
            "rfEffect"
        ],
        [
            "None",
            "Green Phosphor",
            "White Phosphor",
            "Modern Warfare",
            "Amber Filter",
            "Orange Filter",
            "Red Filter"
        ],
        0
    ],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(Blacklist),
    "EDITBOX",
    ["Blacklisted NVG classnames", "Separate classnames with commas. Example: className1, className2, className3"],
    COMPONENT_NAME,
    "",
    true
] call CBA_fnc_addSetting;

ADDON = true;
