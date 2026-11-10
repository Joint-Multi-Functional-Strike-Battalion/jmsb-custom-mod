#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// Threads whose bodies have been asked for. FUNC(netStream) requests what is
// not cached, and the reader redraws on every arriving message - without this
// the first busy net would ask for the same twenty threads on every redraw.
GVAR(asked) = [];

#include "initSettings.inc.sqf"

// CLIENT STATE FIRST, before anything that can fail. It used to be declared at
// the bottom, past the template registry - so a template file that threw left a
// client with no index and no cache, the server then filled the index over the
// wire, and every reader draw ran against a half-built addon. Nothing below
// this line is allowed to decide whether these exist.
//
// AND UNCONDITIONALLY. It was behind `if (hasInterface)`, which is the only way
// either of these can be nil at runtime - and it showed: the index has a second
// creator, FUNC(cltIndex), which assigns it outright when the server pushes one,
// so the index always looked fine. The cache has no such second creator, so
// where the gate had not run it stayed nil and every delivered message threw on
// `jmfsb_messaging_cache getOrDefault`. Two empty containers on a machine that
// never reads them cost nothing; a gate that can leave half the client state
// undefined costs an error per message.
GVAR(index) = [];
GVAR(cache) = createHashMap;

// Notification prefs. Net levels are a personal preference and come back from
// the player's profile; per-thread follows are session things because thread
// ids are. See FUNC(netLevel) for how the two compose.
GVAR(netLevels) = createHashMapFromArray (profileNamespace getVariable [QGVAR(netLevels), []]);
GVAR(threadFollow) = createHashMap;

// The registry is built on every machine, not just the server: rendering a
// message needs its template, and a client that had to ask the server for the
// template before it could show the message would be one round trip slower for
// no reason. Templates are static content - they never change at runtime.
GVAR(templates) = createHashMap;
GVAR(templateIds) = [];

// THE DECK COMES FROM THE MISSION. This was `#include "templates.inc.sqf"` -
// 590 lines of nested arrays compiled into the addon, so a new card or an extra
// line on an existing one meant rebuilding the mod. It is
// config\config_messaging.hpp in the mission now; see FUNC(loadTemplates).
call FUNC(loadTemplates);

// THE CARDS THE MOD CARRIES (user, 2026-11-02): the reports and the replies
// every thread takes, after the mission's deck - the mod's own card replaces
// a mission card of the same id (FUNC(registerBuiltins)). The ids retired from
// the deck, which pac templatesApply skips.
GVAR(retiredCards) = CARDS_RETIRED;
[[] call FUNC(builtinCards), QUOTE(COMPONENT)] call FUNC(registerBuiltins);

// The store. Only the server ever writes to it; a client keeps a disposable
// cache of what it has been shown and refetches after a reconnect.
if (isServer) then {
    GVAR(threads) = createHashMap;
    GVAR(messages) = createHashMap;
    GVAR(boxes) = createHashMap;
    GVAR(counters) = createHashMap;
    GVAR(nonces) = createHashMap;
};

ADDON = true;
