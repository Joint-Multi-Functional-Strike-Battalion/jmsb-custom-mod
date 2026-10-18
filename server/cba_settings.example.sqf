// SERVER CBA SETTINGS - the TAC//PAC database (user, 2026-10-17).
//
// Put this file on the DEDICATED SERVER as
//     <Arma 3 Server folder>\userconfig\cba_settings.sqf
// and start the server with -filePatching, or CBA will not read it.
// Replace the placeholder with the jmsb_pac connection string from Atlas
// (Database > Connect > Drivers). NEVER commit the real string to this repo.
//
// A CBA SETTING IS SENT TO EVERY CLIENT: whoever joins gets this string. Keep
// the Atlas user to readWrite on the jmsb database only, and Atlas Network
// Access to the game server's IP alone (see addons/pac/initSettings.inc.sqf).
// Not sent to anyone: leave the setting empty and give the server
// GHOSTD_PACDB_URL in its environment, or pacdb.json in its root, instead.

// Where the database is - read once, at mission start.
force force jmfsb_pac_serviceUrl = "mongodb+srv://USER:PASSWORD@CLUSTER.mongodb.net/";

// Stop the boot with a PAC BOOT FAILED block in the .rpt when the database
// cannot be read - the JMSB missions ship no config folder, so without the
// database there are no roles, arsenals or radios.
force force jmfsb_pac_svcRequired = true;
