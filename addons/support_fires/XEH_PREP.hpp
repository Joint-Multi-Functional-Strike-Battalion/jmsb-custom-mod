// The four modules, once per placement - many of each are allowed - and the
// shared registration that puts any of them on the board. Both artillery
// modules are virtual batteries (setupBattery); Artillery Battery is retired.
PREP(moduleArtillery);
PREP(moduleVirtual);
PREP(moduleCruise);
PREP(moduleLoiter);
PREP(stockFromTable);
PREP(setupBattery);
PREP(register);

// The support-core provider code (EFUNC(support,registerProvider)).
PREP(assets);
PREP(task);
PREP(tasks);
PREP(sitrep);
PREP(assetAvailable);
PREP(typeList);
PREP(preview);
PREP(overlay);
PREP(reach);

// Shared reads, so the row, the refusal and the server cannot disagree about
// what an asset has left or whether it is free.
PREP(logicOf);
PREP(entityRow);
PREP(ordnance);
PREP(available);
PREP(taskDecls);
PREP(readOpts);
PREP(gunRanges);
PREP(inRange);
PREP(partners);
PREP(fmtDist);

// The one order check, run on the requester's machine and again on the
// server, and the server's own reading of who sent an order (review S6).
PREP(check);
PREP(requester);

// The server side of an order, and what the side sees of it.
PREP(request);
PREP(openMission);
PREP(abort);
PREP(finish);
PREP(mark);
PREP(unmark);
PREP(say);
PREP(sayLater);
// Server to clients by remoteExec, taken only from the server (review S7).
PREP(sayLocal);
PREP(markLocal);
PREP(unmarkLocal);
PREP(sortieDone);
PREP(threat);
PREP(detonate);

// Artillery: a Simplex fire mission, every round spawned on its descent.
PREP(ballistics);
PREP(fireMission);
PREP(fireVirtual);
PREP(aimPoint);
PREP(virtualShot);
PREP(virtualRound);
// The scatter of a round and of a salvo's aim, an ellipse along the line of
// fire, and the aiming error each correction takes down (2026-11-02).
PREP(scatter);
PREP(aimError);
PREP(layHeight);
PREP(ammoKind);

// Adjust fire (TAC//SUPPORT v2 step 6): an observer's corrections on a held
// battery, through the same order path and sender checks.
PREP(adjustFor);
PREP(adjustNext);
PREP(adjustHold);

// Call for fire by message (2026-11-01, DESIGN_SUPPORT_MESSAGING step 6): the
// support core's server hooks - whose battery, the card, the observer's
// follow-ups - and the thread the battery answers in: its salvos, SHOT and
// SPLASH, its prompts with their D9 waits, its stand-down.
PREP(side);
PREP(srvThread);
PREP(threadReply);
// A new mission or a FRAGO in the battery's thread, and its STATUS
// (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09).
PREP(threadRetask);
PREP(status);
PREP(threadFire);
PREP(threadVolley);
PREP(threadCard);
PREP(threadPrompt);
PREP(threadEnd);
PREP(threadTot);
// TARGET SHAPE, METHOD OF FIRE, RECORD AS TARGET and the stock in the
// battery's words (2026-11-02). The recorded target's marker is hidden from
// other sides by FUNC(targetLocal), from the server by remoteExec (JIP).
PREP(threadShape);
PREP(threadMethod);
PREP(stockWords);
PREP(targetPrefix);
PREP(record);
PREP(targetLocal);
// The SHOT and SPLASH cue on the caller's machine (FUNC(cueLocal) by
// remoteExec from the server), and the composer's preview of a call for fire
// before SEND - the support core's "cardPreview" hook (2026-11-02).
PREP(cue);
PREP(cueLocal);
PREP(cardPreview);
// Cruise missiles and loitering munitions by the same card (2026-11-01): one
// launch, SHOT (and SPLASH for a missile), the BDA prompt, the D9 waits.
PREP(threadStrike);
PREP(threadLaunch);

// Cruise missiles: a real projectile flown along a route.
PREP(launchCruise);
PREP(flyCruise);

// Loitering munitions: a real air vehicle that hunts.
PREP(launchLoiter);
PREP(loiterOne);
PREP(loiterTick);
PREP(pickTarget);

// The live impact areas, for the JFO watch HUD
PREP(impactSet);
