import io
import json
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.parse import parse_qs, urlparse

from scripts.assign_user_role import assign_role, main, ROLES


class AssignmentTests(unittest.TestCase):
    def test_every_approved_role_updates_both_fields_only_atomically(self):
        for role in ROLES:
            with self.subTest(role=role):
                calls = []

                def opener(request, timeout):
                    calls.append(request)
                    self.assertEqual(timeout, 30)
                    return io.BytesIO(json.dumps({
                        "updateTime": "2026-10-09T12:00:00Z",
                        "fields": {"emailVerified": {"booleanValue": False}},
                    }).encode())

                assign_role("test-user", role, "local-test-token", opener=opener)
                self.assertEqual(len(calls), 2)
                self.assertEqual(calls[0].get_method(), "GET")
                self.assertEqual(calls[1].get_method(), "PATCH")
                self.assertIn("projects/cleancyclemobileapp/databases/(default)/documents/users/test-user",
                              calls[1].full_url)
                self.assertEqual(json.loads(calls[1].data), {"fields": {
                    "role": {"stringValue": role},
                    "requestedRole": {"stringValue": role},
                }})
                self.assertEqual(parse_qs(urlparse(calls[1].full_url).query), {
                    "updateMask.fieldPaths": ["role", "requestedRole"],
                    "currentDocument.updateTime": ["2026-10-09T12:00:00Z"],
                })

    def test_invalid_role_uid_or_credentials_cannot_issue_requests(self):
        for uid, role, token in [("u", "admin", "t"), ("", "driver", "t"),
                                 ("../users/u", "driver", "t"), ("u", "driver", "")]:
            with self.subTest(uid=uid, role=role):
                with patch("urllib.request.urlopen") as opener:
                    with self.assertRaises(ValueError):
                        assign_role(uid, role, token, opener=opener)
                    opener.assert_not_called()

    def test_missing_profile_does_not_create_one(self):
        calls = []

        def opener(request, timeout):
            calls.append(request)
            raise HTTPError(request.full_url, 404, "not found", {}, None)

        with self.assertRaises(HTTPError):
            assign_role("missing", "driver", "t", opener=opener)
        self.assertEqual(len(calls), 1)

    def test_missing_version_refuses_patch(self):
        calls = []

        def opener(request, timeout):
            calls.append(request)
            return io.BytesIO(b'{}')

        with self.assertRaises(ValueError):
            assign_role("u", "driver", "t", opener=opener)
        self.assertEqual(len(calls), 1)

    def test_iam_denial_is_not_retried_or_bypassed(self):
        with patch("scripts.assign_user_role.subprocess.run") as credentials, \
             patch("scripts.assign_user_role.assign_role") as assign, \
             patch("sys.stderr", new_callable=io.StringIO) as output:
            credentials.return_value.stdout = "local-test-token"
            assign.side_effect = HTTPError("https://example.test", 403, "denied", {}, None)
            self.assertEqual(main(["--uid", "u", "--role", "driver"]), 1)
            assign.assert_called_once()
            self.assertNotIn("local-test-token", output.getvalue())


if __name__ == "__main__":
    unittest.main()
