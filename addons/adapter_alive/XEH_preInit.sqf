#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// IS ALiVE EVEN HERE. This lived in jmfsb_init's block of ten mod-presence
// checks - ACE, ACRE, Zen and the rest - and it was the last reference to
// an ALiVE symbol outside this addon, the one thing keeping the adapter-seam
// invariant red. It is a data read about ALiVE, which makes it the adapter's by
// the same rule that brought profileIgnore here.
//
// THE NAME DOES NOT CHANGE. It stays jmfsb_patches_usesAlive so a mission or a
// script reading it carries on working; only the file that sets it moved.
//
// Nothing in the mod reads it today - it is published for missions and for the
// symmetry of that table.
EGVAR(patches,usesAlive) = isClass (configFile >> "CfgPatches" >> "ALiVE_main");

GVAR(ready) = false;
GVAR(aaRegistered) = false;
GVAR(fireSeq) = 0;
// one-shot latch: FUNC(profileObjects) reports an odd profile shape once
GVAR(shapeLogged) = false;

// Placements whose ground could not be attributed to a side - said once each
// by FUNC(taorFor), which some callers ask once a spawn.
GVAR(ownerlessSaid) = [];

ADDON = true;
