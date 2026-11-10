# Main Menu

`jmfsb_main_menu`

Handle initialization of server status panel.

**Holiday crest** (user, 2026-10-31). The crest above the quick connect
buttons is the holiday's when the mission loading screen's holiday table
says so (`jmfsb_loading_fnc_holiday`: 7 days before the day through the day;
New Year's Dec 26 to Jan 2), the unit's otherwise - `XEH_mainDisplay` swaps
the picture when the menu draws. One table for the main menu, the mission
loading screen and the TAC//PAC boot screen.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_loading`

## Ships

3 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_main_menu_server1Name` | EDITBOX | 1 - Left button name |
| `jmfsb_main_menu_server1Address` | EDITBOX | 1 - Left button address |
| `jmfsb_main_menu_server1Port` | EDITBOX | 1 - Left button port |
| `jmfsb_main_menu_server1Password` | EDITBOX | 1 - Left button password |
| `jmfsb_main_menu_server1Colour` | COLOR | 1 - Left button colour |
| `jmfsb_main_menu_server2Name` | EDITBOX | 2 - Centre button name |
| `jmfsb_main_menu_server2Address` | EDITBOX | 2 - Centre button address |
| `jmfsb_main_menu_server2Port` | EDITBOX | 2 - Centre button port |
| `jmfsb_main_menu_server2Password` | EDITBOX | 2 - Centre button password |
| `jmfsb_main_menu_server2Colour` | COLOR | 2 - Centre button colour |
| `jmfsb_main_menu_server3Name` | EDITBOX | 3 - Right button name |
| `jmfsb_main_menu_server3Address` | EDITBOX | 3 - Right button address |
| `jmfsb_main_menu_server3Port` | EDITBOX | 3 - Right button port |
| `jmfsb_main_menu_server3Password` | EDITBOX | 3 - Right button password |
| `jmfsb_main_menu_server3Colour` | COLOR | 3 - Right button colour |

## Functions

<details><summary>3</summary>

- `jmfsb_main_menu_fnc_addMultiplayerButtonsLogic`
- `jmfsb_main_menu_fnc_cacheServers`
- `jmfsb_main_menu_fnc_serverStatusOnLoad`

</details>
