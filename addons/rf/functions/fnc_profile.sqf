#include "script_component.hpp"
/*
 * Author: JMSB
 * A radio profile, read-only: a copy of the entry RF built from RF_PROFILES
 * (id, bands, txPowerDbm, rxSensDbm, antennaGainDb, pattern, sectorDeg,
 * hopLimit, relayCapable, spreadGainDb, batteryWh). For consumers that price
 * their own emissions (EW's DF and exposure) with RF's own numbers instead of
 * a second table. The profiles are built in preInit on every machine, so this
 * answers anywhere.
 *
 * Arguments:
 * 0: Profile id <STRING>
 *
 * Return Value:
 * Profile copy, empty when there is no such profile <HASHMAP>
 *
 * Example:
 * (["handheld"] call jmfsb_rf_fnc_profile) get "spreadGainDb"
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

+(GVAR(profiles) getOrDefault [_id, createHashMap])
