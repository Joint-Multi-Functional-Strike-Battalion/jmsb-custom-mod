// The shared row. Every list in the suite is drawn with it, so they cannot
// drift apart in padding, type size or divider weight.
PREP(row);
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

// Tile contents, in one place so the band has one source
PREP(tileData);

// Full-size apps
PREP(appComms);
PREP(appHack);
PREP(appIntel);
PREP(appScanner);
PREP(appTimer);
PREP(timerState);
PREP(timerSet);
PREP(alarmAtDelay);
PREP(appSettings);
PREP(appSquad);
PREP(appSupport);
PREP(appWeather);
PREP(appRadio);
PREP(roleTiles);
PREP(setSetting);
PREP(settingLocked);
PREP(settingStep);
PREP(settingCycle);
PREP(missionSchemes);
PREP(toggleNet);
PREP(supportGroup);
PREP(supportCell);
PREP(supportHover);
PREP(supportTint);
PREP(supportStepper);
PREP(supportPassengers);
PREP(supportMapDraw);
PREP(supportMapLive);
PREP(supportPointVars);
PREP(supportPointSet);
PREP(supportRequestParams);

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
PREP(appRadioCalls);
PREP(appRadioContacts);
PREP(appRadioLive);
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
