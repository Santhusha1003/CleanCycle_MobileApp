"""Signup security regression against a local Firestore emulator only.

Run via firebase emulators:exec; never sends requests to live Firestore.
"""
import base64
import json
import os
import time
import unittest
import uuid
from urllib.error import HTTPError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


class SignupPermissions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        host = os.environ.get('FIRESTORE_EMULATOR_HOST', '')
        if not host.startswith(('127.0.0.1:', 'localhost:')):
            raise RuntimeError('This test requires a local Firestore emulator.')
        project = os.environ.get('GCLOUD_PROJECT', '')
        if not project.startswith('demo-'):
            raise RuntimeError('Use a demo- Firebase project for this test.')
        cls.project = project
        cls.endpoint = f'http://{host}/v1/projects/{project}/databases/(default)/documents/users/'

    def setUp(self):
        self.uid = 'signup-test-' + uuid.uuid4().hex

    def _token(self, uid):
        def encode(value):
            return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
        now = int(time.time())
        return encode({'alg': 'none', 'typ': 'JWT'}) + '.' + encode({
            'iss': f'https://securetoken.google.com/{self.project}',
            'aud': self.project, 'sub': uid, 'user_id': uid,
            'iat': now, 'exp': now + 3600,
            'firebase': {'sign_in_provider': 'password'},
        }) + '.'

    def _write(self, document_id, data, authenticated_uid, mask=None):
        fields = {key: value if isinstance(value, dict) else
                  {'booleanValue': value} if isinstance(value, bool) else
                  {'stringValue': value} for key, value in data.items()}
        headers = {'Content-Type': 'application/json'}
        if authenticated_uid is not None:
            headers['Authorization'] = 'Bearer ' + self._token(authenticated_uid)
        endpoint = self.endpoint + quote(document_id, safe='')
        if mask:
            endpoint += '?' + urlencode([('updateMask.fieldPaths', field) for field in mask])
        request = Request(endpoint,
                          data=json.dumps({'fields': fields}).encode(),
                          method='PATCH', headers=headers)
        try:
            with urlopen(request, timeout=10) as response:
                return response.status
        except HTTPError as error:
            return error.code

    def _payload(self, requested='resident', assigned='resident'):
        return {'uid': self.uid, 'role': assigned, 'requestedRole': requested,
                'name': 'Local test', 'email': 'local@example.test'}

    def test_each_signup_request_can_create_own_resident_profile(self):
        for role in ('resident', 'driver', 'municipal_officer'):
            with self.subTest(requestedRole=role):
                self.uid = 'signup-test-' + uuid.uuid4().hex
                self.assertEqual(self._write(self.uid, self._payload(role), self.uid), 200)

    def test_missing_uid_reproduces_the_original_denial(self):
        payload = self._payload()
        del payload['uid']
        self.assertEqual(self._write(self.uid, payload, self.uid), 403)

    def test_mismatched_uid_is_denied(self):
        payload = self._payload()
        payload['uid'] = 'different-user'
        self.assertEqual(self._write(self.uid, payload, self.uid), 403)

    def test_unauthenticated_create_is_denied(self):
        self.assertEqual(self._write(self.uid, self._payload(), None), 403)

    def test_writing_another_users_document_is_denied(self):
        self.assertEqual(self._write(self.uid, self._payload(), 'different-user'), 403)

    def test_privileged_self_registration_is_denied(self):
        for role in ('driver', 'municipal_officer'):
            with self.subTest(role=role):
                self.assertEqual(self._write(self.uid, self._payload(role, role), self.uid), 403)

    def test_verification_updates_preserve_role_uid_and_email(self):
        self.assertEqual(self._write(self.uid, self._payload(), self.uid), 200)
        otp = {'emailOtpHash': 'local-test-hash',
               'emailOtpExpiresAt': {'timestampValue': '2026-10-09T12:00:00Z'}}
        self.assertEqual(self._write(self.uid, otp, self.uid, mask=list(otp)), 200)
        self.assertEqual(self._write(self.uid, {'emailVerified': True}, self.uid,
                                    mask=['emailVerified']), 200)

    def test_owner_cannot_change_uid_or_email(self):
        self.assertEqual(self._write(self.uid, self._payload(), self.uid), 200)
        self.assertEqual(self._write(self.uid, {'uid': 'other-user'}, self.uid,
                                    mask=['uid']), 403)
        self.assertEqual(self._write(self.uid, {'email': 'other@example.test'}, self.uid,
                                    mask=['email']), 403)

    def test_self_promotion_after_registration_is_denied(self):
        self.assertEqual(self._write(self.uid, self._payload('driver'), self.uid), 200)
        for role in ('driver', 'municipal_officer'):
            with self.subTest(role=role):
                self.assertEqual(self._write(self.uid, self._payload(role, role), self.uid), 403)


if __name__ == '__main__':
    unittest.main()
