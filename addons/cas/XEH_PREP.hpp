// The module, once per placement - this system allows MANY.
PREP(moduleController);

// The support-core provider code (EFUNC(support,registerProvider)). One entity
// per module; the core that lists and drives them is neutral, so TAC//SUPPORT
// shows these beside every other provider's assets without either side
// knowing the other's name.
PREP(assets);
PREP(task);
PREP(sitrep);
PREP(assetAvailable);
PREP(preview);
PREP(overlay);
PREP(reach);

// The run itself. The server's door check on who sent an order or a recall
// (review S6), then the order and the recall.
PREP(mayTask);
PREP(request);
PREP(launch);
PREP(runTick);
PREP(abort);
// Virtual until tasked (user, 2026-11-02): the drone made in the air over the
// module when tasked, flown home and removed after the run, and the respawn
// count when one is lost.
PREP(spawnDrone);
PREP(recover);
PREP(gone);
PREP(idleStatus);
PREP(acquire);
// THE PASS (2026-11-05, modelled on how Simplex Support Services flies a
// strafe; no code of it used): one attack run of any CAS aircraft - these
// drones', support_air's jets' and helicopters' - the line-up by the AI, the
// dive flown each frame, the solution, the trigger, a bomb flown to the aim.
PREP(pickStore);
PREP(passBegin);
PREP(passTick);
PREP(passFrame);
PREP(passEnd);
PREP(passAim);
PREP(passActive);
PREP(bombDrop);
PREP(fireAt);
PREP(killed);
// Inbound, in hot, on station and off station, server to the side (or to
// everyone, for off station) by remoteExec (review S7).
PREP(inbound);
PREP(release);
PREP(onStation);
PREP(offStation);

// Shared reads, so the provider and the run cannot disagree about what a
// module is offering or whether it has anything left to offer.
PREP(entityRow);
PREP(stores);
PREP(available);
PREP(nearestTo);
// Times on the board's verdict line - support_air reads its ETAs through it.
PREP(fmtEta);

// The asset's thread (2026-11-01, DESIGN_SUPPORT_MESSAGING steps 3 and 4):
// the support core's server hooks - whose asset it is, a card filed to its
// box, the issuer's follow-ups - and the store a card asks for, which
// support_air's CAS reads too.
PREP(side);
PREP(srvThread);
PREP(threadReply);
PREP(orderStore);
// The prompts and the BDA (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4, step 5):
// what it says in the thread, no answer for 5 min, and the rounds left in a
// store - support_air reads it too. The 60 s AWAITING CLEARED HOT wait's
// question (threadWaiting) went with the 2026-11-09 flow: IN asks the
// clearance itself.
PREP(threadSay);
PREP(threadTimeout);
PREP(storesLeft);
// THE CAS FLOW (2026-11-09, docs/DESIGN_MESSAGE_TEMPLATES.md tree 3): its words
// for both CAS providers (casAsk), a strike order onto the run (runOrder),
// the TOT as a mission time (totTime - support_air reads it too), and the
// support core's STATUS hook (status).
PREP(casAsk);
PREP(runOrder);
PREP(totTime);
PREP(status);
