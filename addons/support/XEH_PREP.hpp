// The provider API - see README.md for the contract.
PREP(registerProvider);
PREP(provider);

// The public API (TAC//MSG's SUPPORT group, the card readers, mission
// scripts): what there is ...
PREP(assets);
PREP(types);
PREP(tasks);

// ... and what may be asked of it.
PREP(canTask);
PREP(request);
// Server: the cooldown ledger, booked by remoteExec (review S6).
PREP(bookCooldown);
PREP(sitrep);
PREP(preview);
PREP(overlay);
// Who can reach one map point, best fit first (2026-11-01).
PREP(reach);
// What a card being composed would get, and its footprint (2026-11-02).
PREP(cardPreview);

// What providers answer with, and who hears it (review R1: no CBA event).
PREP(ack);
PREP(ackLocal);
PREP(onAck);

// Threads (2026-11-01): a request filed to B:SUPPORT:<assetId>, answered by
// the server as the asset. state is the providers' call; srvCallsign is
// reached by remoteExec from request and mailboxFiled.
PREP(state);
PREP(srvFiled);
PREP(srvReply);
PREP(srvCallsign);
// The asset acts on its thread (2026-11-01, DESIGN_SUPPORT_MESSAGING steps 3
// and 4): the issuer's follow-ups passed to the provider, a card filed as the
// asset (a check-in), and the card reader every CAS provider shares - the
// order, the grid, the danger-close check and the ETA words.
PREP(srvFollowUp);
// A card filed into an asset's open thread (2026-11-02): the root cards it
// takes there (threadCards, both machines) and the server's ruling on a
// player's card (srvThreadCard, messaging's onThreadCard hook).
PREP(threadCards);
PREP(assetCard);
PREP(srvThreadCard);
// The message templates (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): an
// asset given a thread (srvTake - its root, or a starter filed in a report),
// a thread's current order with its FRAGOs (threadOrder), STATUS answered by
// the core (statusReply), STATE INTENTIONS asked (askIntentions).
PREP(srvTake);
PREP(threadOrder);
PREP(statusReply);
PREP(askIntentions);
// RTB's landing point with players aboard (user, 2026-11-09).
PREP(rtbLanding);
// Who the asset takes orders from in a thread (2026-11-09).
PREP(threadIssuer);
PREP(fileCard);
PREP(threadEvent);
PREP(srvFileCard);
PREP(srvFileAs);
PREP(readOrder);
PREP(gridPos);
PREP(dangerClose);
PREP(etaText);
// REQUEST ON STATION's WILCO (user, 2026-11-02): LAUNCHING - ON STATION IN m:ss.
PREP(stationWilco);
// The AIRFRAME CHECK-IN an aircraft files on arrival on station (user,
// 2026-11-02), whoever flies it: the filler, the capability ticks, the
// ordnance line.
PREP(checkIn);
PREP(airframeCaps);
PREP(ordnanceLeft);
// The observer a call for fire names (2026-11-01, step 6 and D6).
PREP(observer);
// Step 7 (2026-11-01): the asset's prompt with the D9 waits, and a CASEVAC's
// DEFAULT destination.
PREP(prompt);
PREP(askObservers);
PREP(medicalNearest);
// Step 5 (2026-11-01): the CAS prompts - AWAITING CLEARED HOT after 60 s
// (promptCleared), IN / OFF, REQUEST BDA, RE-ATTACK?, FURTHER TASKING?, BINGO
// (casPrompt) - and the BDA kept on the thread (threadBda).
PREP(promptCleared);
PREP(casPrompt);
PREP(threadBda);
// The cards the mod carries - the mod's own card always wins (user,
// 2026-11-02) - one entry point (builtinCards) over the calls for fire
// (builtinFires) and the replies (builtinReplies); and what an aircraft says
// on its way in: INBOUND with the ETA, 1 MIN OUT - POP SMOKE and the issuer's
// popup.
PREP(builtinCards);
PREP(builtinFires);
PREP(builtinReplies);
PREP(inbound);
PREP(etaTo);
PREP(alertLocal);
PREP(popWord);
// Circle, verify the mark, cleared to land (user, 2026-11-02): a circling
// aircraft's wait (lzClear, its tick and prompts), the answers taken before
// the provider hears them (lzClearReply), the mark seen and its colour.
PREP(lzClear);
PREP(lzClearTick);
PREP(lzClearAsk);
PREP(lzClearReply);
PREP(lzMarks);
PREP(markColour);

// Assets as mailboxes (2026-11-01): TAC//MSG's TO picker lists them, reads a
// box as its call sign, and tells the server the name a root was filed to.
PREP(mailboxes);
PREP(boxName);
PREP(mailboxFiled);

// Tactical flight (user, 2026-11-01): every provider's aircraft. tactical
// puts one on the server's lights watch (tacticalTick, tacticalLights); the
// rest answer where and how high it flies.
PREP(tactical);
PREP(tacticalTick);
PREP(tacticalLights);
PREP(flightHeight);
PREP(isRotary);
PREP(approachHeight);
PREP(flyAt);
PREP(holdPoint);
// Virtual until tasked (user, 2026-11-02): a support aircraft put in the air
// flying over its module when it is tasked, clear of other aircraft.
PREP(spawnAirborne);

// Drone escorts (user, 2026-11-01, DESIGN_SUPPORT_MESSAGING 1.2): two drones
// with a lead aircraft - made and watched (escort, escortTick), the flares
// when a missile comes (escortMissile, escortFlare), removed with it
// (escortEnd); the request card's LZ security that decides a helicopter's.
PREP(escort);
PREP(escortTick);
PREP(escortMissile);
PREP(escortFlare);
PREP(escortEnd);
// ALL ATTACK (user, 2026-11-02): the escorts sent at the lead's target area,
// a tick of it, and its end.
PREP(escortAttack);
PREP(escortStrike);
PREP(escortAttackEnd);
PREP(lzSecurity);

// The thread's map pin (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3, step 8),
// client: the card held (pinRoot), the poll (pinTick), what the card and the
// asset at work draw (pinCard, pinLive), one local marker (pinMarker).
PREP(pinRoot);
PREP(pinTick);
PREP(pinCard);
PREP(pinLive);
PREP(pinMarker);

// The active LZs and DZs (user, 2026-11-02: "in AiTR lz and drop zones need to
// be highlighted"): set per thread by its provider on the server (zones),
// held past a jump's close until the stick is down (zonesHold), sent to the
// side (zonesPublish) and kept by its players (zonesLocal) for the AiTR.
PREP(zones);
PREP(zonesHold);
PREP(zonesPublish);
PREP(zonesLocal);
