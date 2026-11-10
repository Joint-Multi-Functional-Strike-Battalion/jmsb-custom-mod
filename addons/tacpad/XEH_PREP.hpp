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

// Live screens (code review R8): build once, then change words and colours in
// place; a change key to skip a redraw that would draw the same; one redraw
// per frame.
PREP(retext);
PREP(changed);
PREP(liveStore);
PREP(liveApply);
PREP(nextFrameOnce);

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
// The one chip primitive (notes, 2026-10-30), and its measure
PREP(drawChip);
PREP(chipWidth);
PREP(readerPreview);
PREP(readerCard);
// A filed card as one key/value column (2026-11-02): its rows, and the column.
PREP(readerKvRows);
PREP(readerKv);
PREP(readerReplies);
PREP(readerQuick);
PREP(readerQuickTiles);
// What a thread takes from this player (2026-11-02) - one rule for every
// place that offers a reply - and a new task for its asset, in it.
PREP(threadLegal);
PREP(taskInThread);
// The message templates (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): a
// support request filed in a report, the FRAGO composer and its payload, the
// preview that reads either.
PREP(starterInReport);
PREP(composeFrago);
PREP(composeFragoPayload);
PREP(fragoSame);
PREP(composePreviewText);
PREP(composeShortDefault);
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
// The picker's SUPPORT group (2026-11-01): the assets' rows, how one reads,
// the group drawn, and its two-second poll.
PREP(composeToSupport);
PREP(composeToSupportLine);
PREP(composeToSupportDraw);
PREP(composeToSupportTick);
PREP(composeCard);
PREP(composeCardHead);
PREP(composeTiles);
PREP(composeHarvest);
PREP(composeSend);
// A support card's verdict beside SEND and its footprint on the map
// (2026-11-02), and the poll that takes the footprint off again.
PREP(composeFire);
PREP(composeFireTick);
// The card's autofills (report-card review, 2026-11-02): applied before every
// draw, one source each.
PREP(composeAutoFill);
// The CAS 9-line's game-filled lines (2026-11-09).
PREP(autoCas);
PREP(autoValue);
PREP(autoVehicle);
PREP(autoDamage);
PREP(autoFuel);
PREP(autoWind);
PREP(autoSquadAce);
PREP(autoAnchor);
// A choice the composer fills at runtime (choicesFrom, 2026-11-02): its picks,
// and the drop-down they are chosen from.
PREP(composeChoices);
PREP(composeDrop);
// After contact, a SITREP (user, 2026-11-02): SEND SITREP on a TIC thread, and
// the sender's watch for the contact ending.
PREP(sitrepAfterTic);
PREP(contactArm);
PREP(contactAgain);
PREP(contactCheck);
PREP(contactDrop);
PREP(contactTraffic);

// The CC line: the @ completions it drops, and the mailbox ids it resolves to.
PREP(composeCcDrop);
PREP(composeCcIds);
// @ mentions of support assets on it (2026-11-01): a name typed in full, the
// mention (TO and the asset's card), the card switch that keeps typed text,
// and the question asked before it would not.
PREP(composeMentionTyped);
PREP(composeMention);
PREP(composeMentionSwitch);
PREP(composeMentionAsk);

// Where a grid comes from when the player does not type it.
PREP(markerGrids);

// Quick answers on the walking view: numpad 6-9 answer what an asset asks.
PREP(askLocal);
PREP(askChanged);
PREP(askTraffic);
PREP(askChoice);
PREP(askList);
PREP(askItems);
PREP(askCurrent);
PREP(askView);
PREP(askKey);
