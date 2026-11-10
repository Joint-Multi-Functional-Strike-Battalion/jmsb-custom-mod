#!/usr/bin/env python3
"""Sign the mod's Windows extension DLLs (the mod root's *_x64.dll) with Azure
Artifact Signing, then verify them and print their SHA-256.

Run before `hemtt release`. A DLL that is already validly signed is left
alone (its hash, and its BattlEye whitelisting, stay the same); --force signs
it again.

Needs (one time; docs/SIGNING.md):
  - an Artifact Signing account and certificate profile in Azure,
  - `az login` as a user with the Certificate Profile Signer role,
  - the signing client (its Azure.CodeSigning.Dlib.dll) and the Windows SDK's
    signtool.exe,
  - tools/signing.json, the account's details (gitignored):
      {"Endpoint": "https://<region>.codesigning.azure.net",
       "CodeSigningAccountName": "...", "CertificateProfileName": "..."}

Usage: python tools/sign_dlls.py --dlib PATH\\Azure.CodeSigning.Dlib.dll [--force]
"""

import argparse
import glob
import hashlib
import os
import subprocess
import sys

TIMESTAMP_URL = "http://timestamp.acs.microsoft.com"
METADATA = os.path.join("tools", "signing.json")
SDK_BIN = r"C:\Program Files (x86)\Windows Kits\10\bin"


def signtool():
    found = sorted(glob.glob(os.path.join(SDK_BIN, "*", "x64", "signtool.exe")))
    if not found:
        sys.exit("signtool.exe not found: install the Windows SDK (Signing Tools)")
    return found[-1]


def signed(tool, path):
    return subprocess.run([tool, "verify", "/pa", "/q", path], capture_output=True).returncode == 0


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def main():
    if os.path.exists("addons"):
        root = "."
    else:
        root = ".."
    os.chdir(root)

    parser = argparse.ArgumentParser(description="Sign the mod's extension DLLs.")
    parser.add_argument("--dlib", required=True, help="path to Azure.CodeSigning.Dlib.dll (x64)")
    parser.add_argument("--force", action="store_true", help="sign again DLLs that are already signed")
    args = parser.parse_args()

    if not os.path.isfile(args.dlib):
        sys.exit(f"no dlib at {args.dlib}")
    if not os.path.isfile(METADATA):
        sys.exit(f"no {METADATA}: see this script's header")

    tool = signtool()
    dlls = sorted(glob.glob("*_x64.dll"))
    if not dlls:
        sys.exit("no *_x64.dll in the mod root")

    failed = 0
    for dll in dlls:
        if signed(tool, dll) and not args.force:
            print(f"already signed  {dll}")
            continue
        result = subprocess.run([
            tool, "sign", "/v", "/debug",
            "/fd", "SHA256",
            "/tr", TIMESTAMP_URL, "/td", "SHA256",
            "/dlib", args.dlib, "/dmdf", METADATA,
            dll,
        ], capture_output=True, text=True)
        if result.returncode != 0 or not signed(tool, dll):
            print(f"FAILED          {dll}\n{result.stdout[-2000:]}{result.stderr[-2000:]}")
            failed += 1
        else:
            print(f"signed          {dll}")

    print()
    for dll in dlls:
        state = "signed  " if signed(tool, dll) else "UNSIGNED"
        print(f"{state} {sha256(dll)}  {dll}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
