// The shared row. Every list in the suite is drawn with it, so they cannot
// drift apart in padding, type size or divider weight.
PREP(row);
// ...and the shared key/value list (review 2026-11-01, decision R2)
PREP(kvRow);
PREP(readerRow);
PREP(ammoState);
PREP(radioState);
PREP(radioPublish);
PREP(appDrones);
PREP(appJamming);

// Panels
PREP(panelTiles);
PREP(panelSquad);
PREP(panelReader);
PREP(panelTools);
PREP(panelToolsBtn);
PREP(panelSettings);
PREP(panelHide);
PREP(panelTic);
PREP(ticSend);

// Tile contents, in one place so the band has one source, and the band's
// order of them, shared with the settings
PREP(tileData);
// ...and a tile's live words and colours, written in place on refresh (R8)
PREP(tileLive);
PREP(tileOrder);
// ...and the device arrows' page turn (user, 2026-10-31)
PREP(tilePageStep);

// Full-size apps
PREP(appComms);
PREP(appHack);
PREP(appIntel);
PREP(appScanner);
PREP(scannerLive);
PREP(appTimer);
PREP(timerLive);
PREP(timerClock);
PREP(timerState);
PREP(timerSet);
PREP(alarmAtDelay);
PREP(appSettings);
PREP(appMenu);
PREP(appSquad);
// ...its MEMBER page, the BFT mark on a row and a man's reach on DATA
PREP(appSquadMember);
PREP(squadIcon);
PREP(squadLink);
PREP(appWeather);
PREP(appRadio);
PREP(roleTiles);
PREP(setSetting);
PREP(settingLocked);
PREP(settingStep);
PREP(settingCycle);
PREP(missionSchemes);
PREP(toggleNet);

// RADIO / DRONES / HACK boards (docs/DESIGN_TABLET_APPS.md) - the shared panel
// vocabulary, then each board's pages and readers.
PREP(appPagePanel);
PREP(appPageTabs);
PREP(appPageButton);
PREP(appPageBar);
PREP(radioCalls);
PREP(radioRole);
PREP(radioGroup);
PREP(radioDial);
PREP(radioCanAdd);
PREP(radioQuick);
PREP(radioVon);
PREP(radioRfNodes);
PREP(radioRfQuality);
PREP(appRadioKey);
PREP(appRadioNets);
PREP(appRadioSounds);
PREP(appRadioButtons);
PREP(appRadioCalls);
// the voice server's calls, no limit to how many (user, 2026-11-01)
PREP(appRadioCallList);
PREP(appRadioContacts);
PREP(appRadioLive);
// the call's picture (user, 2026-10-28: a camera on the caller, flips to his view)
PREP(callFeed);
PREP(callFeedUnit);
PREP(callCamFlip);
PREP(appRadioManage);
// the RTO's nets on MANAGE (user, 2026-10-22: "allow rtos to add custom channels")
PREP(radioCustom);
PREP(radioSquads);
PREP(radioTick);
PREP(radioCustomPanel);
PREP(radioMembersPanel);
PREP(radioMembersToggle);
PREP(appDronesData);
PREP(appDronesKey);
PREP(appDronesFleet);
PREP(appDronesFeed);
PREP(appDronesEnemy);
PREP(appDronesCamera);
PREP(appDronesAction);
PREP(appDronesPick);
PREP(appHackNodes);
PREP(appHackList);
PREP(appHackAction);
PREP(appHackLog);
PREP(appHackTrack);

// The notices log, opened from settings, the MSG tile and the reader rail.
PREP(openLog);
// The LOG app - the notices log in the MENU and on a tile (2026-11-09).
PREP(appLog);
// The player's live-tile layout: which tiles, in which slots.
PREP(tileLayout);
PREP(tileLayoutSet);
// ...and every tile it can place, the providers' included (notes, 2026-10-30).
PREP(tileChoices);
// ARTY: the artillery team's calculator on ACE's solver, and its gun.
PREP(appArty);
PREP(artyGun);
PREP(artySolve);
