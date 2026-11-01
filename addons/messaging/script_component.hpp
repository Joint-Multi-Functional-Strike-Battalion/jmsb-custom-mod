#define COMPONENT messaging
#define COMPONENT_BEAUTIFIED Messaging
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// RECORD SHAPES. Every record is a HashMap with the keys listed here, and every
// one of them lives on the server only. HashMaps are used rather than positional
// arrays because a message has thirteen fields and nobody can read
// `_msg select 11` correctly at two in the morning. They are converted to arrays
// by toArray at the network boundary and rebuilt with createHashMapFromArray on
// the far side, because a HashMap is not guaranteed to survive remoteExec.
//
//  message  id seq threadId parentId fromUid fromCallsign templateId payload
//           sentTime gameTime priority transition readBy
//  thread   id kind subject rootTemplateId status issuerUid claimedBy
//           participants boxes anchorPos anchorLabel parentThreadId
//           lastActivity closed messages
//  box      id kind displayName roles uids retention forwardToAlive threads
//  index    threadId boxId subject status priority claimedBy lastActivity unread
//
// A TEMPLATE is also a HashMap, but it is built from templates.inc.sqf in
// preInit on every machine and never crosses the wire at all.

// Zero padding on generated ids, so M0042 sorts next to M0041 in a log.
#define ID_PAD 4

// Seconds between sweeps. The sweep only walks threads, so it is cheap; the
// interval is about how quickly an abandoned thread tidies itself, not load.
#define SWEEP_INTERVAL 60

// Hard caps. A long session must not grow the store without bound, and a client
// that has been connected for six hours must not be handed a six-hour index.
#define BOX_THREAD_MAX 200
#define INDEX_MAX 200

// Audience tags per message. Every tag is asked of every player on the server
// once per delivery, and a message that calls out eight different call signs is
// a message addressed to nobody in particular.
#define TAG_MAX 8

// The server's machine id - where a client sends a request by remoteExecCall
// (review S7). CBA events carry no sender, so nothing that needs trust uses one.
#define SERVER_OWNER 2

// remoteExecCall target for "every machine" - a server push the whole server
// takes, such as a marker removed with its thread.
#define TARGET_ALL 0

// Accent colours handed to the notification widget, so a warning from messaging
// looks like every other warning in the mod.
#define COLOUR_NORMAL [0.871, 0.361, 0.188, 1]
#define COLOUR_HIGH [1, 0.30, 0.30, 1]
