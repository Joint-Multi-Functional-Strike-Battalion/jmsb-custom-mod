#include "script_component.hpp"

// THE LEDGER IS THE SERVER'S. A request is dispatched where it was made (the
// providers' own task code decides where the work runs), but a cooldown has
// to hold for every player on the side, so the client that got an accepted
// order books it on the server by remoteExec to FUNC(bookCooldown), which
// checks the sender and publishes the whole ledger. Not a CBA event: those
// do not tell the server who sent them (review S6).
