#include "script_component.hpp"
/*
 * Author: YonV
 * Whether ALiVE's multispawn is restoring gear on respawn, in which case
 * jmfsb's own respawn path must leave the loadout alone.
 *
 * Two systems dressing the same respawned player is how a man ends up
 * naked: each one strips before it dresses, and whichever runs second
 * strips what the first put on. ALiVE publishes its choice
 * (sup_multispawn fnc_multispawn.sqf:118, 181); this reads it.
 *
 * Arguments: None
 *
 * Return Value:
 * ALiVE restores gear <BOOL>
 *
 * Public: Yes
 */

missionNamespace getVariable ["ALiVE_sup_multispawn_RESPAWN_WITH_GEAR", false]
