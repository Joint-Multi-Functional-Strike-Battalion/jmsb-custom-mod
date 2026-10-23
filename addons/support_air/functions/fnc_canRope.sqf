#include "script_component.hpp"
/*
 * Author: JMSB
 * Can this helicopter put men down on ropes: ACE fast-roping loaded, and the
 * airframe fitted with FRIES or able to take them (ace_fastroping_enabled 1
 * built in, 2 fitted on request). The same test the QRF air assault makes
 * before it ropes in rather than lands (FUNC(qrfTick)), and the one the
 * transport module makes before it offers FASTROPE.
 *
 * Arguments:
 * 0: Helicopter class <STRING>
 *
 * Return Value:
 * Can rope <BOOL>
 *
 * Example:
 * ["B_Heli_Transport_01_F"] call jmfsb_support_air_fnc_canRope
 *
 * Public: No
 */

params [["_cls", "", [""]]];

EGVAR(common,aceFastroping)
    && {!isNil "ace_fastroping_fnc_deployAI"}
    && {getNumber (configFile >> "CfgVehicles" >> _cls >> "ace_fastroping_enabled") > 0}
