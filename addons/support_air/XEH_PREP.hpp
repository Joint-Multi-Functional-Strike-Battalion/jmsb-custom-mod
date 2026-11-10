// The modules, once per placement - many of each are allowed.
PREP(moduleCAS);
PREP(moduleTransport);
PREP(moduleQRF);
PREP(register);
PREP(defaultClass);
PREP(bool);

// The support-core provider code (EFUNC(support,registerProvider)), run on
// the viewer's machine.
PREP(assets);
PREP(entityRow);
PREP(tasks);
PREP(task);
PREP(sitrep);
PREP(assetAvailable);
PREP(available);
PREP(logicOf);
PREP(readParam);
PREP(readPoint);
// The one order check, run on the requester's machine and again on the
// server (review S6).
PREP(check);
// The verdict before CONFIRM and the map shapes of the picked asset.
PREP(preview);
PREP(overlay);
PREP(flightTime);
// Who can reach a clicked point - the board's reach card (2026-11-01).
PREP(reach);

// Server: one order in by remoteExec from FUNC(task), the sender checked, the
// asset type that flies it.
PREP(order);
PREP(say);
// The asset's support thread, moved at the sortie's natural points (2026-11-01).
PREP(threadState);
// The asset acts on its thread (2026-11-01, DESIGN_SUPPORT_MESSAGING steps 3
// and 4, and 1.1): the support core's server hooks - whose asset it is, a
// card filed to its box, the issuer's follow-ups - the check-in at the hold,
// and a strike flown from station.
PREP(side);
PREP(srvThread);
PREP(threadReply);
PREP(checkIn);
PREP(casJob);
// The CAS prompts and the BDA (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4, step
// 5): what it says in a thread, and a strike card for an aircraft already in
// the air (on station, or a run re-tasked). The 60 s AWAITING CLEARED HOT
// wait's question (casWaiting) went with the 2026-11-09 flow - IN asks the
// clearance itself; casFlow is that flow's keys for one order.
PREP(casSay);
PREP(casRetask);
PREP(casFlow);
// Transport and QRF by message (2026-11-01, DESIGN_SUPPORT_MESSAGING step 7):
// the cards read into a lift job and flown, its watch and the issuer's
// answers, the end; the QRF's card and answers; the aircraft's own cards,
// prompts and D9.
PREP(liftThread);
PREP(liftLegs);
PREP(liftJob);
PREP(liftGo);
PREP(liftTick);
PREP(liftReply);
// The troop load at a pickup, and the PICKUP waiting for its INSERTION
// (2026-11-08).
PREP(liftLoad);
PREP(liftEnd);
// Its open LZs and DZs for the AiTR (user, 2026-11-02, EFUNC(support,zones)).
PREP(liftZones);
PREP(qrfThread);
PREP(qrfReply);
PREP(threadCard);
PREP(threadPrompt);
PREP(threadTimeout);
// Circle, verify the mark, cleared to land (user, 2026-11-02): the support
// core's CLEARED TO LAND for a lift or a QRF circling its landing point.
PREP(liftCleared);
// ALL IN aboard (user, 2026-11-02: "need an ace interaction while in heli for
// all in"): the ACE self action's condition, and the server's end of it.
PREP(canAllIn);
PREP(srvAllIn);
PREP(canWaveOff);
PREP(srvWaveOff);
// The side's notify rail, server to the side by remoteExec (review S7).
PREP(sayLocal);

// Server: aircraft, shared by every asset type.
PREP(spawnAircraft);
PREP(prepareAircraft);
PREP(moveTo);
PREP(landAt);
// A helicopter flown Simplex's way (2026-11-05): the order on the airframe
// itself and its watch, and the flight control that takes it in to a hover
// or a landing and hands it back.
PREP(heliOrder);
PREP(heliOrderTick);
PREP(heliNoRise);
PREP(heliTake);
PREP(heliFrame);
PREP(heliRelease);
PREP(heliHeld);
PREP(homeTick);
PREP(sweep);
PREP(finish);
PREP(lost);
PREP(adopt);
PREP(respawn);
PREP(restoreCrew);
PREP(rearm);
// The respawn count (user, 2026-11-02): what an airframe lost costs - a
// virtual airframe going home costs nothing.
PREP(replace);
// Drone escorts (user, 2026-11-02: "always for fix wings", by LZ security for
// helicopters): the module's classes read and the support core asked for them
// - support_logistics and the jumpmaster call it too.
PREP(escortLaunch);
// ESCORT pressed in any transport thread (user, 2026-11-09).
PREP(escortCall);
// The support core's STATUS hook (2026-11-09).
PREP(status);
// ALL ATTACK (user, 2026-11-02): a fixed-wing CAS flight's escorts break off
// and attack the target area with the jet - and whether it may.
PREP(allAttack);
PREP(canAllAttack);

// CAS. The release is the CAS drones' pass (2026-11-05, modelled on Simplex
// Support Services' strafe; no code of it used): casStrike begins one, the
// watches tick it; casRun is an ATTACK RUN's own phases, casWinchester the
// way home with nothing left.
PREP(casOrder);
PREP(casLaunch);
PREP(casTick);
PREP(casRun);
PREP(casStrike);
PREP(casWinchester);
PREP(casPosture);

// Transport.
PREP(transportOrder);
PREP(transportLaunch);
PREP(transportPlan);
PREP(transportTick);
PREP(transportArrive);
PREP(transportStep);
PREP(transportHome);
// Why a transport cannot fly, for the write-off and its RPT line (2026-11-01)
// - and the write-off itself, every kind's (2026-11-02: a disabled airframe
// is a lost one).
PREP(flightFault);
PREP(writeOff);
// A clear spot for the rotor at a start, a stand and a landing pad, and the
// rotor wrecked before it left its airfield repaired once (2026-11-02).
PREP(clearSpot);
PREP(rotorRepair);
// Run where the passenger lives, on the server's word (review S7).
PREP(putOut);
PREP(findSignal);
PREP(canRope);
PREP(stockRopes);
// The rappel (2026-11-08): the ropes on the server, each man down his own.
PREP(rappelRopes);
PREP(rappel);

// QRF.
PREP(qrfSquad);
PREP(qrfOrder);
PREP(qrfLaunch);
PREP(qrfTick);
PREP(jump);
PREP(chuteTick);
PREP(qrfLanded);
// The message templates' transport commands (2026-11-09,
// docs/DESIGN_MESSAGE_TEMPLATES.md): HOLD and ABORT where it is (liftHold),
// EXECUTE to carry on (liftResume), MOVE (liftMove), FRAGO (liftFrago), GO
// AROUND (liftGoAround, WAVE OFF's too), a job's own order (liftOrder), what
// it says (liftSay) and STATE INTENTIONS (liftIntentions).
PREP(liftHold);
PREP(liftResume);
PREP(liftMove);
PREP(liftFrago);
PREP(liftGoAround);
PREP(liftOrder);
PREP(liftSay);
PREP(liftIntentions);
