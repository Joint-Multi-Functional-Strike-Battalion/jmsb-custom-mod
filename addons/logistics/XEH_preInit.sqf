#include "script_component.hpp"

ADDON = false;

// PREP'd AGAIN AT preInit, AND THIS IS NOT REDUNDANT.
//
// CBA's preStart dispatch runs inside `with uiNamespace do` - the mission
// namespace does not exist that early - and CBA_fnc_compileFunction stores each
// function in uiNamespace, then copies it into missionNamespace. That copy is
// thrown away when a mission loads. An addon that PREPs ONLY at preStart
// therefore has NO functions once a mission is running.
//
// That was the whole reason every function in these eleven addons came back
// "Undefined variable" in game while the config, the packing and the handlers
// were all provably correct. 73 of jmfsb's other 79 addons already do this;
// these were the exception because they were written from scratch in one go.
#include "XEH_PREP.hpp"

// ACE's drag and carry setters have local effect. FUNC(doSupplyCrate) sends
// FUNC(crateDraggable) by remoteExec with the crate as its JIP id, so every
// machine, joiners too, can drag and carry the crate (review L3) - no CBA
// event any client could raise on any object (review R1).

ADDON = true;
