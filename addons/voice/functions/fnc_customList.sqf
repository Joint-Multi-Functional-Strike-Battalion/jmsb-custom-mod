#include "script_component.hpp"
/*
 * Author: JMSB
 * The RTO nets the server has published (user, 2026-10-22: "allow rtos to
 * add custom channels"), as the RADIO app lists them. A copy: the caller may
 * do what it likes with it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[id, name, squads (upper-case callsigns), uids, owner uid, owner name], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_customList
 *
 * Public: Yes
 */

+GVAR(customPub)
