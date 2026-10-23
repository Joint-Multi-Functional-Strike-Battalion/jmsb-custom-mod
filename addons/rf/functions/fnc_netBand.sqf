#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_netBand: the band a net is on (server; on a client the net table is
 * empty and the answer is ""). For anything that prices noise by net - a
 * jammer that attacks one net hits that net's band.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Band "VHF" | "UHF" | "SAT" | "VIDEO", "" when the net does not exist <STRING>
 *
 * Example:
 * ["DATA"] call jmfsb_rf_fnc_netBand
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

(GVAR(nets) getOrDefault [_id, createHashMap]) getOrDefault ["band", ""]
