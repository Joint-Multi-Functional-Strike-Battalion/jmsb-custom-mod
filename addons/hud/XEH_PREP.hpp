// The layer itself
PREP(open);
PREP(close);
PREP(draw);
PREP(paint);
PREP(cycle);
PREP(toggle);
PREP(slotState);

// Whether the HUD belongs on screen at all right now, and putting it there
// or taking it away. One predicate, asked by the frame handler and the draw
// tick alike - see fnc_hidden.sqf.
PREP(hidden);
PREP(setShown);

// The scanner sweep, read at most every HUD_SWEEP_TTL seconds for whichever
// tiles want it.
PREP(sweep);

// One function per readout. Each appends its draw ops to the list it is given
// (FUNC(paint) makes the controls); none of them measures anything - the data
// is whichever addon owns it.
PREP(widgetDrones);
PREP(widgetJamming);
PREP(widgetRadio);
PREP(widgetEw);
PREP(widgetSquad);
PREP(widgetTimer);
PREP(widgetAps);
