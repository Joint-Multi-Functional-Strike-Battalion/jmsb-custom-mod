// The host: which display the suite is on and the rectangle it draws in.
PREP(hostDisplay);
PREP(setHost);

// Theme and placement - the two things every panel asks the shell for.
PREP(theme);
PREP(hexOf);
PREP(rgbOf);
PREP(place);

// The drawing vocabulary. Every panel is built from these four, so a kicker is
// the same kicker and a 2px rule is the same 2px rule wherever it appears.
PREP(textH);
PREP(textPx);
PREP(textSize);
PREP(xmlSafe);

// Formatting a roster reads the same everywhere, so these sit with the shell
// rather than with the panels - the reader needs them and cannot reach up.
PREP(clock);
PREP(rankShort);
PREP(roleShort);
PREP(drawFill);
PREP(drawFrame);
PREP(drawText);
PREP(drawIcon);
PREP(drawHit);
PREP(headerMeta);

// Panel lifecycle
PREP(register);
PREP(registerApp);
PREP(build);
PREP(open);
PREP(close);
PREP(repaint);
PREP(rebuild);
PREP(fit);
PREP(diaryWatch);

// Input. hotspot is how anything in a panel becomes clickable at all.
PREP(hotspot);

// Apps
PREP(openApp);
PREP(appAlive);
PREP(appIdle);
PREP(appFrame);
PREP(appClose);
PREP(appExits);
PREP(appHost);

// The reader, as a real dialog
PREP(openReader);
PREP(readerClose);
PREP(readerDraw);
PREP(readerInput);
PREP(readerThreadView);
PREP(readerNetView);
PREP(readerComposer);
PREP(readerRail);
PREP(readerList);
PREP(readerRow);
PREP(readerChip);
PREP(readerPreview);
PREP(readerCard);
PREP(readerReplies);
PREP(readerQuick);
PREP(readerCallUnits);
PREP(readerMarkers);
PREP(readerFlash);

// Addressing. One rule for what a net name on the rail means and one list of
// everything a message can be sent to - both were written out by hand in four
// places, and the copies had already drifted.
PREP(netBox);
PREP(netLabel);
PREP(composeTargets);

// Composing, drawn into the reader's right pane rather than into a window of
// its own: the message body, the template picker, the picked template's card.
PREP(composeOpen);
PREP(composePane);
PREP(composePicker);
PREP(composeToPicker);
PREP(composeCard);
PREP(composeCardHead);
PREP(composeTiles);
PREP(composeHarvest);
PREP(composeSend);

// The CC line: the @ completions it drops, and the mailbox ids it resolves to.
PREP(composeCcDrop);
PREP(composeCcIds);

// Where a grid comes from when the player does not type it.
PREP(markerGrids);
