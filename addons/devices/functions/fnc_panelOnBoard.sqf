#include "script_component.hpp"
/*
 * Author: JMSB
 * The vehicle tablet's left rail, ON BOARD (docs/DESIGN_TABLET.md, "Vehicle
 * tablet"): everyone in the vehicle the tablet was opened from, commander
 * first, passengers last - drawn as the squad rail draws a man (its medical
 * icon, the name, the seat in the role column: CMDR, DRV, GNR, PAX, and the
 * TX / VOX talk flag from FUNC(voiceTalkers)), as in
 * art/images/vehicle_screen.png. The header reads the vehicle's callsign
 * (FUNC(vehicleName)) and how many are aboard out of the seats there are.
 *
 * THE RAIL KEEPS THE HEIGHT IT WAS PLACED AT, as the squad rail it stands in
 * for does (jmfsb_tacpad_apps_fnc_panelSquad), so the left rail is the same
 * size on either tablet; the body scrolls when the vehicle holds more.
 *
 * A shell panel like the squad rail it stands in for (registered in
 * XEH_preInit), so it is built, refreshed, hidden behind apps and placed the
 * same way; the vehicle tablet's layout table puts it where the rail goes and
 * leaves the squad rail out.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, "onboard"] call jmfsb_devices_fnc_panelOnBoard
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];
if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

private _vehicle = GVAR(vehicle);
if (isNull _vehicle) exitWith {
    [_body, 0, "NO VEHICLE", "", [], true] call EFUNC(tacpad_apps,row);
    [_id, ""] call EFUNC(tacpad,headerMeta);
};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * HOST_H;
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _iconH = _rowH * ONBOARD_ICON_ROW;
private _iconW = _iconH * pixelW / pixelH;
private _scrollW = ONBOARD_SCROLL_PX * pixelW;
private _nameX = _pad * 2 + _iconW;
private _seatX = _w * ONBOARD_NAME_END;
private _flagX = _w * ONBOARD_SEAT_END;

private _icons = createHashMapFromArray CREW_ICONS;
private _voice = [] call FUNC(voiceTalkers);

// The seats and each man's state are FUNC(vehicleSeats)' - VEHICLE STATUS
// reads the same list, so the two never disagree about who sits where.
private _seats = [_vehicle] call FUNC(vehicleSeats);

private _hurtCount = 0;
{
    _x params ["", "_name", "_seat", "_man", "_state"];
    private _y = _forEachIndex * _rowH;

    private _icon = _icons getOrDefault [_state, ICON_OK];
    if (_state isNotEqualTo CREW_OK) then {_hurtCount = _hurtCount + 1};

    [_body, [_pad, _y + (_rowH - _iconH) * 0.5, _iconH], _icon] call EFUNC(tacpad,drawIcon);
    [_body, [_nameX, _y, _seatX - _nameX, _rowH], _name, _ink, ONBOARD_TEXT, _man isEqualTo (call CBA_fnc_currentUnit)] call EFUNC(tacpad,drawText);
    [_body, [_seatX, _y, _flagX - _seatX, _rowH], _seat, _ink, ONBOARD_TEXT] call EFUNC(tacpad,drawText);

    private _talking = (_voice getOrDefault [hashValue _man, [objNull, 0]]) select 1;
    if (_talking in [VOICE_RADIO, VOICE_DIRECT]) then {
        [
            _body, [_flagX, _y, _w - _flagX - _scrollW - _pad, _rowH],
            ["VOX", "TX"] select (_talking isEqualTo VOICE_RADIO),
            [COLOUR_VOX, COLOUR_TX] select (_talking isEqualTo VOICE_RADIO),
            ONBOARD_TEXT, true
        ] call EFUNC(tacpad,drawText);
    };

    [_body, [_pad, _y + _rowH - RULE_THIN * pixelH, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _seats;

[
    _id,
    format ["%1 %2 %3 / %4", [_vehicle] call FUNC(vehicleName), MIDDOT, count _seats, count (fullCrew [_vehicle, "", true])],
    _hurtCount > 0
] call EFUNC(tacpad,headerMeta);

// NO fit: the rail keeps the TABLET_RAIL height it was placed at.
