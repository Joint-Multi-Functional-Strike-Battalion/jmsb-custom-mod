#include "script_component.hpp"

// EVERY MACHINE: a manual reading is taken where the patient is local, because
// that is the only place his vitals are exact - see FUNC(measureLocal). AI
// patients live on the server or a headless client, so this is not
// interface-only.
[QGVAR(measure), LINKFUNC(measureLocal)] call CBA_fnc_addEventHandler;

if (!hasInterface) exitWith {};

// A medic's hand check, heard on the medic's own machine. ACE raises it after
// every treatment - the misspelling is ACE's. Without ACE it never fires.
["ace_treatmentSucceded", LINKFUNC(recordCheck)] call CBA_fnc_addEventHandler;

// The MEDIC tile opens this - see EFUNC(tacpad_apps,tileData).
[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);
