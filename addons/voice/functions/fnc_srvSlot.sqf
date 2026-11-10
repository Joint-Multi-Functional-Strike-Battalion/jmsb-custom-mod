#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the slot a new call takes, 0-based; -1 when there is none.
 *
 * A free slot first. With every slot taken, one more is made only where the
 * adapter has no channel count to run out of. NO LIMIT TO THE NUMBER OF CALLS
 * ON THE VOICE SERVER (user, 2026-11-01: "on the radio calls tab there should
 * be no limit to the # of calls"): adapter_livekit counts no channels (its
 * "channelUse" hook answers []) and its "reserve" hook grants every net, so
 * the slots grow as calls are made - Mumble and LiveKit alike. Game VON
 * counts its ten custom channels (C2, A2G, eight calls) and stays at
 * CALL_SLOTS. An adapter without a "reserve" hook stays there too.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Slot index, 0-based, -1 for none <NUMBER>
 *
 * Example:
 * private _slot = [] call jmfsb_voice_fnc_srvSlot
 *
 * Public: No
 */

if (!isServer) exitWith {-1};

private _slot = GVAR(slots) find "";
if (_slot >= 0) exitWith {_slot};

// An adapter that counts its channels (game VON) has no slot past these.
if (([] call FUNC(channelUse)) isNotEqualTo []) exitWith {-1};

_slot = count GVAR(slots);
private _granted = [format [CALL_FORMAT, _slot + 1]] call HOOK("reserve");
if (isNil "_granted") exitWith {-1};
if (_granted isNotEqualTo true) exitWith {-1};

GVAR(slots) pushBack "";
INFO_1("call slot %1 added: the adapter counts no channels",_slot + 1);
_slot
