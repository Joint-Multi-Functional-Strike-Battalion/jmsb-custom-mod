# Diag

`jmfsb_diag`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

**A client's log line (review R1).** `jmfsb_diag_fnc_log` with sendToServer
sends the line by `remoteExec` to `jmfsb_diag_fnc_srvLog`. The server writes it
into its RPT tagged with the sender's machine, name and Steam id. It was the
`jmfsb_log_text` CBA event, which let any client write any line into the
server's RPT as if the server had written it.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

5 functions.

## Functions

<details><summary>5</summary>

- `jmfsb_diag_fnc_error`
- `jmfsb_diag_fnc_info`
- `jmfsb_diag_fnc_log`
- `jmfsb_diag_fnc_srvLog`
- `jmfsb_diag_fnc_warning`

</details>
