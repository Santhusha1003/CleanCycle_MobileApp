#!/usr/bin/env python3
"""Trusted administrator provisioning; never shipped/called by the Flutter app."""

import argparse
import json
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen

PROJECT = "cleancyclemobileapp"
ROLES = ("resident", "driver", "municipal_officer")


def _validate(uid, role):
    if not uid or len(uid) > 128 or "/" in uid or uid in (".", ".."):
        raise ValueError("Provide a valid Firebase user UID.")
    if any(ord(character) < 32 for character in uid):
        raise ValueError("Provide a valid Firebase user UID.")
    if role not in ROLES:
        raise ValueError("Unsupported assigned role.")


def assign_role(uid, role, token, *, opener=urlopen):
    """IAM-authorized PATCH of both role fields, guarded against concurrent edits.

    The administrator, not the requestedRole value, authorizes the assignment.
    No verification flags, credentials, profile fields or rules are changed.
    """
    _validate(uid, role)
    if not token.strip():
        raise ValueError("Administrator credentials are required.")
    endpoint = (
        "https://firestore.googleapis.com/v1/projects/"
        f"{PROJECT}/databases/(default)/documents/users/{quote(uid, safe='')}"
    )
    headers = {"Authorization": f"Bearer {token.strip()}"}
    with opener(Request(endpoint, headers=headers), timeout=30) as response:
        document = json.load(response)
    version = document.get("updateTime")
    if not version:
        raise ValueError("Existing user profile has no updateTime; refusing to write.")
    query = urlencode([
        ("updateMask.fieldPaths", "role"),
        ("updateMask.fieldPaths", "requestedRole"),
        ("currentDocument.updateTime", version),
    ])
    payload = {"fields": {
        "role": {"stringValue": role},
        "requestedRole": {"stringValue": role},
    }}
    headers["Content-Type"] = "application/json"
    request = Request(
        f"{endpoint}?{query}", data=json.dumps(payload).encode("utf-8"),
        headers=headers, method="PATCH",
    )
    with opener(request, timeout=30) as response:
        json.load(response)


def main(argv=None):
    parser = argparse.ArgumentParser(description=(
        "Assign an administrator-approved CleanCycle user role and synchronize "
        "requestedRole. Requires Google Cloud credentials authorized by IAM."
    ))
    parser.add_argument("--uid", required=True)
    parser.add_argument("--role", required=True, choices=ROLES)
    arguments = parser.parse_args(argv)
    try:
        _validate(arguments.uid, arguments.role)
        # No shell, credential file, token argument or token logging.
        credentials = subprocess.run(
            ["gcloud", "auth", "print-access-token"],
            check=True, capture_output=True, text=True,
        )
        assign_role(arguments.uid, arguments.role, credentials.stdout)
    except HTTPError as error:
        print(f"Role assignment failed (HTTP {error.code}); no retry was made. "
              "Check IAM access, the existing profile, and concurrent edits.", file=sys.stderr)
        return 1
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("Sign in to Google Cloud CLI with an authorized administrator account first.", file=sys.stderr)
        return 1
    except (ValueError, URLError, TimeoutError):
        print("Role assignment failed; check the UID, credentials and network.", file=sys.stderr)
        return 1
    print(f"Assigned {arguments.role} to users/{arguments.uid}; both role fields synchronized.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
