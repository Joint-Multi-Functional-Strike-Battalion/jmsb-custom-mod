// Whether ECOTI is on at all this frame, and the power key.
PREP(isActive);
PREP(isFullScreen);
PREP(togglePower);
PREP(toggleHideNear);

// The caches: who is in range, how much of each of them can be seen, what
// colour each is.
PREP(updateCandidates);
PREP(updateVisibility);
PREP(targetVisibility);
PREP(targetColour);
PREP(targetLabel);
PREP(targetCard);
PREP(publishFreq);

// Draw3D - draws from the caches only.
PREP(draw);
PREP(manBox);
PREP(vehicleBox);
PREP(boxRect);
PREP(labelText);
PREP(drawBoxes);
PREP(drawCompass);
// The support threads' LZs and DZs (user, 2026-11-02): the side's list read and
// its rings worked out twice a second (updateZones), drawn from that (drawZones);
// the range as the labels read it (rangeText).
PREP(updateZones);
PREP(drawZones);
PREP(rangeText);

// EachFrame - hides the boxes when the map or a dialog covers the view,
// where Draw3D does not run.
PREP(hideCovered);
// Is he looking through a Vector - the long sensor range (user, 2026-10-24).
PREP(vectorView);

// Building marks (2026-11-06): Eden, Zeus and the players' key.
PREP(markSet);
PREP(markPublish);
PREP(markTarget);
PREP(markKey);
PREP(markPick);
PREP(moduleMark);
PREP(zenMark);
PREP(buildingBox);
