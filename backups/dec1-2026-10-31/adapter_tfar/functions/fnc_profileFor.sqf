#include "script_component.hpp"
/*
 * Author: JMSB
 * TFAR radio class -> RF profile: the profile the class names in config
 * (jmfsb_rf_profile, read by jmfsb_rf_fnc_itemProfile - the MPU5 handheld,
 * the TW-950 legacy), else a handheld for a short range set and a manpack
 * for a long range one (a TFAR backpack; radio bags carry no profile since
 * game voice dropped man packs, 2026-10-21). The core never sees a class.
 *
 * Arguments:
 * 0: Kind "sr" | "lr" <STRING>
 * 1: Class: the SR radio's tf_parent, or the LR backpack's class <STRING>
 *
 * Return Value:
 * Profile id <STRING>
 *
 * Example:
 * ["sr", "jmfsb_mpu5"] call jmfsb_adapter_tfar_fnc_profileFor
 *
 * Public: No
 */

params [["_kind", NODE_SR, [""]], ["_class", "", [""]]];

private _profile = [_class] call EFUNC(rf,itemProfile);
if (_profile isNotEqualTo "") exitWith {_profile};
[LR_PROFILE_DEFAULT, SR_PROFILE_DEFAULT] select (_kind isEqualTo NODE_SR)
