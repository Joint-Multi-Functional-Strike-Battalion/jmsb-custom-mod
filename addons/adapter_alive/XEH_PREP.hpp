PREP(ready);
PREP(commanders);
PREP(taorFor);
PREP(objectivesFor);
PREP(aaTargets);
// What air defence OUR factions field - ALiVE knows stock A3 factions only.
PREP(registerFactionAA);
PREP(artyTargets);
PREP(installations);
// The rest of what the enemy's network is made of - see docs/new.md section 7.
PREP(camps);
PREP(logisticsHubs);
PREP(radars);
// ALiVE's event log, re-raised as CBA events - see FUNC(eventListener).
PREP(eventBridge);
PREP(eventListener);
// JMSB intel into the friendly G2; jmfsb sites into the enemy OPCOM.
PREP(reportIntel);
PREP(registerSite);
PREP(requestSupply);
PREP(requestCAS);
// Client-safe reads off ALiVE's public COP broadcasts and civilian model.
PREP(virtualFriendlies);
PREP(enemyKnowledge);
PREP(hostilityAt);
PREP(respawnGearManaged);
PREP(nearProfiles);
PREP(profileGroup);
PREP(profileWaypoint);
PREP(profileIdOf);
PREP(profileAlive);
PREP(requestFire);
PREP(supportAssets);
PREP(supportSitrep);
PREP(supportTask);
PREP(supportTypes);
PREP(probe);
PREP(clusterCandidates);
PREP(bumpHostility);
PREP(profileObjects);
PREP(getData);
PREP(setData);
PREP(postReport);

// ALiVE's own opt-out, so no other addon has to name it - see the function.
PREP(profileIgnore);

// ALiVE's hints into jmfsb_notify - CfgFunctions.hpp points ALIVE_fnc_sendHint here.
PREP(sendHint);
