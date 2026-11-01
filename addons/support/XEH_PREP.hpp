// The provider API - see README.md for the contract.
PREP(registerProvider);
PREP(provider);

// What TAC//SUPPORT reads.
PREP(assets);
PREP(types);
PREP(tasks);

// What TAC//SUPPORT asks.
PREP(canTask);
PREP(request);
// Server: the cooldown ledger, booked by remoteExec (review S6).
PREP(bookCooldown);
PREP(sitrep);
PREP(preview);
PREP(overlay);

// What providers answer with, and who hears it (review R1: no CBA event).
PREP(ack);
PREP(ackLocal);
PREP(onAck);
