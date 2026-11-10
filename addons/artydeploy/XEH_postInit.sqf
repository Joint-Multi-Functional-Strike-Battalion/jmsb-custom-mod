#include "script_component.hpp"

// THE SERVER DOES THE PLACING, whoever pressed the key: the baseplate, the gun,
// and taking them away again (FUNC(preDeploy), FUNC(deploy), FUNC(undeploy),
// FUNC(clearSpot)). The driver's machine only runs the progress bar and sends
// each step by remoteExec, so the server can check the driver named is the
// sender's own unit (review S6) - no CBA event: those carry no sender.

if (!hasInterface) exitWith {};

// The driver's ACE self-interaction on every carrier class.
[] call FUNC(addActions);
