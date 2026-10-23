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

// The server side of an order, and what the side sees of it.
PREP(request);
PREP(openMission);
PREP(abort);
PREP(finish);
PREP(mark);
PREP(unmark);
PREP(sayLater);
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

// Cruise missiles: a real projectile flown along a route.
PREP(launchCruise);
PREP(flyCruise);

// Loitering munitions: a real air vehicle that hunts.
PREP(launchLoiter);
PREP(loiterOne);
PREP(loiterTick);
PREP(pickTarget);
