// The tools, as the TOOLS panel drives them
PREP(start);
PREP(stop);
PREP(clear);
PREP(centre);
// GO TO GRID: CENTRE on a typed grid (user, 2026-10-30)
PREP(goTo);

// Map input, hung on each map control by FUNC(attach)
PREP(attach);
PREP(hasInput);
PREP(mouseDown);
PREP(mouseUp);
PREP(mouseMove);

// Drawing
PREP(draw);
PREP(drawLeg);
PREP(drawProtractor);
PREP(drawViewshed);
PREP(label);

// Readouts
PREP(bearingText);
PREP(distanceText);
PREP(gridText);
PREP(gridCalibrate);
// A typed grid to a position - the inverse of gridText (the ARTY calculator).
PREP(gridToPos);

// MARK and VIEWSHED
PREP(mark);
PREP(viewshedStart);
PREP(viewshedStep);
PREP(viewshedCancel);

// LOS between two points (user, 2026-10-30)
PREP(losCheck);

// MAP MARKERS (user, 2026-11-01): double-click and MARK, one placement path
// through the player's marker system - the built-in card, ACE's dialog, or
// ALiVE's through jmfsb_adapter_alive.
PREP(mapDblClick);
PREP(markLabel);
PREP(markerOpen);
PREP(markerChannels);
PREP(markerOwn);
PREP(markerDelete);
PREP(markerCard);
PREP(markerCardDraw);
PREP(markerCardCells);
// The whole marker set, by tab, and its page (user, 2026-11-02).
PREP(markerCardCatalog);
PREP(markerCardIcons);
PREP(markerCardPlace);
PREP(markerCardClose);
PREP(markerAce);
PREP(markerAceInit);
PREP(markerAceDone);
