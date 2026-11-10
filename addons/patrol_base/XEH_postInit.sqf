#include "script_component.hpp"

// Player-facing "Establish Patrol Base" action + Zeus module registration.
// The Zeus kit drop, the build and the unbuild reach the server by remoteExec
// (FUNC(dropKits), FUNC(serverBuild), FUNC(serverUnbuild)), each checking
// its sender there (review S7) - no CBA event handler.
if (hasInterface) then {
    [] call FUNC(initPlayer);
    [] call FUNC(addZeusModule);
};
