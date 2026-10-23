"""Special request authorization regressions. Local demo emulator ONLY.

Use firebase.special-requests.json for the original candidate or
firebase.combined-test.json with --combined for the combined review candidate.
No Auth, Firestore, or deployment requests are sent to a live project.
"""
import argparse
import base64
import json
from pathlib import Path
import re
import unittest

from test_tracking_permissions import TrackingRules


class SpecialRequestRules(TrackingRules):
    baseline_file = 'firestore.rules'
    candidate_file = 'firestore.special-requests.rules'

    def token(self, uid):
        parts = super().token(uid).split('.')
        payload = json.loads(base64.urlsafe_b64decode(parts[1] + '=' * (-len(parts[1]) % 4)))
        payload.update(self.claims.get(uid, {}))
        parts[1] = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')
        return '.'.join(parts)

    def setUp(self):
        self.claims = {}
        super().setUp()
        self.assertEqual(self.write('special_requests/existing', {
            'requestId': 'existing', 'residentId': 'one', 'status': 'pending'
        }, '__seed__'), 200)
        self.call('/special_requests/new', '__seed__', 'DELETE')

    def assert_denied(self, uid):
        for name, status in [
            ('get', self.call('/special_requests/existing', uid)[0]),
            ('get missing', self.call('/special_requests/missing', uid)[0]),
            ('list', self.call('/special_requests', uid)[0]),
            ('query', self.call(':runQuery', uid, 'POST', {
                'structuredQuery': {'from': [{'collectionId': 'special_requests'}]}})[0]),
            ('create', self.write('special_requests/new', {'requestId': 'new'}, uid)),
            ('update', self.write('special_requests/existing', {'status': 'approved'}, uid, True)),
            ('delete', self.call('/special_requests/existing', uid, 'DELETE')[0]),
        ]:
            with self.subTest(uid=uid, operation=name):
                self.assertEqual(status, 403)

    def assert_allowed(self, uid):
        self.assertEqual(self.call('/special_requests/existing', uid)[0], 200)
        self.assertEqual(self.call('/special_requests', uid)[0], 200)
        self.assertEqual(self.call(':runQuery', uid, 'POST', {
            'structuredQuery': {'from': [{'collectionId': 'special_requests'}]}})[0], 200)
        self.assertEqual(self.write('special_requests/new', {'requestId': 'new'}, uid), 200)
        self.assertEqual(self.write('special_requests/new', {'status': 'approved'}, uid, True), 200)
        self.assertEqual(self.call('/special_requests/new', uid, 'DELETE')[0], 200)

    def test_profile_officer_role_aliases_can_manage_requests(self):
        for role in ['officer', 'municipal_officer']:
            with self.subTest(role=role):
                self.assertEqual(self.write('users/officer', {'role': role}, '__seed__', True), 200)
                self.assert_allowed('officer')

    def test_trusted_claim_role_aliases_without_profile_can_manage_requests(self):
        for role in ['officer', 'municipal_officer']:
            with self.subTest(role=role):
                self.claims['claim-officer'] = {'role': role}
                self.assert_allowed('claim-officer')

    def test_residents_drivers_and_unauthenticated_are_denied(self):
        for uid in ['one', 'd1', None]:
            self.assert_denied(uid)

    def test_anonymous_with_officer_profile_and_claim_is_denied(self):
        for role in ['officer', 'municipal_officer']:
            self.claims['officer'] = {'role': role, 'firebase': {'sign_in_provider': 'anonymous'}}
            self.assert_denied('officer')

    def test_missing_and_unrecognized_roles_cannot_claim_officer_access(self):
        for role in ['', 'driver', 'resident', 'admin', 'Municipal Officer']:
            self.claims['no-officer'] = {'role': role}
            self.assert_denied('no-officer')
        self.claims['one'] = {'requestedRole': 'officer'}
        self.assert_denied('one')

    def test_profile_role_cannot_be_self_promoted(self):
        self.assertEqual(self.write('users/one', {'role': 'municipal_officer'}, 'one', True), 403)
        self.assertEqual(self.write('users/new-user', {'uid': 'new-user', 'role': 'officer'}, 'new-user'), 403)
        self.assert_denied('one')
        self.assert_denied('new-user')

    def test_missing_provider_claim_fails_closed(self):
        self.claims['officer'] = {'role': 'officer', 'firebase': {}}
        self.assert_denied('officer')

    def test_request_fields_do_not_grant_roles_or_subcollection_access(self):
        self.assertEqual(self.write('special_requests/new', {
            'residentId': 'one', 'role': 'officer', 'assignedDriverUid': 'd1'
        }, 'one'), 403)
        self.assertEqual(self.write('special_requests/existing/private/child', {'text': 'private'}, 'officer'), 403)

    def test_candidate_only_adds_one_helper_and_one_nonoverlapping_match(self):
        root = Path(__file__).resolve().parents[1]
        baseline = (root / self.baseline_file).read_text()
        candidate = (root / self.candidate_file).read_text()
        start = candidate.index('    // Matches the admin')
        end = candidate.index('    // Everything else is denied.', start)
        self.assertEqual(candidate[:start] + candidate[end:], baseline)
        # The combined candidate must import the original authorization block
        # verbatim, not replace it with a broader or differently trusted rule.
        original = (root / 'firestore.special-requests.rules').read_text()
        original_start = original.index('    // Matches the admin')
        original_end = original.index('    // Everything else is denied.', original_start)
        self.assertEqual(candidate[start:end], original[original_start:original_end])
        self.assertEqual(candidate.count('function isMunicipalOfficer()'), 1)
        self.assertEqual(candidate.count('match /special_requests/{requestId}'), 1)
        paths = re.findall(r'match\s+([^\s]+)\s*\{', candidate)
        self.assertEqual(len(paths), len(set(paths)))
        self.assertNotIn('{document=**}', candidate)
        self.assertNotIn('{path=**}', candidate)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--combined', action='store_true', help='Check the combined candidate against the unchanged tracking candidate.')
    args = parser.parse_args()
    if args.combined:
        SpecialRequestRules.baseline_file = 'firestore.tracking-review.rules'
        SpecialRequestRules.candidate_file = 'firestore.combined-review.rules'
    # Run this focused suite; the tracking suite is executed separately.
    names = [name for name in SpecialRequestRules.__dict__ if name.startswith('test_')]
    result = unittest.TextTestRunner(verbosity=2).run(
        unittest.TestSuite(SpecialRequestRules(name) for name in names))
    raise SystemExit(not result.wasSuccessful())
