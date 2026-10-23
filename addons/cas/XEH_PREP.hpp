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

// The run itself.
PREP(request);
PREP(acquire);
PREP(fireAt);
PREP(killed);
PREP(egress);

// Shared reads, so the provider and the run cannot disagree about what a
// module is offering or whether it has anything left to offer.
PREP(entityRow);
PREP(stores);
PREP(available);
PREP(nearestTo);
// Times on the board's verdict line - support_air reads its ETAs through it.
PREP(fmtEta);
