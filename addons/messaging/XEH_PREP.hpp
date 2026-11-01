// Templates - built on every machine in preInit, never sent over the wire.
PREP(registerTemplate);
PREP(template);
PREP(templateIds);
PREP(fieldKeys);

// Shared - the same answer must come out on the client that composed a message
// and on the server that accepted it, so validation and rendering live here
// rather than being written twice.
PREP(validate);
PREP(subject);
PREP(render);
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

// Audience tags. tagMatch is the one rule and both ends use it - the server to
// find who a tag reaches, a client to know the tag named them.
PREP(loadTemplates);
PREP(tagMatch);
PREP(srvTagged);

// Sample traffic for testing the reader against.
PREP(seedTest);
