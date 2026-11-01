#include "script_component.hpp"

// A manual reading is taken where the patient is local, because that is the
// only place his vitals are exact: the server sends it there by remoteExec
// (FUNC(srvMeasure) -> FUNC(measureLocal)) - no CBA event (review R1).

if (!hasInterface) exitWith {};

// A medic's hand check, heard on the medic's own machine. ACE raises it after
// every treatment - the misspelling is ACE's. Without ACE it never fires.
["ace_treatmentSucceded", LINKFUNC(recordCheck)] call CBA_fnc_addEventHandler;

// The MEDIC tile opens this - see EFUNC(tacpad_apps,tileData).
[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);
