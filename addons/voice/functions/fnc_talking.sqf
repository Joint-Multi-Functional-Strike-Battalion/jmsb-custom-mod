#include "script_component.hpp"
/*
 * Author: JMSB
 * Who the local player hears talking right now, and on which of his nets -
 * himself included while he transmits. Updated every frame and on every
 * pushed key event (fnc_talkSync): others from the speakers' own key events,
 * with the adapter's engine report as the fallback (VON: getPlayerChannel);
 * himself from his own push-to-talk. Cheap to call. Under TFAR / ACRE the
 * list is that radio's adapter's (fnc_externalTick).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[unit, netId], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_talking
 *
 * Public: Yes
 */

+GVAR(talkers)
