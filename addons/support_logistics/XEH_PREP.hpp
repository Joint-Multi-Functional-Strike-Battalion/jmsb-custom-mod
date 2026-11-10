// The modules, once per placement - many of each are allowed.
PREP(moduleLogistics);
// The old JMSB - Logistics Drop, read into the module above (2026-11-01).
PREP(moduleLegacy);
PREP(moduleCatalog);

// The catalog: the reference area's objects, read once on the server.
PREP(catalogRead);
PREP(catalogEntry);

// The support-core provider code (EFUNC(support,registerProvider)), run on
// the viewer's machine.
PREP(assets);
PREP(entityRow);
PREP(logicOf);
PREP(tasks);
PREP(task);
PREP(sitrep);
PREP(available);
PREP(assetAvailable);
PREP(preview);
PREP(overlay);
PREP(reach);
PREP(eta);
// The one order check, run on the requester's machine and again on the
// server (review S6), and the order it reads out of the parameter array.
PREP(check);
PREP(readCart);
PREP(cartNames);
PREP(countLine);

// Server: one order in by remoteExecCall from FUNC(task), the sender checked.
PREP(order);
PREP(deliver);
PREP(launch);
PREP(spawnAircraft);
PREP(spawnItem);
PREP(fillCrate);
PREP(releaseItem);
PREP(markItem);
PREP(dropTick);
PREP(slingTick);
PREP(account);
PREP(aircraftDone);
PREP(finish);
PREP(lost);
PREP(say);
// The asset's support thread, moved at the delivery's natural points.
PREP(threadState);
// Resupply and airdrop by message (2026-11-01, DESIGN_SUPPORT_MESSAGING step
// 7): the support core's server hooks - whose asset it is, a card filed to its
// box, the issuer's answers - the catalog by name, and D9 on the receipt.
PREP(side);
PREP(srvThread);
PREP(threadReply);
// STATUS answered by the core (2026-11-09).
PREP(status);
PREP(threadTimeout);
PREP(catalogFind);
// RESUPPLY's item picks (user, 2026-11-02: "we have pre made crates so the
// requested items should be a drop down of them"): the catalog's names, read
// on the viewer's machine for the composer (tacpad CHOICE_SOURCES).
PREP(catalogNames);
// On the way in (user, 2026-11-01): INBOUND - ETA, 1 MIN OUT - POP SMOKE.
PREP(inbound);
// The side's notify rail, server to the side by remoteExec (review S7).
PREP(sayLocal);
