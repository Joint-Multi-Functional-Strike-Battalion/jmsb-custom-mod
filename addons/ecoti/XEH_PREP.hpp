// Whether ECOTI is on at all this frame, and the power key.
PREP(isActive);
PREP(isFullScreen);
PREP(togglePower);

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

// EachFrame - hides the boxes when the map or a dialog covers the view,
// where Draw3D does not run.
PREP(hideCovered);
