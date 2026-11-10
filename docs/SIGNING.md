# Signing the extension DLLs

The Windows DLLs in the mod root (`jmsb_voice_x64.dll`, `ghostd_pacdb_x64.dll`)
get a code signature. Only `jmsb_voice_x64.dll` is loaded by players;
`ghostd_pacdb_x64.dll` ships in the release again since 2026-11-01 for a
Windows server or host, and only the server loads it. Antivirus
trusts a signed DLL more, Windows shows the publisher in its properties, and
BattlEye can see who made it.

**Unsigned and clean is the first route (2026-11-01).** Both DLLs were
rebuilt in pure Rust, without the parts antivirus flagged: the voice DLL
without Google's WebRTC library, the database DLL without .NET's NativeAOT
runtime (extensions/ghostd_pacdb, which replaced DIVINER tools/pacdb's C#).
The voice DLL scanned clean on VirusTotal. Signing stays paused.

Signing does not replace BattlEye whitelisting. Sign first, then submit the
signed file: signing changes the hash.

The service is **Azure Artifact Signing** (called Trusted Signing before 2026):
Microsoft's own, from about $10 a month. Check the current price at
<https://azure.microsoft.com/pricing/details/artifact-signing/>.

## One-time setup

1. **Azure account.** Pay-as-you-go at <https://portal.azure.com>.
2. **Signing account.** In the portal, search "Artifact Signing", then
   Create: pick a region (it sets the endpoint below) and the Basic plan.
3. **Identity check.** On the account: Identity validation > New > Public.
   - Individual: US or Canada only. Photo ID and a selfie through Microsoft
     Entra Verified ID.
   - Organization: needs a business with a verifiable history.
   - Takes from hours to days. **The signature shows the validated name** -
     for an individual, your legal name.
4. **Certificate profile.** Certificate profiles > Create > Public Trust,
   using the validated identity. Name it `jmsb`.
5. **Permission.** On the signing account: Access control (IAM) > Add role
   assignment > **Artifact Signing Certificate Profile Signer** (it may still
   be listed as Trusted Signing Certificate Profile Signer) > your user.
6. **This PC.**
   - Azure CLI: `winget install Microsoft.AzureCLI`
   - The signing client: the NuGet package Microsoft.Trusted.Signing.Client
     (or its renamed successor). Unzip it; you need
     `bin\x64\Azure.CodeSigning.Dlib.dll` from it. It needs the .NET 8
     runtime.
   - signtool comes with the Windows SDK (already here:
     `C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64`).
7. **`tools/signing.json`** (gitignored), from the account's overview page:

   ```
   {
     "Endpoint": "https://wus2.codesigning.azure.net",
     "CodeSigningAccountName": "<account name>",
     "CertificateProfileName": "jmsb"
   }
   ```

   The endpoint is the account's region (wus2 = West US 2, eus = East US, ...).

## The free route: SignPath Foundation (chosen 2026-11-01)

SignPath Foundation signs open-source projects for free, with its own
certificate (the publisher shown is "SignPath Foundation"). It signs only
builds made by GitHub Actions from the public repository.

- `extensions/jmsb_voice` is MIT for this (its `LICENSE`); the rest of the mod
  stays APL-SA. Its README carries the code signing policy SignPath asks for.
- `.github/workflows/jmsb_voice.yml` builds the DLL on GitHub's Windows
  machines on every push that touches the extension, or by hand. It signs only
  once these are set on the repository (Settings > Secrets and variables >
  Actions): variables `SIGNPATH_ORGANIZATION_ID`, `SIGNPATH_PROJECT_SLUG`,
  `SIGNPATH_POLICY_SLUG`, secret `SIGNPATH_API_TOKEN`.
- Apply at <https://signpath.org/apply> with the repository URL, the MIT
  license, and what is signed (`jmsb_voice_x64.dll`). GitHub and SignPath both
  need two-factor sign-in on the account.
- The signed DLL from the workflow's `jmsb_voice_x64-signed` artifact goes in
  the mod root, its hash in `tools/dlls.sha256`, then to BattlEye.
- `ghostd_pacdb_x64.dll` is built from `extensions/ghostd_pacdb` since
  2026-11-01; it would need its own workflow. It does not reach players, so
  it can wait.

## Every release with a changed DLL

1. Build the DLL and copy it to the mod root (extensions/jmsb_voice/README.md;
   pacdb: extensions/ghostd_pacdb/README.md).
2. `az login`
3. `python tools/sign_dlls.py --dlib C:\path\to\bin\x64\Azure.CodeSigning.Dlib.dll`

   It signs each unsigned `*_x64.dll` in the mod root, verifies it, and prints
   every DLL's state and SHA-256. A DLL already signed is left alone, so its
   hash and whitelisting stay; `--force` signs it again.
4. Look the SHA-256 up on VirusTotal. Report false positives to Microsoft
   (<https://www.microsoft.com/wdsi/filesubmission>, software developer).
5. Send the signed DLL to BattlEye for whitelisting (support@battleye.com or
   their web form: file name, what it does, download link, source link).
6. `hemtt release`.

The Linux `.so` files run only on the server: no signing, no BattlEye.

## Why a reviewer might look twice at jmsb_voice_x64.dll

For the BattlEye submission and anyone who asks:

- **Microphone and network:** it is a voice client. It opens the microphone
  only while in a voice room and sends audio to the unit's own voice server,
  LiveKit or Mumble, as the server's settings say.
- **No keyboard, screen or video code** since 2026-11-01: Google's WebRTC
  library (and with it `GetAsyncKeyState` and the screen-capture glue) was
  replaced by pure Rust WebRTC. It exports only Arma's entry points.
- **About 10 MB:** pure Rust WebRTC, TLS, libopus and RNNoise linked in, with
  no other files needed.
- **Source:** `extensions/jmsb_voice` (Rust). Nothing is packed or obfuscated.
