#include "script_component.hpp"

// The old EGVAR(main,jmfsb_enabled) master gate stood here. Nothing in the
// repo, the settings or the mission ever WROTE that variable, so the isNil
// arm always fired and everything below this line was dead. Removed.

// The move itself happens on the SERVER. A player pressing the action is not
// the owner of the other players being loaded, and moveInCargo wants the unit
// local - so the action asks the server and the server does the seating,
// sending each move to the machine that owns that player. The ask is a
// remoteExec to FUNC(board), which checks the presser - not the CBA event it
// was, which any client could raise for any point from anywhere (review R1).
