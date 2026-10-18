class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
        };
        class ModuleDescription;
    };

    // PLACING THIS MODULE IS THE ENABLE. No module, no air defence.
    //
    // A STOPGAP. ALiVE places air defence itself and this mod's rule is to feed
    // ALiVE rather than duplicate it - but ALiVE 3's version is not stable, so
    // this stands in until it is and is meant to be deleted rather than grown.
    //
    // What a commander gets depends on how it fights, which is read from ALiVE
    // and never asked for here: a conventional commander gets radars cueing
    // launchers, an asymmetric one gets men with MANPADS.
    class jmfsb_moduleAirDefence: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JMSB - Air Defence (temporary)";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleController));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        icon = "\a3\ui_f\data\map\markers\nato\o_antiair.paa";

        class Attributes: AttributesBase {
            class sitesPerSide: Edit {
                property = QGVAR(sitesPerSide);
                displayName = "Batteries Per Side";
                tooltip = "How many radar-and-launcher sites each conventional commander gets, at most. Asymmetric commanders get none - they get MANPAD teams instead.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('sitesPerSide',_value)]);
            };
            class launchers: Edit {
                property = QGVAR(launchers);
                displayName = "Launchers Per Battery";
                tooltip = "Launchers set back from the radar that cues them, so killing the radar and killing the launchers are separate jobs.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('launchers',_value)]);
            };
            class rearmEvery: Edit {
                property = QGVAR(rearmEvery);
                displayName = "Rearm Interval (min)";
                tooltip = "Every this many minutes the surviving battery pieces are restocked to full. 0 turns rearming off.";
                typeName = "NUMBER";
                defaultValue = "10";
                expression = QUOTE(_this setVariable [ARR_2('rearmEvery',_value)]);
            };
            // NO "Profile Batteries" ATTRIBUTE. Turning it on handed the site
            // to ALiVE's runtime profiler, and that function deletes what it
            // profiles - which is why a battery logged as fully crewed stood
            // there with nobody on it. Sites stay live and are marked
            // ALIVE_profileIgnore so nothing else virtualises them either.
            class spacing: Edit {
                property = QGVAR(spacing);
                displayName = "Battery Spacing (m)";
                tooltip = "Least distance between two batteries, so a commander does not stack all of them on one hill.";
                typeName = "NUMBER";
                defaultValue = "2500";
                expression = QUOTE(_this setVariable [ARR_2('spacing',_value)]);
            };
            // PER SIDE. One radar class for the whole map was wrong: the three
            // commanders are three different armies, and a mission that wanted
            // Russian hardware on OPFOR and Patriots on BLUFOR had no way to
            // say so. Every one of these is BLANK by default, which means "pick
            // from that commander's own faction" - so a mission only fills in
            // the sides it wants to force.
            //
            // The TAOR fields close a hole the ALiVE-derived ground has: a
            // side with no commander module - the players', usually - never
            // declares its ground, so another side whose own TAOR is blank
            // ("whole map") could legally build inside it. A marker named
            // here binds its own side AND is off limits to every other side,
            // commander or not.
            class taorWest: Edit {
                property = QGVAR(taorWest);
                displayName = "BLUFOR TAOR Markers";
                tooltip = "Comma-separated area-marker names BLUFOR air defence must stay inside. BLANK reads the BLUFOR commander's ALiVE placements. Other sides keep out of these markers either way.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('taorWest',_value)]);
            };
            class taorEast: Edit {
                property = QGVAR(taorEast);
                displayName = "OPFOR TAOR Markers";
                tooltip = "Comma-separated area-marker names OPFOR air defence must stay inside. BLANK reads the OPFOR commander's ALiVE placements. Other sides keep out of these markers either way.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('taorEast',_value)]);
            };
            class taorGuer: Edit {
                property = QGVAR(taorGuer);
                displayName = "Independent TAOR Markers";
                tooltip = "Comma-separated area-marker names Independent air defence must stay inside. BLANK reads the Independent commander's ALiVE placements. Other sides keep out of these markers either way.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('taorGuer',_value)]);
            };
            class radarWest: Edit {
                property = QGVAR(radarWest);
                displayName = "BLUFOR Radar Class";
                tooltip = "Search radar for BLUFOR commanders. BLANK picks one from the commander's own faction.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('radarWest',_value)]);
            };
            class launcherWest: Edit {
                property = QGVAR(launcherWest);
                displayName = "BLUFOR Launcher Classes";
                tooltip = "Missile launcher for BLUFOR commanders. Comma-separated for a mixed battery - one is drawn per launcher. BLANK picks from the faction.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('launcherWest',_value)]);
            };
            class manpadWest: Edit {
                property = QGVAR(manpadWest);
                displayName = "BLUFOR MANPAD Weapon";
                tooltip = "Launcher a BLUFOR MANPAD team carries. Its magazine is derived from the weapon. BLANK picks from the faction. Only added to a shooter whose own class carries no AA launcher already.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('manpadWest',_value)]);
            };
            class manpadManWest: Edit {
                property = QGVAR(manpadManWest);
                displayName = "BLUFOR MANPAD Man Class";
                tooltip = "Soldier class the BLUFOR MANPAD teams are built from. Comma-separated to mix. BLANK draws from the commander's own faction. A man who already carries an AA launcher keeps it and the MANPAD Weapon stays home.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('manpadManWest',_value)]);
            };

            class radarEast: Edit {
                property = QGVAR(radarEast);
                displayName = "OPFOR Radar Class";
                tooltip = "Search radar for OPFOR commanders. BLANK picks one from the commander's own faction.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('radarEast',_value)]);
            };
            class launcherEast: Edit {
                property = QGVAR(launcherEast);
                displayName = "OPFOR Launcher Classes";
                tooltip = "Missile launcher for OPFOR commanders. Comma-separated for a mixed battery. BLANK picks from the faction.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('launcherEast',_value)]);
            };
            class manpadEast: Edit {
                property = QGVAR(manpadEast);
                displayName = "OPFOR MANPAD Weapon";
                tooltip = "Launcher an OPFOR MANPAD team carries. BLANK picks from the faction. Only added to a shooter whose own class carries no AA launcher already.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('manpadEast',_value)]);
            };
            class manpadManEast: Edit {
                property = QGVAR(manpadManEast);
                displayName = "OPFOR MANPAD Man Class";
                tooltip = "Soldier class the OPFOR MANPAD teams are built from. Comma-separated to mix. BLANK draws from the commander's own faction. A man who already carries an AA launcher keeps it and the MANPAD Weapon stays home.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('manpadManEast',_value)]);
            };

            class radarGuer: Edit {
                property = QGVAR(radarGuer);
                displayName = "Independent Radar Class";
                tooltip = "Search radar for Independent commanders. BLANK picks one from the commander's own faction.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('radarGuer',_value)]);
            };
            class launcherGuer: Edit {
                property = QGVAR(launcherGuer);
                displayName = "Independent Launcher Classes";
                tooltip = "Missile launcher for Independent commanders. Comma-separated for a mixed battery. BLANK picks from the faction.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('launcherGuer',_value)]);
            };
            class manpadGuer: Edit {
                property = QGVAR(manpadGuer);
                displayName = "Independent MANPAD Weapon";
                tooltip = "Launcher an Independent MANPAD team carries. BLANK picks from the faction. Only added to a shooter whose own class carries no AA launcher already.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('manpadGuer',_value)]);
            };
            class manpadManGuer: Edit {
                property = QGVAR(manpadManGuer);
                displayName = "Independent MANPAD Man Class";
                tooltip = "Soldier class the Independent MANPAD teams are built from. Comma-separated to mix. BLANK draws from the commander's own faction. A man who already carries an AA launcher keeps it and the MANPAD Weapon stays home.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('manpadManGuer',_value)]);
            };
            class openGround: Edit {
                property = QGVAR(openGround);
                displayName = "Clear Ground (m)";
                tooltip = "How much open ground a battery needs around it - no trees, rocks or buildings. A radar in a wood sees nothing and a launcher in a street is a decoration, so this is deliberately large. Lower it only if a map is too dense to place anything.";
                typeName = "NUMBER";
                defaultValue = "35";
                expression = QUOTE(_this setVariable [ARR_2('openGround',_value)]);
            };
            class security: Edit {
                property = QGVAR(security);
                displayName = "Security Groups Per Battery";
                tooltip = "Infantry guarding each battery - 0, 1 or 2 groups. They stand off the hardware rather than on it, so a player who finds the radar has still not walked onto it unopposed. 0 leaves the site to its own crews.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('security',_value)]);
            };
            class teamsPerSide: Edit {
                property = QGVAR(teamsPerSide);
                displayName = "MANPAD Teams Per Side";
                tooltip = "How many shooter teams an ASYMMETRIC commander puts out, spread over its objectives. Two or three men each, placed off the objective where they can see the approach.";
                typeName = "NUMBER";
                defaultValue = "6";
                expression = QUOTE(_this setVariable [ARR_2('teamsPerSide',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Places air defence for every ALiVE commander on the map. TEMPORARY - it stands in until ALiVE 3's own air defence is stable.",
                "",
                "Conventional commanders (invasion, occupation) get radar-cued missile batteries. Asymmetric commanders get MANPAD teams instead - a guerrilla does not field a battery.",
                "",
                "Where they go is read from ALiVE: each commander's own TAOR and objectives, never anything set here. Everything placed is profiled, so it costs nothing while nobody is near it.",
                "",
                "Batteries Per Side - conventional commanders only, asymmetric get none",
                "Launchers Per Battery - set back from the radar that cues them",
                "Battery Spacing (m) - least distance between two batteries",
                "Radar / Launcher / MANPAD classes are set PER SIDE - the three commanders are three different armies. Leave any of them blank to pick from that commander's own faction.",
                "Clear Ground (m) - open ground a battery needs; a radar in a wood sees nothing",
                "MANPAD Teams Per Side - asymmetric commanders only"
            };
        };
    };

    // AN AA BASE WHERE THE MISSION MAKER PUTS IT (user, 2026-10-14). Not part
    // of the temporary commander system above and not dependent on it: no
    // Air Defence module, no ALiVE commander, no TAOR marker needed - the
    // module's position and area ARE the site.
    //
    // NO SIDE ON IT (D59). The base belongs to whoever owns its hardware - the
    // radar class's own config side, else the first launcher's, else the
    // first gun's.
    //
    // Hardware and crews stay live and out of ALiVE (profiling static AA
    // deletes it); only the guards are ALiVE-profiled.
    class jmfsb_moduleAABase: Module_F {
        scope = 2;
        scopeCurator = 0;
        displayName = "JMSB - AA Base";
        author = QAUTHOR;
        category = "jmfsb_modules";
        function = QUOTE(DFUNC(moduleAABase));
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;
        canSetArea = 1;
        icon = "\a3\ui_f\data\map\markers\nato\o_antiair.paa";

        class AttributeValues {
            size3[] = {300, 300, -1};
            isRectangle = 0;
        };

        class Attributes: AttributesBase {
            class radarClass: Edit {
                property = QGVAR(radarClass);
                displayName = "Radar Class";
                tooltip = "One search radar vehicle class, placed at the module. Its own side is the base's side. BLANK builds no radar - the side then comes from the first missile class, else the first gun class.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('radarClass',_value)]);
            };
            class missileClass: Edit {
                property = QGVAR(missileClass);
                displayName = "Missile Classes";
                tooltip = "SAM launcher classes, comma-separated - one is drawn at random per launcher. They stand on the outer ring, set back from the radar. Classes that do not exist are skipped and named in the RPT.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('missileClass',_value)]);
            };
            class missileCount: Edit {
                property = QGVAR(missileCount);
                displayName = "Missile Launchers";
                tooltip = "How many SAM launchers. Fewer stand up when the area has too little open, level ground, and the RPT says so.";
                typeName = "NUMBER";
                defaultValue = "3";
                expression = QUOTE(_this setVariable [ARR_2('missileCount',_value)]);
            };
            class gunClass: Edit {
                property = QGVAR(gunClass);
                displayName = "Gun Classes";
                tooltip = "AA gun or CIWS classes, comma-separated - one is drawn at random per gun. They stand on an inner ring close to the radar, as its point defence.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('gunClass',_value)]);
            };
            class gunCount: Edit {
                property = QGVAR(gunCount);
                displayName = "Guns";
                tooltip = "How many AA guns on the inner ring.";
                typeName = "NUMBER";
                defaultValue = "2";
                expression = QUOTE(_this setVariable [ARR_2('gunCount',_value)]);
            };
            class guards: Edit {
                property = QGVAR(guards);
                displayName = "Guard Groups";
                tooltip = "Infantry groups guarding the base - 0, 1 or 2. They stand off the hardware inside the area and are handed to ALiVE as profiles once ALiVE is up, so they cost nothing while nobody is near. Without ALiVE they stay live.";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = QUOTE(_this setVariable [ARR_2('guards',_value)]);
            };
            class guardClasses: Edit {
                property = QGVAR(guardClasses);
                displayName = "Guard Classes";
                tooltip = "Soldier classes for the guards and for any manned gun, comma-separated. BLANK draws from the radar's own faction (else the first missile or gun class's), falling back to the side's basic rifleman.";
                typeName = "STRING";
                defaultValue = "''";
                expression = QUOTE(_this setVariable [ARR_2('guardClasses',_value)]);
            };
        };

        class ModuleDescription: ModuleDescription {
            description[] = {
                "Builds an AA base inside the module's area: a radar at the module, SAM launchers on a ring around it, AA guns close in as point defence, and guards standing off the hardware.",
                "",
                "Works on its own - no Air Defence module, ALiVE commander or TAOR marker needed. The area's radius sets the spread.",
                "",
                "The base's side is the radar class's own side, else the first missile class's, else the first gun class's.",
                "",
                "Radar, launchers, guns and their crews stay live and out of ALiVE. Only the guards are ALiVE-profiled."
            };
        };
    };
};
