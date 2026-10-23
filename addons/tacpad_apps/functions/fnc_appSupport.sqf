#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT: combat-support tasking, fronting the SUPPORT CORE
 * (jmfsb_support) and never touching any provider - ALiVE, the CAS drones,
 * support_fires / support_air - itself. Rows from
 * EFUNC(support,assets), asset types and their tasks from
 * EFUNC(support,types) / EFUNC(support,tasks), orders through
 * EFUNC(support,request), receipts on the jmfsb_support_ack event.
 *
 * THE LAYOUT (docs/DESIGN_SUPPORT.md, "The screen"):
 *
 *   +------------------------------------------------------------+
 *   | TAC//SUPPORT                         AVAILABLE · n  SITREP |
 *   | CAS · 2 | ARTILLERY · 1 | TRANSPORT · 1 | QRF · 1          |  one tab per type with a row
 *   +----------------------+-------------------------------------+
 *   | verdict              |                                     |
 *   | UNIT  rows           |              the map                |
 *   | TASK  rows           |   (its own control on the vanilla   |
 *   | LOCATION  TARGET/LZ  |    map; the tablet's own map on     |
 *   | PARAMETERS steppers  |    the tablet)                      |
 *   |----------------------|-------------------------------------|
 *   | READY  checklist     |  ORDER UNIT RTB                     |
 *   | [ CONFIRM TASKING ]  |  CLOSE                              |
 *   +----------------------+-------------------------------------+
 *
 * TWO HOSTS, ONE SCREEN. On the vanilla map (native mode) the board is the
 * QGVAR(supportDlg) dialog - a map control embedded in a drawn panel on the
 * map display bled past its frame and fed its drags to the big map, and in a
 * dialog it clips and pans itself. On the TABLET ("all apps need to be inside
 * the tablet", user 2026-10-20) it opens NO dialog: it draws on the device
 * dialog inside the host's app area, like every other app, and its map hole
 * is a hole over the tablet's own map (idc IDC_HOST_MAP), which it claims for
 * its picks through EGVAR(tacpad,appMapClaim) - see EFUNC(tacpad,appExits).
 * The device bar, tiles and net row stay round it.
 *
 * THE MAP IS A HOLE AND THE SCREEN IS BUILT AROUND IT. Runtime controls stack
 * above config ones, so one group spanning the rectangle would cover the map
 * and eat every click meant for it. Slabs BORDER the hole - header, tabs,
 * form and its foot to the left, actions under it - and nothing of ours
 * crosses it.
 *
 * Arguments (app handler):
 * 0: Host display <DISPLAY> - unused; the board finds its own display
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_hostDisplay", displayNull, [displayNull]]];

if (isNil QEFUNC(support,assets)) exitWith {
    ["SUPPORT", "The support core is not loaded.", "high"] call EFUNC(messaging,notify);
};

// THE TASKING TAG GATE is the core's - see EFUNC(support,canTask), which also
// fails OPEN on a tag that names nobody in the mission.
([player] call EFUNC(support,canTask)) params ["_may", "_gateWhy"];
if (!_may) exitWith {
    ["SUPPORT", _gateWhy, "high"] call EFUNC(messaging,notify);
};

private _onHost = HOST_DEVICE;

// The last draw's controls. The root was one control and is a list now; an
// old single control is wrapped so a session spanning the change does not
// choke on it.
private _oldRoot = uiNamespace getVariable [QGVAR(supportRoot), []];
if (_oldRoot isEqualType controlNull) then {_oldRoot = [_oldRoot]};

// Whatever other app was open closes first - a board over a live app left the
// old page ghosting through. On the tablet the app group may be this board's
// own header slab, which goes with the rest of the old draw below.
private _g = uiNamespace getVariable [QEGVAR(tacpad,appGroup), controlNull];
if (!isNull _g && {!(_g in _oldRoot)}) then {ctrlDelete _g};
uiNamespace setVariable [QEGVAR(tacpad,appGroup), controlNull];

// THE DISPLAY. The dialog on the vanilla map - opening twice just redraws the
// content - and the host display on the tablet. FRESH is the first draw of an
// opening, the only one that resets the marker pick and centres the map; on
// the tablet that is a draw with no live controls left from the last one
// (FUNC(appClose) sweeps them, and so does the appOpened listener in
// XEH_postInit when another app takes the screen).
private _display = displayNull;
private _fresh = false;
if (_onHost) then {
    _display = HOST_DISPLAY;
    _fresh = (_oldRoot findIf {!isNull _x}) < 0;
} else {
    _display = uiNamespace getVariable [QGVAR(supportDlg), displayNull];
    if (isNull _display) then {
        createDialog QGVAR(supportDlg);
        _display = uiNamespace getVariable [QGVAR(supportDlg), displayNull];
        _fresh = true;
        INFO_1("appSupport: dialog created - %1",_display);
    };
};
if (isNull _display) exitWith {
    WARNING_1("appSupport: no display to draw on (tablet %1)",_onHost);
};
if (_fresh) then {
    missionNamespace setVariable [QGVAR(supportPickMarker), false];
};

// The form's scroll, read before the form it belongs to goes.
private _oldBody = uiNamespace getVariable [QGVAR(supportBody), controlNull];
private _scroll = if (isNull _oldBody) then {[0, 0]} else {ctrlScrollValues _oldBody};

{if (!isNull _x) then {ctrlDelete _x}} forEach _oldRoot;

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

// OPAQUE, WHATEVER THE PANEL OPACITY SETTING SAYS. Translucent ground is for
// panels floating over the live map; on a modal board it is mud.
_ground = +_ground;
_ground set [3, 1];

private _mute = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _accentText = ["accentText"] call EFUNC(tacpad,theme);
private _surface = ["surface"] call EFUNC(tacpad,theme);

// ------------------------------------------------------------- geometry ----
// The safe zone on the vanilla map, the host rectangle on the tablet - see
// SUP_UNIT_W in script_component.hpp.
private _uw = SUP_UNIT_W;
private _uh = SUP_UNIT_H;
([SUP_FRAME_NATIVE, SUP_FRAME_TABLET] select _onHost) params ["_fx", "_fy", "_fw0", "_fh0"];
private _w = _fw0 * _uw;
private _h = _fh0 * _uh;
private _x0 = SUP_ORIGIN_X + _fx * _uw;
private _y0 = SUP_ORIGIN_Y + _fy * _uh;

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * _uh;
private _pad = PAD * _uw;
private _padY = PAD * _uh;
private _ruleX = RULE_THICK * pixelW;
private _ruleY = RULE_THICK * pixelH;

private _headerH = SUP_HEAD_K * _h;
private _tabsH = _rowH * SUP_TABS_K;
private _top = _headerH + _tabsH;
private _mapL = SUP_MAP_L_K * _w;
private _mapB = SUP_MAP_B_K * _h;
private _fw = _mapL;
private _aw = _w - _mapL;
private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;

// The hole, in screen units: where the map shows and where a press on it
// counts as a pick.
private _hole = [_x0 + _mapL, _y0 + _top, _w - _mapL, _mapB - _top];
uiNamespace setVariable [QGVAR(supportHole), _hole];

// ---------------------------------------------------------- the selection --
private _sel = missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]];
_sel params ["_selType", "_selUnit", "_selTask"];

private _assets = call EFUNC(support,assets);

// ONLY THE TYPES THAT HAVE A ROW - one tab each. A provider declares its types
// whether or not the mission gave it anything (support_air declares TRANSPORT,
// LOGISTICS and QRF on every mission), and a tab counted 0 is a choice that
// leads nowhere. The set is the providers' declarations, merged by the core;
// nothing here names a type.
private _types = (call EFUNC(support,types)) select {
    private _type = _x param [0, ""];
    (_assets findIf {(_x param [1, ""]) isEqualTo _type}) > -1
};
private _fnc_hasTab = {
    params ["_t"];
    (_types findIf {(_x param [0, ""]) isEqualTo _t}) > -1
};

// THE LAST TAB A PLAYER PRESSED IS REMEMBERED for the session
// (QGVAR(supportTabPref)), apart from the selection: a tab that runs dry
// drops the selection to the first tab still answering, and the next opening
// goes back to the remembered one once it has a row again.
private _pref = missionNamespace getVariable [QGVAR(supportTabPref), ""];
private _want = _selType;
if (_fresh && _pref isNotEqualTo "" && {[_pref] call _fnc_hasTab}) then {_want = _pref};
if (_types isNotEqualTo [] && {!([_want] call _fnc_hasTab)}) then {
    _want = (_types select 0) param [0, ""];
};
if (_want isNotEqualTo _selType) then {
    INFO_2("appSupport: tab '%1' -> '%2'",_selType,_want);
    _selType = _want;
    _selUnit = "";
    _selTask = "";
    missionNamespace setVariable [QGVAR(supportSel), [_selType, _selUnit, _selTask]];
};
// No type answering at all: a unit and task picked before the last row went
// would otherwise hold CONFIRM ready against an asset that is no longer there.
if (_types isEqualTo [] && {_selUnit isNotEqualTo "" || _selTask isNotEqualTo ""}) then {
    INFO_1("appSupport: no type has rows - clearing the pick on '%1'",_selType);
    _selUnit = "";
    _selTask = "";
    missionNamespace setVariable [QGVAR(supportSel), [_selType, _selUnit, _selTask]];
};

private _units = _assets select {(_x param [1, ""]) isEqualTo _selType};
private _unitRow = _units param [_units findIf {(_x param [0, ""]) isEqualTo _selUnit}, []];

// The airframe the map marks and PASSENGERS reads - element 7 of the
// core's row, objNull for a battery or a provider that does not say.
uiNamespace setVariable [QGVAR(supportVeh), _unitRow param [7, objNull]];
uiNamespace setVariable [QGVAR(supportVehLabel), _unitRow param [2, ""]];
// EVERY ROW, for the live overlay (FUNC(supportMapDraw)): each airframe out
// and the plan it is flying (row field 8), the picked one in ink - the task
// markers Simplex puts on the map for its transports, on the board's map in
// both hosts.
uiNamespace setVariable [QGVAR(supportRows), _assets];
uiNamespace setVariable [QGVAR(supportSelId), _selUnit];
// What the picked asset's provider wants on the map besides - an artillery
// battery's range rings (EFUNC(support,overlay)).
uiNamespace setVariable [QGVAR(supportShapes), [_selUnit, _unitRow] call EFUNC(support,overlay)];

// WHAT HAS BEEN COMMITTED. A confirmed tasking lights its task row in the
// accent while the unit is busy with it, or for a grace while the provider has
// yet to flip the unit's status.
(missionNamespace getVariable [QGVAR(supportCommitted), []]) params [["_cUnit", ""], ["_cTask", ""], ["_cAt", -1]];
private _unitBusy = _unitRow isNotEqualTo [] && {(_unitRow param [4, "idle"]) isNotEqualTo "idle"};
private _commitLive = _cUnit isNotEqualTo "" && _cUnit isEqualTo _selUnit
    && {_unitBusy || {CBA_missionTime - _cAt < SUP_COMMIT_GRACE}};
private _tasked = _unitBusy || _commitLive;

// [token, label, meta, guidance, steppers, needsPoint, pointLabel] - declared
// by the providers, not by this screen: EFUNC(support,tasks) answers for the
// picked unit's provider, or for every provider of the type before a unit is
// picked. Nothing to list while no type has a row.
private _tasks = if (_types isEqualTo []) then {[]} else {
    [_selType, _selUnit, _unitRow] call EFUNC(support,tasks)
};
private _taskRow = _tasks param [_tasks findIf {(_x param [0, ""]) isEqualTo _selTask}, []];

private _prm = missionNamespace getVariable [QGVAR(supportParams), SUP_PARAMS_DEFAULT];
_prm params ["_radius", "_alt", "_roeIdx"];
private _speedIdx = _prm param [3, 1];
private _roeText = SUP_ROE_TEXT;

// A JMFSB-NATIVE CAS DRONE FLIES THE RUN THE PLAYER DRAWS - target, INGRESS and
// EGRESS. The id's prefix is the provider kind the support core routes on;
// only the CAS drone provider registers that kind.
private _isJmfsbCas = ((_unitRow param [0, ""]) splitString ":" param [0, ""]) isEqualTo SUP_KIND_DRAWN_RUN;

// WHAT THE PICKED TASK DECLARES - its steppers, whether it needs a point, and
// what the point is called (TARGET, LZ, PICKUP, DROP POINT ...). See
// addons/support/README.md.
private _declSteps = _taskRow param [4, []];
if !(_declSteps isEqualType []) then {_declSteps = []};
private _declPoint = _taskRow param [5, false];
if !(_declPoint isEqualType false) then {_declPoint = false};
private _pointLabel = _taskRow param [6, ""];
if (!(_pointLabel isEqualType "") || _pointLabel isEqualTo "") then {_pointLabel = SUP_POINT_DEFAULT};
_pointLabel = toUpper _pointLabel;

// THE LEGACY LAYOUT IS THE ALiVE PROVIDER'S. Its steppers and ROE list write
// slots 0-7 and 11, which only that provider reads; drawn only for a task that
// declares nothing, on an ALiVE row - or, before a unit is picked, while every
// row of the type is ALiVE's.
private _fnc_kindOf = {((_this param [0, ""]) splitString ":") param [0, ""]};
private _legacy = _declSteps isEqualTo [] && {
    if (_unitRow isEqualTo []) then {
        _units isNotEqualTo [] && {(_units findIf {!((_x call _fnc_kindOf) in SUP_KINDS_LEGACY)}) < 0}
    } else {
        (_unitRow call _fnc_kindOf) in SUP_KINDS_LEGACY
    }
};

// THE MAP OVERLAY'S RADIUS, for FUNC(supportMapDraw): nil while the legacy
// layout is up, otherwise [slot, min, max, label] of the declared stepper
// that sizes the effect area, or [] when nothing does. A stepper's own map
// aid (field 8, ["radius"]) says so; the label is the fallback for providers
// that declare none.
private _aids = [];
if (_legacy) then {
    uiNamespace setVariable [QGVAR(supportRadiusStep), nil];
} else {
    private _ri = _declSteps findIf {((_x param [8, []]) param [0, ""]) isEqualTo "radius"};
    if (_ri < 0) then {_ri = _declSteps findIf {(toUpper (_x param [0, ""])) in SUP_RADIUS_LABELS}};
    private _rs = [];
    if (_ri >= 0) then {
        (_declSteps select _ri) params [["_rLabel", ""], ["_rSlot", 0], "", ["_rMin", 0], ["_rMax", 0]];
        _rs = [_rSlot, _rMin, _rMax, _rLabel];
    };
    uiNamespace setVariable [QGVAR(supportRadiusStep), _rs];
    // The other aids - an approach bearing, a danger-close ring:
    // [aid, slot, min, max, label].
    {
        _x params [["_aLabel", ""], ["_aSlot", 0], "", ["_aMin", 0], ["_aMax", 0], "", "", "", ["_aid", []]];
        if (_aid isEqualType [] && {(_aid param [0, ""]) in ["bearing", "ring"]}) then {
            _aids pushBack [_aid, _aSlot, _aMin, _aMax, _aLabel];
        };
    } forEach _declSteps;
};
uiNamespace setVariable [QGVAR(supportAids), _aids];

// THE POINTS THE TASK CARRIES BESIDES ITS OWN (task declaration field 7):
// [label, slot, hint, required, many, leg, row key]. A CAS drone row that
// declares none still gets its INGRESS and EGRESS - it always has.
private _declPoints = (_taskRow param [7, []]) select {
    _x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {(_x param [1, -1]) isEqualType 0} && {(_x param [1, -1]) >= SUP_PARAM_INGRESS}
};
if (_declPoints isEqualTo [] && _isJmfsbCas) then {
    _declPoints = [
        ["INGRESS", SUP_PARAM_INGRESS, "AUTO - FROM YOUR SIDE", false, 1, "in"],
        ["EGRESS", SUP_PARAM_EGRESS, "AUTO - STRAIGHT THROUGH", false, 1, "out"]
    ];
};
_declPoints = _declPoints apply {
    _x params ["_dLabel", "_dSlot", ["_dHint", ""], ["_dReq", false], ["_dMany", 1], ["_dLeg", "out"]];
    [toUpper _dLabel, _dSlot, _dHint, _dReq isEqualTo true, (round _dMany) max 1, _dLeg, SUP_POINT_KEY(_dSlot)]
};
uiNamespace setVariable [QGVAR(supportPointDecls), _declPoints];
private _many = createHashMap;
{_many set [_x select 6, _x select 4]} forEach _declPoints;
uiNamespace setVariable [QGVAR(supportMany), _many];

// Only a row on the screen can be armed, or a stale arming would send the
// next map click into a point the screen is not showing.
if !((missionNamespace getVariable [QGVAR(supportSlot), SUP_SLOT_TARGET]) in ([SUP_SLOT_TARGET] + (_declPoints apply {_x select 6}))) then {
    missionNamespace setVariable [QGVAR(supportSlot), SUP_SLOT_TARGET];
};

private _pt = missionNamespace getVariable [QGVAR(supportPoint), []];
private _needsPoint = _selType isEqualTo "arty" || _isJmfsbCas || _declPoint;

// -------------------------------------------------------- the checklist ----
// WHAT THE TASKING STILL NEEDS, one line each, done or missing - shown over
// CONFIRM TASKING, which stays dead until nothing is missing. [label, says,
// done]. A point the request can go without (a PICKUP "on you") is done
// either way and says so.
private _fnc_pointText = {
    params ["_slot"];
    ([_slot] call FUNC(supportPointVars)) params ["_pv", "_nv"];
    private _p = missionNamespace getVariable [_pv, []];
    private _n = missionNamespace getVariable [_nv, ""];
    if (_p isEqualTo []) exitWith {""};
    // A row that takes several points holds a list of them.
    if ((_p select 0) isEqualType []) exitWith {
        format ["%1 POINT%2 · LAST %3", count _p, ["S", ""] select (count _p isEqualTo 1), mapGridPosition (_p select -1)]
    };
    if (_n isEqualTo "") then {format ["GRID %1", mapGridPosition _p]} else {format ["MKR %1", toUpper _n]}
};
private _ptText = [SUP_SLOT_TARGET] call _fnc_pointText;
private _checks = [
    ["UNIT", [_unitRow param [2, "UNIT"], "not selected"] select (_unitRow isEqualTo []), _unitRow isNotEqualTo []],
    ["TASK", [_taskRow param [1, "TASK"], "not selected"] select (_taskRow isEqualTo []), _taskRow isNotEqualTo []],
    [
        _pointLabel,
        switch (true) do {
            case (_ptText isNotEqualTo ""): {_ptText};
            case (_needsPoint): {"not set"};
            default {"your position"};
        },
        !_needsPoint || {_pt isNotEqualTo []}
    ]
];
// Every further point the task declares REQUIRED is a line of its own.
{
    _x params ["_dLabel", "", "", "_dReq", "", "", "_dKey"];
    if (_dReq) then {
        private _dText = [_dKey] call _fnc_pointText;
        _checks pushBack [_dLabel, [_dText, "not set"] select (_dText isEqualTo ""), _dText isNotEqualTo ""];
    };
} forEach _declPoints;

// THE PROVIDER'S VERDICT, once everything else is set - an ETA, a time of
// flight, OUT OF RANGE - the line Simplex shows beside its confirm
// (EFUNC(support,preview)). Against the request, it is a missing line and
// CONFIRM waits; a provider with no preview adds nothing.
if ((_checks findIf {!(_x select 2)}) < 0) then {
    private _preview = [_selUnit, _selTask, _pt, [] call FUNC(supportRequestParams)] call EFUNC(support,preview);
    if (_preview isNotEqualTo []) then {
        _preview params ["_pOk", "_pLine"];
        _checks pushBack ["VERDICT", _pLine, _pOk];
    };
};
private _missing = _checks select {!(_x select 2)};
private _ready = _missing isEqualTo [];
uiNamespace setVariable [QGVAR(supportMissing), _missing apply {format ["%1 - %2", _x select 0, _x select 1]}];

// The marker list takes the whole form column; the checklist and CONFIRM
// belong to the form and stand down with it.
private _picking = missionNamespace getVariable [QGVAR(supportPickMarker), false];
private _checkH = _rowH * SUP_CHECK_K;
private _groupH = _rowH * 0.85;
private _footH = if (_picking) then {0} else {
    _groupH + _padY + count _checks * _checkH + _padY * 2 + _btnH + _padY * 2
};

// --------------------------------------------------------------- the slabs --
private _roots = [];
private _fnc_slab = {
    params ["_px", "_py", "_pw", "_ph", ["_cls", QEGVAR(tacpad,panel)]];
    private _s = _display ctrlCreate [_cls, -1];
    _s ctrlSetPosition [_x0 + _px, _y0 + _py, _pw, _ph];
    _s ctrlCommit 0;
    // FUNC(appClose)'s orphan sweep takes owned controls with it - the
    // board's slabs are top-level, not children of one app group.
    _s setVariable [QEGVAR(tacpad,owned), true];
    _roots pushBack _s;
    _s
};

private _head = [0, 0, _w, _headerH] call _fnc_slab;
private _tabs = [0, _headerH, _w, _tabsH] call _fnc_slab;
// THE FORM SCROLLS. An artillery request with every fires control offered is
// nine steppers, a transport a dozen tasks and three points: on the vanilla
// map that is more than the column holds, so the form is the tacpad's
// scrolling body, and the scroll it was at survives the redraw every pick
// makes.
private _body = [0, _top, _fw, _h - _top - _footH, QEGVAR(tacpad,body)] call _fnc_slab;
uiNamespace setVariable [QGVAR(supportBody), _body];
private _foot = if (_footH > 0) then {[0, _h - _footH, _fw, _footH] call _fnc_slab} else {controlNull};
private _act = [_mapL, _mapB, _aw, _h - _mapB] call _fnc_slab;
private _bodyH = _h - _top - _footH;

// The border, four standalone lines - no single frame may span the hole - and
// the divider along the form's edge.
{
    _x params ["_px", "_py", "_pw", "_ph"];
    private _l = _display ctrlCreate [QEGVAR(tacpad,fill), -1];
    _l ctrlSetPosition [_x0 + _px, _y0 + _py, _pw, _ph];
    _l ctrlSetBackgroundColor _ink;
    _l ctrlCommit 0;
    _l setVariable [QEGVAR(tacpad,owned), true];
    _roots pushBack _l;
} forEach [
    [0, 0, _w, _ruleY],
    [0, _h - _ruleY, _w, _ruleY],
    [0, 0, _ruleX, _h],
    [_w - _ruleX, 0, _ruleX, _h],
    [_mapL, _top, _ruleX, _h - _top]
];

uiNamespace setVariable [QGVAR(supportRoot), _roots];

// ON THE TABLET THE BOARD IS THE OPEN APP'S PAGE. Its header is the app group
// FUNC(appFrame) replaces when another app opens, and it holds the host's map
// for its picks while it is the open app.
if (_onHost) then {
    uiNamespace setVariable [QEGVAR(tacpad,appGroup), _head];
    uiNamespace setVariable [QEGVAR(tacpad,appMapClaim), SUP_APP];
};

// Display-dispatched press rects, gathered through the draw and stored once
// at the bottom - see the display MouseButtonDown handler.
private _hotspots = [];

// CLOSE: the dialog on the vanilla map, the app on the tablet - never a
// closeDisplay there, that display is the device.
private _fnc_close = [{
    (uiNamespace getVariable [QGVAR(supportDlg), displayNull]) closeDisplay 2;
}, {
    [] call EFUNC(tacpad,appClose);
}] select _onHost;

// ------------------------------------------------------------- the header ---
[_head, [0, 0, _w, _headerH], _ground] call EFUNC(tacpad,drawFill);
[_head, [0, _headerH - _ruleY, _w, _ruleY], _ink] call EFUNC(tacpad,drawFill);
[_head, [_pad * 2, 0, _w * 0.4, _headerH], "TAC//SUPPORT", _ink, TEXT_TITLE, true, "left", true] call EFUNC(tacpad,drawText);

private _idle = {(_x param [4, "idle"]) isEqualTo "idle"} count _assets;
private _sitW = _w * 0.08;
private _sitX = _w - _pad * 2 - _sitW;
private _sitY = _headerH * 0.15;
private _sitH = _headerH * 0.7;
[_head, [_w * 0.5, 0, _sitX - _w * 0.5 - _pad * 3, _headerH], format ["AVAILABLE · %1", _idle], _mute, TEXT_LABEL, true, "right", true] call EFUNC(tacpad,drawText);

// SITREP asks the picked asset for its own state through the support core and
// its provider - every type, batteries included (support_fires answers for
// its own); a provider with no sitrep answers "no report".
private _canSitrep = _unitRow isNotEqualTo [];
[_head, [_sitX, _sitY, _sitW, _sitH], ([_line, _ink] select _canSitrep), RULE_THICK] call EFUNC(tacpad,drawFrame);
[_head, [_sitX, _sitY, _sitW, _sitH], "SITREP", ([_dim, _ink] select _canSitrep), TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);

_hotspots pushBack [_x0 + _sitX, _y0 + _sitY, _sitW, _sitH, [{
    INFO("appSupport: SITREP pressed with no airframe picked");
    missionNamespace setVariable [QGVAR(supportFlash), ["Pick an airframe for its sitrep", false, CBA_missionTime]];
    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}, {
    private _sel = missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]];
    ([_sel # 1] call EFUNC(support,sitrep)) params ["_ok", "_said"];
    missionNamespace setVariable [QGVAR(supportFlash), [_said, _ok, CBA_missionTime]];
    ["SUPPORT", _said, ["high", "normal"] select _ok] call EFUNC(messaging,notify);
    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] select _canSitrep, "SITREP"];

// WHAT A PICK DOES, IN ONE PLACE. Every list on the screen - the tabs too - is
// the same choice made in a different slot: slot, value, and clear whatever
// depended on it. A tab is slot 0, remembered for the session, and it answers
// any marker list that was open.
private _fnc_pick = {
    params ["_ctrl"];
    private _sel = missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]];
    (_ctrl getVariable [QGVAR(pick), []]) params ["_slot", "_value"];
    INFO_2("appSupport: row pressed - slot %1 value '%2'",_slot,_value);

    _sel set [_slot, _value];
    if (_slot < 1) then {_sel set [1, ""]};
    if (_slot < 2) then {_sel set [2, ""]};
    missionNamespace setVariable [QGVAR(supportSel), _sel];
    if (_slot isEqualTo 0) then {
        missionNamespace setVariable [QGVAR(supportTabPref), _value];
        missionNamespace setVariable [QGVAR(supportPickMarker), false];
    };

    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};

// --------------------------------------------------------------- the tabs ---
// ONE TAB PER TYPE THAT HAS A ROW, in the core's order, each counted. The
// picked tab is the ink fill; the others lift to the surface step on hover.
[_tabs, [0, 0, _w, _tabsH], _ground] call EFUNC(tacpad,drawFill);
if (_types isEqualTo []) then {
    [_tabs, [_pad * 2, 0, _w - 4 * _pad, _tabsH], "NO SUPPORT ON THIS MISSION", _dim, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
};
private _tabW = _w / ((count _types) max 1);
private _tabInH = _tabsH - _ruleY;
{
    _x params ["_type", "_label"];
    private _n = {(_x param [1, ""]) isEqualTo _type} count _assets;
    private _on = _type isEqualTo _selType;
    private _tx = _forEachIndex * _tabW;
    private _rect = [_tx, 0, _tabW, _tabInH];
    private _fillC = [_ground, _ink] select _on;
    private _textC = [_ink, _ground] select _on;

    private _fill = [_tabs, _rect, _fillC] call EFUNC(tacpad,drawFill);
    private _spec = ["label", [_tabs, [_tx + _pad, 0, _tabW - 2 * _pad, _tabInH], format ["%1 · %2", _label, _n], _textC, TEXT_LABEL, true, "center"]] call FUNC(supportHover);
    if (_forEachIndex > 0) then {
        [_tabs, [_tx, 0, RULE_THIN * pixelW, _tabInH], _line] call EFUNC(tacpad,drawFill);
    };
    private _hit = [_tabs, _rect, _fnc_pick] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(pick), [0, _type]];
    if (!_on) then {
        ["wire", [_hit, _fill, [_spec], _fillC, _surface, []]] call FUNC(supportHover);
    };
} forEach _types;
[_tabs, [0, _tabInH, _w, _ruleY], _ink] call EFUNC(tacpad,drawFill);

// The form ground and the action slab's, opaque, scheme colours. The form's
// is stretched to its content at the end of the draw, so a scrolled form is
// never the map showing through.
private _bodyGround = [_body, [0, 0, _fw, _bodyH], _ground] call EFUNC(tacpad,drawFill);
[_act, [0, 0, _aw, _h - _mapB], _ground] call EFUNC(tacpad,drawFill);

// THE GROUP LABEL - see FUNC(supportGroup).
private _fnc_group = {
    params ["_rowY", "_label", "_guide"];
    [_body, _rowY, _fw, _label, _guide] call FUNC(supportGroup)
};

// A LIST ROW - see FUNC(supportCell) for the states.
private _fnc_row = {
    params ["_rowY", "_label", "_meta", "_state", "_data"];
    [_body, [0, _rowY, _fw, _rowH], _label, _meta, _state, _fnc_pick, _data] call FUNC(supportCell);
    _rowY + _rowH
};

// ----------------------------------------------------------- action stack ---
// Under the map: ORDER UNIT RTB and CLOSE. CONFIRM TASKING is not here - it
// stands alone at the foot of the form, under the checklist that says what
// it is waiting for.
private _gapY = _padY * 1.25;
private _ax = _pad * 2;
private _abw = _aw - 4 * _pad;
private _aBtnH = _btnH min ((_h - _mapB - 2 * _padY - _gapY) / 2);
private _ry = _padY;
private _ky = _ry + _aBtnH + _gapY;

// [parent, x, y, w, h, label, style]: "pri" accent fill, "armed" ink fill,
// "off" divider border and dim label, anything else an ink border.
private _fnc_action = {
    params ["_parent", "_bx", "_by", "_bw", "_bh", "_label", "_style"];
    switch (_style) do {
        case "pri": {[_parent, [_bx, _by, _bw, _bh], _accent] call EFUNC(tacpad,drawFill)};
        case "armed": {[_parent, [_bx, _by, _bw, _bh], _ink] call EFUNC(tacpad,drawFill)};
        default {
            [_parent, [_bx, _by, _bw, _bh], ([_ink, _line] select (_style isEqualTo "off")), RULE_THICK] call EFUNC(tacpad,drawFrame);
        };
    };
    private _colour = switch (_style) do {
        case "pri";
        case "armed": {_ground};
        case "off": {_dim};
        default {_ink};
    };
    [_parent, [_bx + _pad * 2, _by, _bw - 4 * _pad, _bh], _label, _colour, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
};

// ------------------------------------------------------- input, wired once --
// A redraw between a press and its release eats the release, so the poll
// defers while a button is held. DISPATCHED FROM THE DISPLAY, NOT FROM
// CONTROLS: the 703 press log proved input reaches the dialog while not one
// control-attached handler on the action slab ever fired, so the actions hang
// their rects in QGVAR(supportHotspots) and this hit-tests them. Hung once per
// display - the dialog, or the device dialog on the tablet, where it stands
// down whenever the board is not the open app.
if (!(_display getVariable [QGVAR(pressWired), false])) then {
    _display setVariable [QGVAR(pressWired), true];
    _display displayAddEventHandler ["MouseButtonDown", {
        params ["", "_button", "_mx", "_my"];
        if (HOST_DEVICE && {(uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo SUP_APP}) exitWith {false};
        uiNamespace setVariable [QGVAR(supportMouseHeld), true];
        if (_button isNotEqualTo 0) exitWith {false};

        // ANY PRESS THAT IS NOT RTB DISARMS RTB - the handoff's "blur
        // disarms". A press on nothing redraws so the label comes back.
        private _armedRtb = missionNamespace getVariable [QGVAR(supportRtbArmed), []];
        private _spots = uiNamespace getVariable [QGVAR(supportHotspots), []];
        private _idx = _spots findIf {
            _x params ["_hx", "_hy", "_hw", "_hh"];
            _mx >= _hx && {_mx <= _hx + _hw} && _my >= _hy && {_my <= _hy + _hh}
        };
        private _at = format ["%1 %2", round (_mx * 1000) / 1000, round (_my * 1000) / 1000];
        if (_idx > -1) then {
            (_spots select _idx) params ["", "", "", "", "_fnc", "_name"];
            INFO_2("appSupport: press [%1] -> %2",_at,_name);
            if (_name isNotEqualTo "RTB" && {_armedRtb isNotEqualTo []}) then {
                missionNamespace setVariable [QGVAR(supportRtbArmed), []];
            };
            [] call _fnc;
        } else {
            INFO_1("appSupport: press [%1] -> no action",_at);
            if (_armedRtb isNotEqualTo []) then {
                missionNamespace setVariable [QGVAR(supportRtbArmed), []];
                {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            };
        };
        false
    }];
    _display displayAddEventHandler ["MouseButtonUp", {
        uiNamespace setVariable [QGVAR(supportMouseHeld), false];
        false
    }];
};

// ---------------------------------------------------------------- the map ---
// The dialog's own control on the vanilla map, laid into the hole every draw
// (the tab row moved the hole's top below where dialog.hpp puts it) - with
// ctrlMapSetPosition, because a map moved by ctrlSetPosition keeps its
// viewport at the declared rect and every click and centring lands off by
// the difference (the devices overlay found that, 2026-10-20). On the tablet
// the device screen's map, which already fills the app area under the hole -
// left where it is.
private _map = if (_onHost) then {_display displayCtrl IDC_HOST_MAP} else {_display displayCtrl 8961};
if (!_onHost && {!isNull _map}) then {
    _map ctrlMapSetPosition _hole;
};

// Handlers hung ONCE per map control, not per redraw. The click is a pick into
// whichever point row is armed - a map click names no marker and answers any
// marker list that was open. On the tablet the same control serves the whole
// suite, so both stand down unless the board is the open app, and a click only
// counts inside the hole.
if (!isNull _map && {!(_map getVariable [QGVAR(supportWired), false])}) then {
    _map setVariable [QGVAR(supportWired), true];

    _map ctrlAddEventHandler ["MouseButtonDown", {
        params ["_map", "_button", "_mx", "_my"];
        if (_button isNotEqualTo 0) exitWith {false};
        if (HOST_DEVICE) then {
            if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo SUP_APP) exitWith {_button = -1};
            (uiNamespace getVariable [QGVAR(supportHole), []]) params [["_hx", 0], ["_hy", 0], ["_hw", 0], ["_hh", 0]];
            if (_mx < _hx || _mx > _hx + _hw || _my < _hy || _my > _hy + _hh) then {_button = -1};
        };
        if (_button isNotEqualTo 0) exitWith {false};

        private _world = _map ctrlMapScreenToWorld [_mx, _my];
        private _slot = missionNamespace getVariable [QGVAR(supportSlot), SUP_SLOT_TARGET];
        INFO_2("appSupport: map click -> slot %1 at %2",_slot,_world);
        [_slot, [_world # 0, _world # 1, 0], ""] call FUNC(supportPointSet);
        missionNamespace setVariable [QGVAR(supportPickMarker), false];
        {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        false
    }];

    _map ctrlAddEventHandler ["Draw", {
        if (HOST_DEVICE && {(uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo SUP_APP}) exitWith {};
        _this call FUNC(supportMapDraw);
    }];
};

// CENTRED ON THE TASK POINT, OR THE MAN, WHEN THE BOARD OPENS. The dialog's map
// zooms in on it; the tablet's keeps its zoom and pans so the point lands in
// the middle of the hole, not under the form.
if (_fresh && {!isNull _map}) then {
    private _centre = missionNamespace getVariable [QGVAR(supportPoint), []];
    if (_centre isEqualTo []) then {_centre = getPosATL player};
    if (_onHost) then {
        // The device lays its map over exactly the host rectangle
        // (jmfsb_devices fnc_onLoad), so that is the map's own centre.
        HOST_RECT params ["_mpx", "_mpy", "_mpw", "_mph"];
        private _mid = _map ctrlMapScreenToWorld [_mpx + _mpw / 2, _mpy + _mph / 2];
        private _in = _map ctrlMapScreenToWorld [(_hole # 0) + (_hole # 2) / 2, (_hole # 1) + (_hole # 3) / 2];
        _map ctrlMapAnimAdd [0, ctrlMapScale _map, [
            (_centre # 0) + (_mid # 0) - (_in # 0),
            (_centre # 1) + (_mid # 1) - (_in # 1)
        ]];
    } else {
        _map ctrlMapAnimAdd [0, 0.1, _centre];
    };
    ctrlMapAnimCommit _map;
};

// ------------------------------------------------------------- the poll -----
// Availability refreshes while the board lives. On the vanilla map it stands
// down when the dialog closes and gives the map back its panels; on the tablet
// when the board is no longer the open app - FUNC(appClose) has already done
// the giving back there.
private _existing = uiNamespace getVariable [QGVAR(supportPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(supportPFH), [{
    params ["", "_handle"];

    if (!SUP_SHOWN) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(supportPFH), -1];

        // ONLY IF SUPPORT IS STILL THE OPEN APP, and only for the dialog. This
        // branch fires up to two seconds after the dialog closed - time enough
        // for the player to have opened another app.
        if (HOST_NATIVE && {(uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo SUP_APP}) then {
            uiNamespace setVariable [QEGVAR(tacpad,appCurrent), ""];
            {
                (_x param [0, controlNull]) ctrlShow true;
            } forEach values (missionNamespace getVariable [QEGVAR(tacpad,open), createHashMap]);
        };
    };

    // THE POLL ONLY REDRAWS WHEN THE DATA CHANGED - a full teardown every two
    // seconds is the flicker the user reported.
    private _now = str (call EFUNC(support,assets))
        + str (crew (uiNamespace getVariable [QGVAR(supportVeh), objNull]));
    if (_now isEqualTo (uiNamespace getVariable [QGVAR(supportSeen), ""])) exitWith {};

    // Defer - NOT skip - while a mouse button is held.
    if (uiNamespace getVariable [QGVAR(supportMouseHeld), false]) exitWith {};
    uiNamespace setVariable [QGVAR(supportSeen), _now];

    [SUP_APP] call EFUNC(tacpad,openApp);
}, 2, []] call CBA_fnc_addPerFrameHandler];

// ------------------------------------------------------- the marker picker --
// MKR on a point row swaps the form for this list until a marker is picked or
// the pick is cancelled. ONLY MARKERS A PLAYER PLACED - engine name
// "_USER_DEFINED #..." - the user's rule for every marker list. No colour
// filtering - a mate's red contact mark is exactly what fires get aimed at.
if (_picking) exitWith {
    // Only CLOSE on the action stack - stale rects from the last draw would
    // make invisible buttons pressable over the marker list.
    [_act, _ax, _ry, _abw, _aBtnH, "CLOSE", "act"] call _fnc_action;
    uiNamespace setVariable [QGVAR(supportHotspots), [[_x0 + _mapL + _ax, _y0 + _mapB + _ry, _abw, _aBtnH, _fnc_close, "CLOSE"]]];

    private _mkrs = allMapMarkers select {
        ((_x select [0, 13]) isEqualTo "_USER_DEFINED")
        && {!("taor" in toLower markerText _x)}
    };
    _mkrs = _mkrs apply {[markerPos _x distance2D player, _x]};
    _mkrs sort true;

    private _fit = (floor ((_bodyH - _rowH * 3) / _rowH)) max 1;
    private _shown = _mkrs select [0, _fit];

    private _rowY = [_padY, "MARKER", format ["%1 of %2 - nearest first", count _shown, count _mkrs]] call _fnc_group;

    if (_shown isEqualTo []) then {
        [_body, [0, _rowY, _fw, _rowH], "NO MARKERS ON THE MAP", "", "off"] call FUNC(supportCell);
        _rowY = _rowY + _rowH;
    };

    {
        _x params ["_dist", "_mkr"];

        // A placed marker with no text has only its machine name, and
        // "_USER_DEFINED #23" is not a name anybody briefed.
        private _label = markerText _mkr;
        if (_label isEqualTo "") then {_label = "PLACED MARKER"};

        private _distText = if (_dist < 1000) then {format ["%1 M", round _dist]} else {format ["%1 KM", (round (_dist / 100)) / 10]};

        [
            _body, [0, _rowY, _fw, _rowH], toUpper _label,
            format ["GRID %1 · %2", mapGridPosition (markerPos _mkr), _distText], "rest",
            {
                params ["_ctrl"];
                (_ctrl getVariable [QGVAR(pick), []]) params [["_mkr", ""], ["_label", ""]];
                (markerPos _mkr) params ["_px", "_py"];
                // Into whichever row was armed when MKR was pressed - the
                // marker list is one screen serving every point row.
                [missionNamespace getVariable [QGVAR(supportSlot), SUP_SLOT_TARGET], [_px, _py, 0], _label] call FUNC(supportPointSet);
                missionNamespace setVariable [QGVAR(supportPickMarker), false];
                {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            },
            [_mkr, _label]
        ] call FUNC(supportCell);

        _rowY = _rowY + _rowH;
    } forEach _shown;

    _rowY = _rowY + _padY;
    [_body, [_pad, _rowY, _fw - 2 * _pad, _rowH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
    [_body, [_pad * 3, _rowY, _fw - 6 * _pad, _rowH], "CANCEL", _ink, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_pad, _rowY, _fw - 2 * _pad, _rowH], {
        missionNamespace setVariable [QGVAR(supportPickMarker), false];
        {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
};

// ------------------------------------------------------------ the verdict --
// SAID FIRST, AT THE TOP OF THE FORM, in a row that is always reserved so the
// form never jumps. A SLAB, EDGE TO EDGE: ink for what the asset took, surface
// with accent-700 type for what it would not.
private _rowY = _padY;
(missionNamespace getVariable [QGVAR(supportFlash), []]) params [["_flashText", ""], ["_flashOk", true], ["_flashAt", -99]];
if (_flashText isNotEqualTo "" && {CBA_missionTime - _flashAt < 12}) then {
    [_body, [0, _rowY, _fw, _rowH], ([_surface, _ink] select _flashOk)] call EFUNC(tacpad,drawFill);
    [
        _body, [_pad * 2, _rowY, _fw - 4 * _pad, _rowH],
        toUpper _flashText, ([_accentText, _ground] select _flashOk), TEXT_LABEL, true, "left", true
    ] call EFUNC(tacpad,drawText);
};
_rowY = _rowY + _rowH;

// ------------------------------------------------------------------- unit ---
// THE TAB IS THE ASSET TYPE, so the form opens on its units.
_rowY = [
    _rowY, "UNIT",
    switch (true) do {
        case (_unitRow isEqualTo []): {"Select one"};
        case (_tasked): {"Unit is on a mission — you may abort or change the current task"};
        default {"Unit is available and waiting for task"};
    }
] call _fnc_group;

if (_units isEqualTo []) then {
    [_body, [0, _rowY, _fw, _rowH], "NO SUPPORT ASSETS ANSWERING", "", "off"] call FUNC(supportCell);
    _rowY = _rowY + _rowH;
} else {
    {
        _x params ["_id", "", "_callsign", "_platform", "_status"];
        private _veh = _x param [7, objNull];
        private _meta = [toUpper _platform];
        if (_selType isEqualTo "transport" && {!isNull _veh}) then {
            _meta pushBack format ["%1 PAX", count (fullCrew [_veh, "cargo", true])];
        };
        _meta pushBack toUpper _status;
        _rowY = [_rowY, _callsign, _meta joinString " · ", ["rest", "on"] select (_selUnit isEqualTo _id), [1, _id]] call _fnc_row;
    } forEach _units;
};

// ------------------------------------------------------------------- task ---
// What the task DOES is guidance, and goes to the group label when the row is
// picked - never into the row.
_rowY = [_rowY, "TASK", _taskRow param [3, "Select one"]] call _fnc_group;

// A LONG LIST GOES TWO TO A LINE, label only - a transport offers a dozen
// tasks, and one per line pushed CONFIRM off the form.
private _twoUp = count _tasks > SUP_TASK_COLUMNS_AT;
private _colW = [_fw, _fw / 2] select _twoUp;
{
    _x params ["_id", "_label", "_meta"];
    private _state = switch (true) do {
        case (_commitLive && _cTask isEqualTo _id): {"acc"};
        case (_selTask isEqualTo _id): {"on"};
        default {"rest"};
    };
    if (_twoUp) then {
        private _col = _forEachIndex % 2;
        [_body, [_col * _colW, _rowY, _colW, _rowH], _label, "", _state, _fnc_pick, [2, _id]] call FUNC(supportCell);
        if (_col isEqualTo 1 || {_forEachIndex isEqualTo (count _tasks - 1)}) then {_rowY = _rowY + _rowH};
    } else {
        _rowY = [_rowY, _label, _meta, _state, [2, _id]] call _fnc_row;
    };
} forEach _tasks;

// -------------------------------------------------------------- the point --
// WHERE BEFORE HOW, the way a Simplex request reads: the point straight after
// the task, named for what it is - TARGET, LZ, PICKUP, DROP POINT, DROP ZONE -
// by the task's own declaration. ONE ROW PER POINT THE REQUEST CARRIES, and one
// of them is ARMED - the armed row is where the next map click or marker pick
// lands. A point picked off a marker keeps the marker's name.
private _armed = missionNamespace getVariable [QGVAR(supportSlot), SUP_SLOT_TARGET];

private _fnc_pointRow = {
    params ["_rowY", "_slot", "_label", "_hint", "_required"];

    ([_slot] call FUNC(supportPointVars)) params ["_pv"];
    private _p = missionNamespace getVariable [_pv, []];
    private _isArmed = _armed isEqualTo _slot;
    private _text = [_hint, [_slot] call _fnc_pointText] select (_p isNotEqualTo []);

    [_body, [_pad * 2, _rowY, _fw * 0.2, _rowH], _label, ([_mute, _ink] select _isArmed), TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);

    private _vx = _fw * 0.2;
    private _vw = _fw * 0.48;
    [_body, [_vx, _rowY, _vw, _rowH], ([_line, _ink] select _isArmed), ([RULE_THIN, RULE_THICK] select _isArmed)] call EFUNC(tacpad,drawFrame);
    [_body, [_vx + _pad * 2, _rowY, _vw - 4 * _pad, _rowH], _text, ([_ink, _accentText] select (_p isEqualTo [] && _required)), TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);

    // Pressing the value arms this row. The slot travels on the hit control
    // rather than being captured, because these blocks run long after the
    // draw that made them.
    private _armHit = [_body, [_vx, _rowY, _vw, _rowH], {
        params ["_ctrl"];
        missionNamespace setVariable [QGVAR(supportSlot), _ctrl getVariable [QGVAR(slotIdx), SUP_SLOT_TARGET]];
        {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _armHit setVariable [QGVAR(slotIdx), _slot];

    // MKR arms the row AND swaps the form for the marker list; CLR gives that
    // one point back - an ingress cleared is an ingress flown automatically.
    {
        _x params ["_glyph", "_cx", "_code"];
        [_body, [_cx, _rowY, _fw * 0.13, _rowH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
        [_body, [_cx, _rowY, _fw * 0.13, _rowH], _glyph, _ink, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
        private _hit = [_body, [_cx, _rowY, _fw * 0.13, _rowH], _code] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(slotIdx), _slot];
    } forEach [
        ["MKR", _fw * 0.7, {
            params ["_ctrl"];
            missionNamespace setVariable [QGVAR(supportSlot), _ctrl getVariable [QGVAR(slotIdx), SUP_SLOT_TARGET]];
            missionNamespace setVariable [QGVAR(supportPickMarker), true];
            {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }],
        ["CLR", _fw * 0.85, {
            params ["_ctrl"];
            ([_ctrl getVariable [QGVAR(slotIdx), SUP_SLOT_TARGET]] call FUNC(supportPointVars)) params ["_pv", "_nv"];
            missionNamespace setVariable [_pv, []];
            missionNamespace setVariable [_nv, ""];
            {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }]
    ];

    _rowY + _rowH + _padY * 0.5
};

_rowY = [_rowY, "LOCATION", "Click the map, or MKR for a placed marker"] call _fnc_group;
_rowY = _rowY + _padY * 0.5;
_rowY = [
    _rowY, SUP_SLOT_TARGET, _pointLabel,
    ["YOUR POSITION - CLICK THE MAP", "REQUIRED - CLICK THE MAP"] select _needsPoint,
    _needsPoint
] call _fnc_pointRow;

// THE OTHER POINTS THE TASK CARRIES, as its provider declares them - the CAS
// approach and way out, a transport's VIA legs (each click adds one) and
// its LZ or set-down point. AUTO IS A REAL ANSWER for an optional one:
// nothing picked means the provider's own choice.
{
    _x params ["_dLabel", "", "_dHint", "_dReq", "", "", "_dKey"];
    _rowY = [_rowY, _dKey, _dLabel, toUpper _dHint, _dReq] call _fnc_pointRow;
} forEach _declPoints;

// ------------------------------------------------------------- parameters --
// WHAT THIS TYPE OF REQUEST NEEDS, as the provider declares it for the picked
// task: a fire mission's ordnance, rounds, sheaf and guns; a CAS task's radius
// or passes and altitude (and ordnance for a run); a lift's height, speed and
// door guns; a drop's height. Steppers side by side or full width - see
// FUNC(supportStepper).
private _gap = _fw * 0.03;
private _half = (_fw - 4 * _pad - _gap) / 2;
private _fnc_steps = {
    params ["_rowY", "_left", ["_right", []]];
    private _stepTop = _rowY + _padY;
    if (_right isEqualTo []) exitWith {
        ([_body, [_pad * 2, _stepTop, _fw - 4 * _pad]] + _left) call FUNC(supportStepper)
    };
    ([_body, [_pad * 2 + _half + _gap, _stepTop, _half]] + _right) call FUNC(supportStepper);
    ([_body, [_pad * 2, _stepTop, _half]] + _left) call FUNC(supportStepper)
};

private _paramsGuide = "";
if (_selType isEqualTo "arty" && {_unitRow isEqualTo []}) then {_paramsGuide = "Pick a battery for its ordnance"};
if (_isJmfsbCas && _selTask isEqualTo "LOITER") then {_paramsGuide = "Gunner - ISR takes the seat on station"};
if (_taskRow isEqualTo [] && {!_legacy}) then {_paramsGuide = "Pick a task for its parameters"};

_rowY = [_rowY, ["PARAMETERS", "BEHAVIOUR"] select (_selType isEqualTo "transport"), _paramsGuide] call _fnc_group;

// A DECLARED STEPPER is [label, slot, step, min, max, display, list, bar] -
// display is a format with %1 for the value, or an array of words indexed by
// it - turned here into FUNC(supportStepper)'s own argument list.
private _fnc_declStep = {
    params [["_label", "", [""]], ["_slot", 0, [0]], ["_step", 1, [0]], ["_min", 0, [0]], ["_max", 1, [0]], ["_display", "%1", ["", []]], ["_list", [], [[]]], ["_bar", true, [false]]];
    private _v = _prm param [_slot, _min];
    if !(_v isEqualType 0) then {_v = _min};
    // Clamped as the bar and the provider clamp it: the parameter array is
    // shared across assets.
    _v = (round _v) max _min min _max;
    private _text = if (_display isEqualType []) then {
        private _word = _display param [round _v, ""];
        [str _v, _word] select (_word isEqualType "" && _word isNotEqualTo "")
    } else {
        format [_display, _v]
    };
    [toUpper _label, toUpper _text, _slot, _step, _min, _max, _list, _bar]
};

if (_declSteps isNotEqualTo []) then {
    for "_i" from 0 to (count _declSteps - 1) step 2 do {
        private _left = (_declSteps select _i) call _fnc_declStep;
        private _right = [];
        if (_i + 1 < count _declSteps) then {_right = (_declSteps select (_i + 1)) call _fnc_declStep};
        _rowY = [_rowY, _left, _right] call _fnc_steps;
    };
} else {
    switch (_selType) do {
        case "cas": {
            if (_legacy) then {
                _rowY = [
                    _rowY,
                    ["CAS RADIUS", format ["%1 M", _radius], 0, 100, 100, 1000, [], true],
                    ["ALTITUDE", format ["%1 M", _alt], 1, 50, 50, 500, [], true]
                ] call _fnc_steps;
            };
            if (_isJmfsbCas) then {
                // WHAT THE RUN COMES IN WITH: the airframe's actual stores
                // behind a leading AUTO. SLOT 10, past the two points at 8 and
                // 9 - the confirm writes those two every press.
                private _ordList = _unitRow param [5, []];
                if (_selTask isNotEqualTo "LOITER" && {_ordList isNotEqualTo []}) then {
                    private _ordIdx = (_prm param [10, 0]) max 0 min (count _ordList - 1);
                    _rowY = [_rowY, ["ORDNANCE", toUpper (_ordList param [_ordIdx, "AUTO"]), 10, 1, 0, count _ordList - 1, [], false]] call _fnc_steps;
                };
            };
        };
        case "arty": {
            if (!_legacy) exitWith {};
            // Ordnance steps through what THIS battery carries, so the screen
            // can never offer a shell the guns do not have.
            private _ordTypes = _unitRow param [5, []];
            if (_ordTypes isNotEqualTo []) then {
                private _ordIdx = ((_prm param [4, 0]) max 0) min (count _ordTypes - 1);
                (_ordTypes param [_ordIdx, []]) params [["_oName", "?"], ["_oRds", 0]];

                // THE NAME TRAVELS, NOT JUST THE INDEX - stored at 11.
                if ((_prm param [11, ""]) isNotEqualTo _oName) then {
                    _prm set [11, _oName];
                    missionNamespace setVariable [QGVAR(supportParams), _prm];
                };
                _rowY = [_rowY, ["ORDNANCE", format ["%1 · %2 RDS", _oName, _oRds], 4, 1, 0, count _ordTypes - 1, [], false]] call _fnc_steps;
            };

            _rowY = [
                _rowY,
                ["ROUNDS", str ([1, 3, 6, 12, 24] param [_prm param [5, 1], 3]), 5, 1, 0, 4, [], true],
                ["DISPERSION", format ["%1 M", _prm param [6, 100]], 6, 50, 0, 500, [], true]
            ] call _fnc_steps;

            // HOW MANY OF THE BATTERY'S TUBES FIRE, normalised to "all of
            // them" when unset or sized for a different battery.
            private _gunsMax = _unitRow param [6, 0];
            if (_gunsMax > 0) then {
                private _gunsCur = _prm param [7, 0];
                if (_gunsCur < 1 || _gunsCur > _gunsMax) then {
                    _prm set [7, _gunsMax];
                    missionNamespace setVariable [QGVAR(supportParams), _prm];
                };
                _rowY = [_rowY, ["GUNS", format ["%1 OF %2", _prm param [7, _gunsMax], _gunsMax], 7, 1, 1, _gunsMax, [], true]] call _fnc_steps;
            };
        };
        case "transport": {
            if (!_legacy) exitWith {};
            _rowY = [
                _rowY,
                ["HEIGHT", format ["%1 M", _alt], 1, 50, 50, 500, [], true],
                ["SPEED", ["LIMITED", "NORMAL", "FULL"] select _speedIdx, 3, 1, 0, 2, [], true]
            ] call _fnc_steps;
            _rowY = [_rowY, ["RULES OF ENGAGEMENT", toUpper (_roeText param [_roeIdx, ""]), 2, 1, 0, count _roeText - 1, SUP_ROE_ORDER, false]] call _fnc_steps;
        };
    };
};
_rowY = _rowY + _padY;

// ------------------------------------------------------ rules of engagement --
// CAS lists the five engine combat modes, the handoff's way; the index each
// row writes is the ALiVE provider's - see SUP_ROE_TEXT.
if (_selType isEqualTo "cas" && _legacy) then {
    _rowY = [_rowY, "RULES OF ENGAGEMENT", format ["Combat mode %1", SUP_ROE_MODES param [_roeIdx, ""]]] call _fnc_group;
    {
        [
            _body, [0, _rowY, _fw, _rowH], _roeText param [_x, ""], "", ["rest", "on"] select (_roeIdx isEqualTo _x),
            {
                params ["_ctrl"];
                private _prm = missionNamespace getVariable [QGVAR(supportParams), SUP_PARAMS_DEFAULT];
                _prm set [2, (_ctrl getVariable [QGVAR(pick), [0]]) param [0, 0]];
                missionNamespace setVariable [QGVAR(supportParams), _prm];
                {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            },
            [_x]
        ] call FUNC(supportCell);
        _rowY = _rowY + _rowH;
    } forEach SUP_ROE_LIST;
};

// ------------------------------------------------------------- passengers --
// Transport only, in whatever room the form has left.
if (_selType isEqualTo "transport" && {_unitRow isNotEqualTo []}) then {
    private _room = floor ((_bodyH - _padY - _rowY) / _rowH) - 1;
    _rowY = [_body, _rowY, _fw, _unitRow param [7, objNull], _room] call FUNC(supportPassengers);
};

// The ground under everything the form drew, and the scroll put back.
_bodyGround ctrlSetPositionH (_bodyH max (_rowY + _padY));
_bodyGround ctrlCommit 0;
if (_scroll isEqualType [] && {(_scroll param [0, 0]) > 0}) then {
    _body ctrlSetScrollValues [_scroll select 0, -1];
};

// --------------------------------------------------- READY, then CONFIRM ---
// CONFIRM TASKING STANDS APART at the foot of the form, under the checklist of
// what it is waiting for - never in the same stack as RTB and CLOSE, where a
// thumb aimed at one found the other. Each line is done (an ink square, the
// value in ink) or missing (an accent outline, the value in accent-700), and
// CONFIRM is the accent cell only when nothing is missing.
[_foot, [0, 0, _fw, _footH], _ground] call EFUNC(tacpad,drawFill);
[_foot, [0, 0, _fw, _ruleY], _ink] call EFUNC(tacpad,drawFill);
private _ckY = [_foot, 0, _fw, "READY", ["All set - confirm to send", format ["%1 missing", count _missing]] select (!_ready)] call FUNC(supportGroup);
_ckY = _ckY + _padY;

private _box = _checkH * 0.45;
{
    _x params ["_cLabel", "_cSays", "_cDone"];
    private _bx = _pad * 2;
    private _byy = _ckY + (_checkH - _box) / 2;
    private _boxW = _box * (pixelW / pixelH);
    if (_cDone) then {
        [_foot, [_bx, _byy, _boxW, _box], _ink] call EFUNC(tacpad,drawFill);
    } else {
        [_foot, [_bx, _byy, _boxW, _box], _accent, RULE_THICK] call EFUNC(tacpad,drawFrame);
    };
    [_foot, [_bx + _boxW + _pad * 2, _ckY, _fw * 0.3, _checkH], _cLabel, ([_accentText, _ink] select _cDone), TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_foot, [_fw * 0.36, _ckY, _fw * 0.64 - _pad * 2, _checkH], toUpper _cSays, ([_accentText, _mute] select _cDone), TEXT_LABEL, true, "right"] call EFUNC(tacpad,drawText);
    _ckY = _ckY + _checkH;
} forEach _checks;
_ckY = _ckY + _padY * 2;

[_foot, _ax, _ckY, _fw - 4 * _pad, _btnH, "CONFIRM TASKING", ["off", "pri"] select _ready] call _fnc_action;

private _fnc_confirm = if (_ready) then {{
    private _sel = missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]];
    // INGRESS, EGRESS AND EVERY DECLARED POINT RIDE IN THE PARAMETER ARRAY,
    // past everything ALiVE's own tasking reads, so one array serves every
    // kind of asset - see FUNC(supportRequestParams).
    private _prm = [] call FUNC(supportRequestParams);

    (
        [
            _sel # 1, _sel # 2,
            missionNamespace getVariable [QGVAR(supportPoint), []],
            _prm
        ] call EFUNC(support,request)
    ) params ["_ok", "_why"];

    // WHAT WAS ACCEPTED, IN THE WORDS OF THE THING THAT ACCEPTED IT - the
    // callsign read back off the asset list. An accepted order also becomes
    // the committed tasking, which lights its task row in the accent.
    private _said = if (_ok) then {
        missionNamespace setVariable [QGVAR(supportCommitted), [_sel # 1, _sel # 2, CBA_missionTime]];
        private _assets = call EFUNC(support,assets);
        private _row = _assets param [_assets findIf {(_x param [0, ""]) isEqualTo (_sel # 1)}, []];
        private _cs = _row param [2, "UNIT"];
        private _at = missionNamespace getVariable [QGVAR(supportPoint), []];

        if (_at isEqualTo []) then {
            format ["%1 ACCEPTED - %2", _cs, _sel # 2]
        } else {
            format ["%1 ACCEPTED - %2 ON %3", _cs, _sel # 2, mapGridPosition _at]
        }
    } else {
        _why
    };
    missionNamespace setVariable [QGVAR(supportFlash), [_said, _ok, CBA_missionTime]];
    ["SUPPORT", _said, ["high", "normal"] select _ok] call EFUNC(messaging,notify);
    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}} else {{
    // A press on CONFIRM that is not ready sends nothing and names the first
    // missing line instead of sitting silent.
    private _missing = uiNamespace getVariable [QGVAR(supportMissing), []];
    private _say = _missing param [0, "Not ready"];
    INFO_1("appSupport: confirm pressed not ready - '%1'",_say);
    missionNamespace setVariable [QGVAR(supportFlash), [_say, false, CBA_missionTime]];
    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}};

_hotspots pushBack [_x0 + _ax, _y0 + _h - _footH + _ckY, _fw - 4 * _pad, _btnH, _fnc_confirm, "CONFIRM"];

// ORDER UNIT RTB DOUBLE-CONFIRMS. The first press arms it and the label
// becomes CONFIRM RTB; a second press inside SUP_RTB_ARM_WINDOW seconds
// commits, and the window running out - or any other press, see the display
// handler - disarms it. Unavailable while the unit is idle.
(missionNamespace getVariable [QGVAR(supportRtbArmed), []]) params [["_aUnit", ""], ["_aAt", -1]];
private _rtbArmed = _tasked && _aUnit isEqualTo _selUnit && {CBA_missionTime - _aAt <= SUP_RTB_ARM_WINDOW};
private _isArty = _selType isEqualTo "arty";
[
    _act, _ax, _ry, _abw, _aBtnH,
    [["ORDER UNIT RTB", "ORDER BATTERY HOME"] select _isArty, ["CONFIRM RTB", "CONFIRM BATTERY HOME"] select _isArty] select _rtbArmed,
    ["off", ["act", "armed"] select _rtbArmed] select _tasked
] call _fnc_action;

private _fnc_rtb = if (_tasked) then {{
    private _sel = missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]];
    (missionNamespace getVariable [QGVAR(supportRtbArmed), []]) params [["_aUnit", ""], ["_aAt", -1]];

    if (_aUnit isEqualTo (_sel # 1) && {CBA_missionTime - _aAt <= SUP_RTB_ARM_WINDOW}) exitWith {
        missionNamespace setVariable [QGVAR(supportRtbArmed), []];
        missionNamespace setVariable [QGVAR(supportCommitted), []];
        ([_sel # 1, "rtb"] call EFUNC(support,request)) params ["_ok", "_why"];
        private _said = [_why, "RTB ordered."] select _ok;
        missionNamespace setVariable [QGVAR(supportFlash), [_said, _ok, CBA_missionTime]];
        ["SUPPORT", _said, ["high", "normal"] select _ok] call EFUNC(messaging,notify);
        {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    };

    INFO_1("appSupport: RTB armed for %1",_sel select 1);
    private _at = CBA_missionTime;
    missionNamespace setVariable [QGVAR(supportRtbArmed), [_sel # 1, _at]];
    [{
        params ["_at"];
        (missionNamespace getVariable [QGVAR(supportRtbArmed), []]) params ["", ["_now", -1]];
        if (_now isNotEqualTo _at) exitWith {};
        missionNamespace setVariable [QGVAR(supportRtbArmed), []];
        if (SUP_SHOWN) then {
            [SUP_APP] call EFUNC(tacpad,openApp);
        };
    }, [_at], SUP_RTB_ARM_WINDOW] call CBA_fnc_waitAndExecute;
    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}} else {{
    INFO("appSupport: RTB pressed with no tasked unit selected");
    missionNamespace setVariable [QGVAR(supportFlash), ["Nothing to recall - pick a unit that is on a task", false, CBA_missionTime]];
    {[SUP_APP] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}};

// CLOSE always closes without committing anything. Esc closes too: the
// dialog's own, or FUNC(openApp)'s on the tablet.
[_act, _ax, _ky, _abw, _aBtnH, "CLOSE", "act"] call _fnc_action;

_hotspots pushBack [_x0 + _mapL + _ax, _y0 + _mapB + _ry, _abw, _aBtnH, _fnc_rtb, "RTB"];
_hotspots pushBack [_x0 + _mapL + _ax, _y0 + _mapB + _ky, _abw, _aBtnH, _fnc_close, "CLOSE"];
uiNamespace setVariable [QGVAR(supportHotspots), _hotspots];
