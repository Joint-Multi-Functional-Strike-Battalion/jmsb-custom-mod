# Steam Workshop upload

| File | Where it goes |
|---|---|
| `preview.png` | Publisher **Preview image** (1024x1024, under Steam's 1 MB limit) |
| `description.txt` | Workshop **Description** (Steam BBCode, under the 8000-character limit) |
| `changenotes.txt` | Publisher **Change note** for the first upload |
| `banner.png`, `header_*.png` | Images inside the description - see below |

## The images in the description

Steam only shows description images that are online. These are served by the
unit site: the three files are in the website repo at `public/steam/`, so after
the site's next build and deploy they are at

    https://jmsb.info/steam/banner.png
    https://jmsb.info/steam/header_features.png
    https://jmsb.info/steam/header_credits.png

and `description.txt` already points at those addresses. Changing an image is
changing it in `public/steam/` and redeploying the site - the Workshop page
picks it up without being edited.

## Required items

On the Workshop page set **Required items**: CBA_A3, ACE and DUI - Squad Radar.
The description names them in one line and lists no other mods (user,
2026-10-17); Steam's Required items box is where subscribers see them.
`header_requirements.png` is kept here unused.

## Upload

Use **Arma 3 Tools > Publisher** on the release folder
(`.hemttout/release`), or the `releases/` zip unpacked to `@jmfsb`.
