// Templates - built on every machine in preInit, never sent over the wire.
PREP(registerTemplate);
// The cards the mod carries - the mod's own card always wins (2026-11-02).
PREP(builtinCards);
PREP(registerBuiltins);
PREP(template);
PREP(templateIds);
PREP(fieldKeys);

// Shared - the same answer must come out on the client that composed a message
// and on the server that accepted it, so validation and rendering live here
// rather than being written twice.
PREP(validate);
PREP(subject);
// A grid field as a position - the thread's anchor on the server, the
// composer's autofills on the client (report-card review, 2026-11-02).
PREP(fieldPos);
PREP(render);
// A field as printed, a FRAGO's changed lines, a thread's current order
// (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09).
PREP(fieldText);
PREP(fragoLines);
PREP(currentOrder);
PREP(notify);
PREP(netLevel);
PREP(squadNets);
PREP(setNetLevel);
PREP(follow);

// Client
PREP(linkState);
PREP(submit);
PREP(request);
PREP(open);
PREP(cltIndex);
PREP(cltReceive);
PREP(cltThread);
PREP(netStream);
PREP(roleTag);
PREP(roleNets);
PREP(railNets);
PREP(netNames);
PREP(netsApply);
PREP(platoonTags);
PREP(tagSet);
PREP(tagCallout);
PREP(cltMarker);
PREP(cltReject);
PREP(cltCacheClear);
// Hooks for the server's refusal, run by cltReject, and for traffic
// arriving, run by cltReceive (review S7).
PREP(onReject);
PREP(onReceive);

// Server. A client reaches only srvSubmit, srvRequestIndex, srvRequestThread,
// srvMarkRead and srvClaim, by remoteExecCall, and each checks the sender at
// its top (review S7).
PREP(srvSubmit);
PREP(srvThreadFor);
PREP(srvDeliver);
PREP(srvNextId);
PREP(srvBox);
PREP(srvMembers);
PREP(srvBoxesFor);
PREP(srvIndexFor);
PREP(srvRequestIndex);
PREP(srvIndexPush);
PREP(srvRequestThread);
PREP(srvMarkRead);
PREP(srvClaim);
PREP(srvSweep);
PREP(srvForward);
PREP(srvTic);
// Server hook: run after a message is filed (srvSubmit) - how the support
// core answers its threads without this addon knowing it (2026-11-01).
PREP(onFiled);
// Server hook: rules on a card filed into an open thread (srvThreadFor) - a
// support asset's re-task and its own states (2026-11-02).
PREP(onThreadCard);

// Audience tags. tagMatch is the one rule and both ends use it - the server to
// find who a tag reaches, a client to know the tag named them.
PREP(loadTemplates);
PREP(tagMatch);
PREP(srvTagged);

// Sample traffic for testing the reader against.
PREP(seedTest);
