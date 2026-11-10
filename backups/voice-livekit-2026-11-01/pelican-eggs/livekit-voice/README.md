# LiveKit voice (JMSB)

Pelican egg for the JMSB mod's voice server: LiveKit, the echo test bot, and
optional encryption (TLS).

Image: `yonvclaw/jmsb-livekit:latest`. Pelican pulls it on every start, so a
new push plus a restart updates the server. The egg doesn't change.

## Ports

Give the server three allocations:

| Allocation | Protocol | Default | Variable |
|---|---|---|---|
| Primary | TCP | 7880 | the primary allocation (signalling; players connect here) |
| Extra 1 | UDP | 7882 | UDP port (all voice audio) |
| Extra 2 | TCP | 7881 | TCP port (fallback when UDP is blocked) |

## Variables

| Variable | What |
|---|---|
| API key / API secret | Shared with the Arma server: put the same two in its CBA settings (JMSB - Radio & Voice > Voice server (LiveKit)). Secret: 32+ characters. |
| UDP port / TCP port | The numbers of the two extra allocations. |
| Use external IP | true on a public server. |
| Log level | info. debug only to chase a problem. |
| Echo test | true: the bot answers ECHO TEST calls from in game. |
| Encryption (TLS) | false (default) or true. See below. |

## Encryption (optional)

Off: players connect with `ws://`. The voice audio is always encrypted, but
the sign-in (the token) travels in the clear.

On: players connect with `wss://`. The container serves the node's own
Let's Encrypt certificate on the primary port. It gets no certificate of its
own and needs no port 80 or 443.

What you need:
- The node's name points at the IP the voice server's allocations are on.
  Ours is `game9001.ghostsofbattle.com` -> 172.93.101.237.
- That name has a certificate from certbot (the one Wings uses), in
  `/etc/letsencrypt/live/game9001.ghostsofbattle.com/`.

### 1. Copy the certificate where the container can read it (node, as root)

Containers run as Wings' user, not root, and certbot's key is readable only
by root. A certbot deploy hook copies it on every renewal.

Find Wings' user id:

```
grep -A6 '^  user:' /etc/pelican/config.yml
```

It shows `uid:` and `gid:` (often 988). Put them in USER_ID and GROUP_ID
below.

Create `/etc/letsencrypt/renewal-hooks/deploy/jmsb-voice-cert`:

```
#!/bin/sh
# Copies the node's certificate for the JMSB voice server container.
NAME=game9001.ghostsofbattle.com
DIR=/var/lib/pelican/voice-cert
USER_ID=988
GROUP_ID=988
install -d -m 750 -o $USER_ID -g $GROUP_ID $DIR
install -m 640 -o $USER_ID -g $GROUP_ID /etc/letsencrypt/live/$NAME/fullchain.pem $DIR/fullchain.pem
install -m 600 -o $USER_ID -g $GROUP_ID /etc/letsencrypt/live/$NAME/privkey.pem $DIR/privkey.pem
```

Make it executable and run it once now:

```
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/jmsb-voice-cert
/etc/letsencrypt/renewal-hooks/deploy/jmsb-voice-cert
ls -l /var/lib/pelican/voice-cert
```

The listing should show `fullchain.pem` and `privkey.pem`, owned by that id.

### 2. Allow the folder in Wings (node, as root)

In `/etc/pelican/config.yml`, add the folder to `allowed_mounts` (create
the key at the top level if it isn't there):

```
allowed_mounts:
  - /var/lib/pelican/voice-cert
```

Then `systemctl restart wings`.

### 3. Create the mount (panel, admin)

Admin > Mounts > Create:

| Field | Value |
|---|---|
| Name | voice-cert |
| Source | `/var/lib/pelican/voice-cert` |
| Target | `/mnt/voice-cert` (exactly this) |
| Read only | yes |
| User mountable | no |

Attach it to the LiveKit voice egg and to the node game9001. Then open the
voice server (Admin > Servers > the server > Mounts) and add voice-cert.

### 4. Turn it on

On the voice server, set **Encryption (TLS)** to true and restart it. The
console shows Caddy starting, then `starting LiveKit server`.

If the mount is missing it stops at once with:
`TLS is on but /mnt/voice-cert/fullchain.pem is missing or unreadable`.
Check steps 1-3.

### 5. Point the Arma server at it

CBA setting Voice server address:

```
wss://game9001.ghostsofbattle.com:7880
```

Use the name, not the IP: the certificate is for the name. Use the primary
port.

Check from any PC: `https://game9001.ghostsofbattle.com:7880` in a browser
shows `OK` with a padlock.

### Renewals

certbot renews the node's certificate, and the hook copies it. The container
checks the copy every hour and reloads it, with no restart and no dropped
players.

### Turning it off

Set Encryption (TLS) to false, restart the server, and change the address
back to `ws://`. The mount can stay.

## Build

From WSL (Ubuntu), in this folder:

```
docker build -t yonvclaw/jmsb-livekit:latest -t yonvclaw/jmsb-livekit:vX.Y.Z-N .
docker push yonvclaw/jmsb-livekit:latest
docker push yonvclaw/jmsb-livekit:vX.Y.Z-N
```

Then restart the server. The version tag is for rolling back.
