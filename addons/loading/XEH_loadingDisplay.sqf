#include "script_component.hpp"
#include "\a3\ui_f\hpp\defineResinclDesign.inc"
#include "\a3\ui_f\hpp\defineCommonGrids.inc"
/*
 * Author: veteran29
 * Initializes loading screen display and adds 1st Joint Multi-Functional Strike Battalion branding:
 * the background, the unit crest beside the engine's mission box and the QUICK BRIEF panel right of it.
 *
 * Runs after the engine's own loading script (CBA's display handlers follow BIS_fnc_initDisplay), so
 * the mission box is already filled, its description already fitted to its text, and the box already
 * faded out when there is no mission to show.
 *
 * Arguments:
 * 0: Loading display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_display"];

TRACE_1("Loading screen",_display);

private _logoWidth = LOGO_SIZE_PX * pixelW;
private _logoHeight = LOGO_SIZE_PX * pixelH;

// THE MISSION BOX the engine draws (RscDisplayLoadMission's Mission group) is
// where the crest and the brief hang off, so they follow it at every interface
// size: the group is in display coordinates, its controls inside it are not.
// The box's top is its black title bar; without a group (another variant of
// the display) the crest keeps its old corner and there is no brief.
private _ctrlMission = _display displayCtrl IDC_LOADING_MISSION;
private _boxTop = safeZoneY + safeZoneH - _logoHeight;
private _boxRight = safeZoneX;
private _boxBottom = safeZoneY + safeZoneH;
if (!isNull _ctrlMission) then {
    (ctrlPosition _ctrlMission) params ["_groupX", "_groupY", "", "_groupH"];
    (ctrlPosition (_display displayCtrl IDC_LOADING_MISSIONBACKGROUNDTOP)) params ["_barX", "_barY", "_barW"];
    _boxTop = _groupY + _barY;
    _boxRight = _groupX + _barX + _barW;
    _boxBottom = _groupY + _groupH;
};

private _picture = _display ctrlCreate ["RscPicture", -1];
_picture ctrlSetPosition [
    safeZoneX,
    _boxTop,
    _logoWidth, _logoHeight
];

// THE CREST: a holiday's in its window (CfgLoadingScreen.hpp's Holidays -
// the run-up to the day and the day itself), the unit's otherwise.
private _holiday = [] call FUNC(holiday);
private _logo = [QPATHTOEF(media,images\logo_2048.paa), getText (_holiday >> "logo")] select (!isNull _holiday);
TRACE_2("Crest",configName _holiday,_logo);
_picture ctrlSetText _logo;
_picture ctrlCommit 0;

private _month = systemTime select 1;
private _easterMonth = [] call EFUNC(common,easterDate) select 1;

private _ctrlBg = _display displayCtrl IDC_LOADINGSTART_CUSTOM_BG;
private _backgroundCfg = uiNamespace getVariable [QGVAR(backgroundCfg), configNull];
if (isNull _backgroundCfg) then {
    if (_month == _easterMonth && {selectRandom [true, false]}) then {
        _backgroundCfg = CFG_LOADING_SCREEN >> "Backgrounds" >> "bunny";
    } else {
        _backgroundCfg = selectRandom ("true" configClasses (CFG_LOADING_SCREEN >> "Backgrounds"));
    };
    uiNamespace setVariable [QGVAR(backgroundCfg), _backgroundCfg];
    TRACE_1("Loading background",_backgroundCfg);
};

_ctrlBg ctrlSetText getText (_backgroundCfg >> "path");
_ctrlBg ctrlCommit 0;

// THE QUICK BRIEF, right of the box, top on the box's top: the current OPORD's
// quickBrief or the mission's overview (FUNC(quickBrief)). Not drawn when the
// game is still starting (the splash is up), when the engine faded the box out
// (no mission), when its DLC notice has the space, when there is nothing to
// say, or when the screen has no room beside the box.
([] call FUNC(quickBrief)) params ["_briefSubtitle", "_briefText"];
private _briefX = _boxRight + BRIEF_GAP_COLS * GUI_GRID_W;
private _briefW = (safeZoneX + safeZoneW - BRIEF_RIGHT_MARGIN_COLS * GUI_GRID_W) - _briefX;
private _showBrief = _briefText isNotEqualTo ""
    && {!isNull _ctrlMission}
    && {uiNamespace getVariable ["BIS_initGame", false]}
    && {ctrlFade _ctrlMission < 1}
    && {!ctrlShown (_display displayCtrl IDC_LOADING_DLCPICTUREBACK)}
    && {_briefW >= BRIEF_MIN_COLS * GUI_GRID_W};
TRACE_3("Quick brief",_showBrief,_briefSubtitle,_briefText);

if (_showBrief) then {
    private _briefBar = _display ctrlCreate ["RscText", -1];
    _briefBar ctrlSetPosition [_briefX, _boxTop, _briefW, BRIEF_BAR_ROWS * GUI_GRID_H];
    _briefBar ctrlSetBackgroundColor COLOUR_BRIEF_BAR;
    _briefBar ctrlCommit 0;

    private _briefTitle = _display ctrlCreate ["RscText", -1];
    _briefTitle ctrlSetPosition [_briefX, _boxTop, _briefW, BRIEF_TITLE_ROWS * GUI_GRID_H];
    _briefTitle ctrlSetFontHeight (BRIEF_TITLE_ROWS * GUI_GRID_H);
    _briefTitle ctrlSetText BRIEF_TITLE;
    _briefTitle ctrlCommit 0;

    private _briefSub = _display ctrlCreate ["RscText", -1];
    _briefSub ctrlSetPosition [_briefX, _boxTop + BRIEF_SUBTITLE_ROW * GUI_GRID_H, _briefW, BRIEF_SUBTITLE_ROWS * GUI_GRID_H];
    _briefSub ctrlSetFont BRIEF_FONT_LIGHT;
    _briefSub ctrlSetFontHeight (BRIEF_SUBTITLE_SIZE * GUI_GRID_H);
    _briefSub ctrlSetTextColor COLOUR_BRIEF_SUBTITLE;
    _briefSub ctrlSetText _briefSubtitle;
    _briefSub ctrlCommit 0;

    // fitted to its text as the engine fits the mission description, and no
    // lower than the engine's own mission group reaches
    private _briefBodyTop = _boxTop + BRIEF_BODY_ROW * GUI_GRID_H;
    private _briefBody = _display ctrlCreate ["RscStructuredText", -1];
    _briefBody ctrlSetPosition [_briefX, _briefBodyTop, _briefW, _boxBottom - _briefBodyTop];
    _briefBody ctrlSetBackgroundColor COLOUR_BRIEF_BODY;
    _briefBody ctrlSetStructuredText parseText format ["<t size='%1'>%2</t>", BRIEF_BODY_TEXT_SIZE, _briefText];
    _briefBody ctrlCommit 0;
    private _briefBodyH = (ctrlTextHeight _briefBody + BRIEF_BODY_PAD) min (_boxBottom - _briefBodyTop);
    _briefBody ctrlSetPosition [_briefX, _briefBodyTop, _briefW, _briefBodyH];
    _briefBody ctrlCommit 0;
};

private _ctrlGrpLoadingStart = _display displayCtrl IDC_LOADINGSTART_LOADINGSTART;
private _loadingLabel = _display ctrlCreate ["RscStructuredText", -1, _ctrlGrpLoadingStart];
_loadingLabel ctrlSetPosition [0, 0, 1, 1];
_loadingLabel ctrlSetStructuredText parseText ([
    '<t size="1.17" shadow="2">',
    format ["Author: %1", getText (_backgroundCfg >> "author")],
    '</t>'
] joinString "");
_loadingLabel ctrlCommit 0;

_loadingLabel ctrlSetPosition [
    safeZoneW - ctrlTextWidth _loadingLabel,
    0,
    ctrlTextWidth _loadingLabel, ctrlTextHeight _loadingLabel
];
_loadingLabel ctrlCommit 0;

nil
