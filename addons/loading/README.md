# Loading

`jmfsb_loading`

The loading screen.

**Mission loading** (`XEH_loadingDisplay`, on `RscDisplayLoading`): a random
unit background, the unit crest and a QUICK BRIEF panel, both hung off the
engine's own mission box (`RscDisplayLoadMission`'s `Mission` group) so they
follow it at every interface size. The crest is 512 px square at the safe
zone's left edge with its top on the box's black title bar (user, 2026-10-30:
"aligned with the mission box, double size"); without a box it keeps its old
bottom-left corner. The brief sits right of the box, 3 grid columns off it and
4 short of the safe zone's right edge, top on the box's top, in the box's own
hand: a 2.7-row black bar with QUICK BRIEF and a subtitle, and a body fitted
to its text, capped at the group's bottom. `quickBrief` reads the text off
`missionConfigFile`: the OPORD `CfgGFA_PAC >> settings >> currentOpord` names
gets its `quickBrief` attribute (subtitle = the OPORD's header title), else the
mission's `overviewText` (subtitle MISSION OVERVIEW). Nothing to show, no
mission, the engine's DLC notice up, or no room beside the box (4:3): no panel.
Structured text markup is allowed (`<br/>` for a line break).

**Holiday crests** (`CfgLoadingScreen.hpp` `Holidays`, `holiday`,
`holidayDate`; user, 2026-10-30: "run them 7 days before the holiday,
Christmas takes priority over New Year's, New Year's the 26th to Jan 2"): in
a holiday's window the crest is that holiday's, `ui\holidays\<class>.paa`
from `art/JMSB-holidays` (the 1024s, by `tools/gen_holiday_logos.py`). A
window runs from `daysBefore` days ahead of the day to `daysAfter` past it: 7
and 0 for all but New Year's, which runs Dec 26 to Jan 2. Dates are
`month` + `day`; `month` + `weekday` + `nth` (Memorial Day the last Monday of
May, Indigenous Peoples' Day the second Monday of October, Thanksgiving the
fourth Thursday of November); or `easter = 1`. Where windows overlap the
holiday nearer today wins. The eleven: New Year's Day, Valentine's Day,
St Patrick's Day, Easter, Memorial Day, Independence Day, Indigenous Peoples'
Day, Halloween, Veterans Day, Thanksgiving, Christmas. A new one is a PNG in
the art folder, a line in the generator and a class in the config. Day
counts come from `jmfsb_common_fnc_daysFromCivil` (Hinnant's days_from_civil,
so a window across New Year is plain subtraction).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`

## Ships

3 functions.

## Functions

<details><summary>3</summary>

- `jmfsb_loading_fnc_holiday`
- `jmfsb_loading_fnc_holidayDate`
- `jmfsb_loading_fnc_quickBrief`

</details>
