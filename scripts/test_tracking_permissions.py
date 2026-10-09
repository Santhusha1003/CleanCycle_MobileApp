"""Tracking security regressions. Local Firestore emulator + demo project only."""
import base64
import json
import os
import time
import unittest
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

class TrackingRules(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        host = os.environ.get('FIRESTORE_EMULATOR_HOST', '')
        cls.project = os.environ.get('GCLOUD_PROJECT', '')
        if not host.startswith(('127.0.0.1:', 'localhost:')) or not cls.project.startswith('demo-'):
            raise RuntimeError('Use only a localhost Firestore emulator and demo- project.')
        cls.root = f'http://{host}/v1/projects/{cls.project}/databases/(default)/documents'

    def token(self, uid):
        def encode(value):
            return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
        now = int(time.time())
        return encode({'alg': 'none', 'typ': 'JWT'}) + '.' + encode({
            'iss': f'https://securetoken.google.com/{self.project}', 'aud': self.project,
            'sub': uid, 'user_id': uid, 'iat': now, 'exp': now + 3600,
            'firebase': {'sign_in_provider': 'password'}}) + '.'

    def call(self, path, uid, method='GET', body=None):
        headers = {'Content-Type': 'application/json'}
        if uid is not None:
            headers['Authorization'] = 'Bearer ' + ('owner' if uid == '__seed__' else self.token(uid))
        req = Request(self.root + path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method)
        try:
            with urlopen(req, timeout=15) as response:
                return response.status, json.load(response)
        except HTTPError as error:
            return error.code, json.load(error)

    def write(self, path, data, uid, mask=False):
        def field(value):
            if isinstance(value, bool): return {'booleanValue': value}
            if isinstance(value, (int, float)): return {'doubleValue': value}
            if isinstance(value, list): return {'arrayValue': {'values': [field(item) for item in value]}}
            return {'stringValue': value}
        query = '?' + urlencode([('updateMask.fieldPaths', key) for key in data]) if mask else ''
        return self.call('/' + path + query, uid, 'PATCH', {'fields': {key: field(value) for key, value in data.items()}})[0]

    def query(self, collection, filters, uid):
        clauses = [{'fieldFilter': {'field': {'fieldPath': key}, 'op': 'EQUAL', 'value': {'stringValue': value}}} for key, value in filters.items()]
        where = clauses[0] if len(clauses) == 1 else {'compositeFilter': {'op': 'AND', 'filters': clauses}}
        return self.call(':runQuery', uid, 'POST', {'structuredQuery': {'from': [{'collectionId': collection}], 'where': where}})

    def setUp(self):
        for uid, role in [('one', 'resident'), ('two', 'resident'), ('d1', 'driver'), ('d2', 'driver'), ('officer', 'municipal_officer')]:
            self.assertEqual(self.write('users/' + uid, {'uid': uid, 'email': uid + '@example.test', 'role': role, 'name': uid}, '__seed__'), 200)
        for suffix, resident, driver in [('1', 'one', 'd1'), ('2', 'two', 'd2')]:
            self.assertEqual(self.write('special_pickups/r' + suffix, {
                'requestId': 'r' + suffix, 'userId': resident, 'status': 'Assigned',
                'assignedDriverUid': driver, 'assignedVehicleId': 'v' + suffix}, '__seed__'), 200)
            self.assertEqual(self.write('vehicles/v' + suffix, {'registrationNumber': 'v' + suffix}, '__seed__'), 200)
            self.assertEqual(self.write('drivers/municipal-' + suffix, {
                'driverId': 'municipal-' + suffix, 'authUid': driver,
                'email': driver + '@example.test'}, '__seed__'), 200)
            self.assertEqual(self.write('schedules/s' + suffix, {
                'assignedDriverId': 'municipal-' + suffix,
                'assignedDriverUid': driver, 'assignedVehicleId': 'v' + suffix,
                'collectionDate': '2026-10-10T00:00:00.000',
                'startTime': '08:00', 'endTime': '10:00', 'zone': 'North',
                'wasteType': 'general', 'acceptedItems': [], 'instructions': '',
                'status': 'scheduled'}, '__seed__'), 200)
            self.assertEqual(self.write('resident_schedules/s' + suffix, {
                'collectionDate': '2026-10-10T00:00:00.000',
                'startTime': '08:00', 'endTime': '10:00', 'zone': 'North',
                'wasteType': 'general', 'acceptedItems': [], 'instructions': '',
                'status': 'scheduled'}, '__seed__'), 200)
            self.assertEqual(self.write('driver_trips/special_pickups_r' + suffix, self.trip(suffix, resident, driver), '__seed__'), 200)

    def trip(self, suffix='1', resident='one', driver='d1'):
        return {'requestCollection': 'special_pickups', 'requestId': 'r' + suffix,
                'residentId': resident, 'assignedDriverUid': driver,
                'assignedVehicleId': 'v' + suffix, 'driverName': driver,
                'vehicleNumber': 'v' + suffix, 'status': 'assigned'}

    def test_resident_can_read_only_owned_request_and_trip(self):
        self.assertEqual(self.call('/special_pickups/r1', 'one')[0], 200)
        self.assertEqual(self.call('/special_pickups/r2', 'one')[0], 403)
        self.assertEqual(self.call('/driver_trips/special_pickups_r1', 'one')[0], 200)
        self.assertEqual(self.call('/driver_trips/special_pickups_r2', 'one')[0], 403)

    def test_residents_read_only_safe_schedule_projection(self):
        status, body = self.call('/resident_schedules/s1', 'one')
        self.assertEqual(status, 200)
        fields = body['fields']
        self.assertEqual(set(fields), {
            'collectionDate', 'startTime', 'endTime', 'zone', 'wasteType',
            'status', 'acceptedItems', 'instructions'})
        self.assertEqual(self.call('/schedules/s1', 'one')[0], 403)
        forged = {**{
            'collectionDate': '2026-10-10T00:00:00.000',
            'startTime': '08:00', 'endTime': '10:00', 'zone': 'North',
            'wasteType': 'general', 'acceptedItems': [], 'instructions': '',
            'status': 'scheduled'}, 'assignedDriverUid': 'd1'}
        self.assertEqual(self.write('resident_schedules/s1', forged, 'officer'), 403)
        changed = {'wasteType': 'private change'}
        self.assertEqual(self.write('resident_schedules/s1', changed, 'officer', True), 403)

    def test_driver_can_read_only_assigned_trip_and_schedule(self):
        self.assertEqual(self.call('/driver_trips/special_pickups_r1', 'd1')[0], 200)
        self.assertEqual(self.call('/driver_trips/special_pickups_r2', 'd1')[0], 403)
        self.assertEqual(self.call('/schedules/s1', 'd1')[0], 200)
        self.assertEqual(self.call('/schedules/s2', 'd1')[0], 403)
        self.assertEqual(self.call('/special_pickups/r2', 'd1')[0], 403)

    def test_driver_can_read_only_own_verified_driver_record(self):
        self.assertEqual(self.call('/drivers/municipal-1', 'd1')[0], 200)
        self.assertEqual(self.call('/drivers/municipal-2', 'd1')[0], 403)
        self.assertEqual(self.query('drivers', {'authUid': 'd1'}, 'd1')[0], 200)
        self.assertEqual(self.query('drivers', {'authUid': 'd2'}, 'd1')[0], 403)
        self.assertEqual(self.call(':runQuery', 'd1', 'POST', {
            'structuredQuery': {'from': [{'collectionId': 'drivers'}]}})[0], 403)
        # Municipal Officer collection-wide access remains unchanged.
        self.assertEqual(self.call(':runQuery', 'officer', 'POST', {
            'structuredQuery': {'from': [{'collectionId': 'drivers'}]}})[0], 200)

    def test_revoked_internal_driver_link_removes_schedule_access(self):
        self.assertEqual(self.call('/drivers/municipal-1', '__seed__', 'DELETE')[0], 200)
        self.assertEqual(self.call('/schedules/s1', 'd1')[0], 403)

    def test_schedule_assignment_requires_verified_internal_driver_link(self):
        self.assertEqual(self.write('drivers/municipal-1', {
            'driverId': 'municipal-1', 'authUid': 'd1'}, '__seed__'), 200)
        valid = {'scheduleId': 'assigned', 'assignedDriverId': 'municipal-1',
                 'assignedDriverUid': 'd1', 'assignedVehicleId': 'v1',
                 'status': 'scheduled'}
        self.assertEqual(self.write('schedules/assigned', valid, 'officer'), 200)
        forged_uid = {**valid, 'scheduleId': 'forged', 'assignedDriverUid': 'd2'}
        self.assertEqual(self.write('schedules/forged', forged_uid, 'officer'), 403)
        self.assertEqual(self.write('schedules/assigned', {
            'assignedDriverUid': 'd2'}, 'd1', True), 403)

    def test_scoped_queries_match_the_application(self):
        self.assertEqual(self.query('special_pickups', {'userId': 'one'}, 'one')[0], 200)
        self.assertEqual(self.call('/driver_trips/special_pickups_r1', 'one')[0], 200)
        self.assertEqual(self.query('driver_trips', {'assignedDriverUid': 'd1'}, 'd1')[0], 200)
        self.assertEqual(self.query('schedules', {'assignedDriverUid': 'd1'}, 'd1')[0], 200)
        self.assertEqual(self.query('driver_trips', {'assignedDriverUid': 'd2'}, 'd1')[0], 403)

    def test_driver_coordinates_cannot_change_assignment_or_another_trip(self):
        self.assertEqual(self.write('driver_trips/special_pickups_r1', {'currentLatitude': 6.9, 'currentLongitude': 79.8}, 'd1', True), 200)
        self.assertEqual(self.write('driver_trips/special_pickups_r2', {'currentLatitude': 6.9, 'currentLongitude': 79.8}, 'd1', True), 403)
        self.assertEqual(self.write('driver_trips/special_pickups_r1', {'assignedDriverUid': 'd2'}, 'd1', True), 403)
        self.assertEqual(self.write('driver_trips/special_pickups_r1', {'currentLatitude': 999, 'currentLongitude': 79.8}, 'd1', True), 403)

    def test_only_officer_can_create_a_valid_linked_trip(self):
        self.assertEqual(self.call('/driver_trips/special_pickups_r1', '__seed__', 'DELETE')[0], 200)
        self.assertEqual(self.write('driver_trips/special_pickups_r1', self.trip(), 'one'), 403)
        self.assertEqual(self.write('driver_trips/special_pickups_r1', self.trip(), 'd1'), 403)
        self.assertEqual(self.write('driver_trips/special_pickups_r1', self.trip(), 'officer'), 200)
        self.assertEqual(self.write('driver_trips/special_pickups_r1', self.trip(resident='two'), 'officer'), 403)

    def test_pending_signup_request_cannot_self_assign_or_approve_role(self):
        request = {'requestId': 'new', 'userId': 'one', 'status': 'Pending'}
        self.assertEqual(self.write('special_pickups/new', request, 'one'), 200)
        self.assertEqual(self.write('special_pickups/new', {'assignedDriverUid': 'd1'}, 'one', True), 403)
        self.assertEqual(self.write('special_pickups/new', {'status': 'Assigned'}, 'one', True), 403)
        self.assertEqual(self.write('users/one', {'role': 'driver'}, 'one', True), 403)
        self.assertEqual(self.write('special_pickups/forged', {**request, 'requestId': 'forged', 'assignedDriverUid': 'd1'}, 'one'), 403)

    def test_reassignment_revokes_old_driver_access(self):
        self.assertEqual(self.write('special_pickups/r1', {'assignedDriverUid': 'd2'}, '__seed__', True), 200)
        self.assertEqual(self.call('/driver_trips/special_pickups_r1', 'd1')[0], 403)

    def test_unauthenticated_reads_and_writes_are_denied(self):
        self.assertEqual(self.call('/driver_trips/special_pickups_r1', None)[0], 403)
        self.assertEqual(self.write('special_pickups/new', {'userId': 'one', 'requestId': 'new', 'status': 'Pending'}, None), 403)

if __name__ == '__main__':
    unittest.main()
