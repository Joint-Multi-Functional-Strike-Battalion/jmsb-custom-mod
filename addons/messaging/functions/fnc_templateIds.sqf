#include "script_component.hpp"
/*
 * Author: YonV
 * Lists template ids in registration order, optionally filtered by what they
 * can be used for. Registration order is kept because the templates file is
 * ordered the way the JMSB smart-card deck is, and a UI that sorted them
 * alphabetically would put AIRDROP above CASEVAC.
 *
 * Arguments:
 * 0: Kind - "root", "reply" or "" for all <STRING> (optional, default "")
 * 1: Thread status a reply must be legal in, "" to ignore <STRING> (optional, default "")
 *
 * Return Value:
 * Template ids <ARRAY>
 *
 * Example:
 * private _replies = ["reply", "ISSUED"] call jmfsb_messaging_fnc_templateIds
 *
 * Public: Yes
 */

params [["_kind", "", [""]], ["_status", "", [""]]];

// NO exitWith IN HERE. A select block is not called - it shares the scope of
// whatever is running it - so an exitWith inside one exits THIS FUNCTION, and
// this function then returns the Bool it was trying to give back for a single
// template. It did: every caller got `false` where it expected a list, and
// openCompose died on `forEach false` the first time anyone pressed NEW.
GVAR(templateIds) select {
    private _t = GVAR(templates) get _x;
    private _tKind = _t get "kind";
    private _allowed = _t get "allowedFrom";

    (_kind == "" || _tKind == _kind || _tKind == "both")
    && {_status == "" || {_allowed isEqualTo [] || {_status in _allowed}}}
}
