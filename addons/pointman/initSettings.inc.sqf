// HOW CLOSE IS ARRIVED. An operation value: Point Man moves on to the next
// waypoint inside this, and ends the route at the last.
[
    QGVAR(arriveRadius), "SLIDER",
    ["Point Man arrival radius", "How close to a waypoint counts as reaching it, in metres. Point Man then moves on to the next waypoint, and ends the route at the last."],
    ["JMSB - Tablet & Map", "Point Man"],
    [5, 200, 25, 0],
    false
] call CBA_fnc_addSetting;
