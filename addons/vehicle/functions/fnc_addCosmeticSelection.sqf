#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A -- Tinkered with by YonV
 * This function adds cosmetic customization actions to vehicles.
 *
 * THE CATALOGUE LIVES IN fn_vehicle_cosmeticEntries NOW - one data list that
 * this menu and the MOTORPOOL spawner UI both read, so a paint added there
 * shows up in both. This file only hangs the ACE actions.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * nothing
 *
 * Example:
 * [_vehicle] call jmfsb_vehicle_fnc_addCosmeticSelection;
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];

private _textures = call jmfsb_vehicle_fnc_cosmeticEntries;
// plus what the vehicle's own config can paint it, where the catalogue has nothing
_textures = _textures + ([typeOf _vehicle, _textures] call FUNC(factoryPaints));

{
    _x params ["_classname", "_displayName", "_textureCode"];
    if (_vehicle isKindOf _classname) then {

        private _statement = {
            params ["_vehicle", "_player", "_params"];
            _params params [["_texture", "", [""]], ["_code", {}, [{}]]];

            call _code;
            ["Vehicle", "Vehicle art has been changed.", NOTE_GOOD] call JMFSBFUNC(notify,notify);
        };

        private _category = ["ACE_SelfActions", QEGVAR(Actions_Vehicle,Main_Cat), QEGVAR(Actions_Vehicle,Cosmetic_Cat)];
        private _action = [format ["YMF_Cosmetic_%1_%2", _classname, _forEachIndex], _displayName, "", _statement, {true}, nil, _textureCode] call ace_interact_menu_fnc_createAction;
        [_vehicle, 1, _category, _action] call ace_interact_menu_fnc_addActionToObject;

        INFO_4("VehicleCosmeticSelector","Selector for classname '%1' named '%2' added to %3 (%4)",typeOf _vehicle,_displayName,_vehicle,typeOf _vehicle);
    };
} forEach _textures;
