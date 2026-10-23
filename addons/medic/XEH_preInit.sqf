#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// WHICH MEDICAL SYSTEM IS LOADED, asked once. Both are optional: without ACE
// medical there is nothing to read and the app says so; without ACM the ACE
// readings still work and the ACM-only lines (devices, airway, chest, rhythm,
// respiration) say ACM NOT LOADED.
GVAR(ace) = isClass (configFile >> "CfgPatches" >> "ace_medical");
GVAR(acm) = isClass (configFile >> "CfgPatches" >> "ACM_circulation");

// The patient whose page is open, objNull for the list. A fresh open from the
// tile starts on the list - the tile may be alerting about someone else - except
// straight after SHOW ON MAP, which sets GVAR(keepPatient) so the tile comes
// back to the man it showed (FUNC(app)).
GVAR(patient) = objNull;
GVAR(keepPatient) = false;

// The refresh loop's handle, a mission variable on purpose: a CBA per-frame
// handler id is only good for the mission that issued it. The app group this
// addon last drew is a control, so it lives in uiNamespace (QGVAR(group),
// set in FUNC(app)) - a control in the mission namespace cannot be serialised.
GVAR(pfh) = -1;

// THE MEDIC TILE, offered to tacpad_apps' band. It answers no tile unless the
// player is a CLS or a medic (FUNC(tile)). That skill check is its gate, not
// the role: role tiles[] lists written before this tile existed never name it,
// and hid it from every medic.
if (!isNil QEGVAR(tacpad_apps,tileProviders)) then {
    EGVAR(tacpad_apps,tileProviders) set [APP_ID, FUNC(tile)];
    EGVAR(tacpad_apps,tileUngated) pushBackUnique APP_ID;
};

ADDON = true;
