// The modules, once per placement - many of each are allowed.
PREP(moduleCAS);
PREP(moduleTransport);
PREP(moduleLogistics);
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

// Server: one order in by remoteExec from FUNC(task), the sender checked, the
// asset type that flies it.
PREP(order);
PREP(say);
// The side's notify rail, server to the side by remoteExec (review S7).
PREP(sayLocal);

// Server: aircraft, shared by every asset type.
PREP(spawnAircraft);
PREP(prepareAircraft);
PREP(moveTo);
PREP(landAt);
PREP(homeTick);
PREP(sweep);
PREP(finish);
PREP(lost);
PREP(adopt);
PREP(respawn);
PREP(restoreCrew);
PREP(rearm);

// CAS.
PREP(casOrder);
PREP(casLaunch);
PREP(casTick);
PREP(casStrike);
PREP(casPosture);

// Transport.
PREP(transportOrder);
PREP(transportLaunch);
PREP(transportPlan);
PREP(transportTick);
PREP(transportArrive);
PREP(transportStep);
PREP(transportHome);
// Run where the passenger lives, on the server's word (review S7).
PREP(putOut);
PREP(findSignal);
PREP(canRope);
PREP(stockRopes);

// Logistics drop.
PREP(dropOrder);
PREP(dropLaunch);
PREP(dropTick);
PREP(releaseCrate);
PREP(markCrate);
PREP(fillCrate);

// QRF.
PREP(qrfSquad);
PREP(qrfOrder);
PREP(qrfLaunch);
PREP(qrfTick);
PREP(jump);
PREP(chuteTick);
PREP(qrfLanded);
