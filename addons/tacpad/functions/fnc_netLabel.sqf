#include "script_component.hpp"
/*
 * Author: YonV
 * A comma-separated addressee list, in the words the player picked it by.
 *
 * B:HQ IS NOT AN ADDRESS ANYBODY SPEAKS. The pane holds ids because the engine
 * addresses ids, but a line reading "TO B:HQ, P:76561198012345678" is a debug
 * readout - so the address is drawn through here and reads "HQ, SGT DOE".
 *
 * AN ID OFF THE LIST STILL PRINTS. A man who has left, or a box this player does
 * not read, has no label to look up, and is shown rather than dropped - a target
 * silently missing from the TO line is a message going somewhere the sender
 * cannot see. A box or a group carries its own name and prints it; a man carries
 * only a uid, so he is looked up by it, and reads DIRECT when even that fails.
 *
 * Arguments:
 * 0: Addressee ids, comma separated <STRING>
 *
 * Return Value:
 * Readable list <STRING>
 *
 * Example:
 * private _who = [jmfsb_tacpad_composeTo] call jmfsb_tacpad_fnc_netLabel
 *
 * Public: Yes
 */

params [["_ids", "", [""]]];

private _list = ((_ids splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
if (_list isEqualTo []) exitWith {"NOBODY"};

private _targets = [] call FUNC(composeTargets);

// A SUPPORT ASSET'S BOX READS AS ITS CALL SIGN (2026-11-01, design D1):
// "B:SUPPORT:cas:0" is HOG - EFUNC(support,boxName), "" for any other box.
private _supportNames = !isNil QEFUNC(support,boxName);

(_list apply {
    private _id = _x;
    private _at = _targets findIf {(_x # 0) isEqualTo _id};
    private _asset = "";
    if (_supportNames) then {_asset = [_id] call EFUNC(support,boxName)};

    switch (true) do {
        case (_asset isNotEqualTo ""): {_asset};
        case (_at >= 0): {(_targets # _at) # 1};
        default {
            switch (_id select [0, 2]) do {
                case "B:";
                case "G:": {toUpper (_id select [2])};
                // A UID IS NOT A NAME. "TO P:76561198012345678" is the debug readout
                // the whole function exists to stop, and a direct message opened off a
                // roster arrives as exactly that id - so the man is looked up by it.
                // DIRECT when he cannot be found, the word the old chips used for it.
                case "P:": {
                    private _uid = _id select [2];
                    private _found = allPlayers select {(getPlayerUID _x) isEqualTo _uid};
                    if (_found isEqualTo []) then {"DIRECT"} else {toUpper (name (_found # 0))}
                };
                // Anything else, submit takes as a shared mailbox name - so it reads
                // as one here too rather than being second-guessed.
                default {toUpper _id};
            }
        };
    }
}) joinString ", "
