"""Atomic schedule-save security regressions; localhost demo emulator only.

Run from the repository root:
firebase emulators:exec --only firestore --project demo-cleancycle-schedule \
  --config firebase.schedule-test.json 'python3 scripts/test_schedule_save_permissions.py'
"""
import unittest
from test_tracking_permissions import TrackingRules

class ScheduleSaveRules(TrackingRules):
    def setUp(self):
        super().setUp()
        for path in ['schedules/schedule_003', 'resident_schedules/schedule_003', 'driver_trips/schedules_schedule_003']:
            self.call('/' + path, '__seed__', 'DELETE')

    def save(self, uid='officer', driver='d1', projection_zone='Malabe'):
        schedule = {
            'scheduleId': 'schedule_003', 'zone': 'Malabe',
            'collectionDate': '2026-10-12T18:30:00Z',
            'startTime': '08:00', 'endTime': '17:00',
            'wasteType': 'recyclable', 'status': 'scheduled',
            'assignedDriverId': 'municipal-1', 'assignedDriverUid': driver,
            'assignedVehicleId': 'v1', 'trackingTripId': 'schedules_schedule_003',
        }
        projection = {key: schedule[key] for key in ['zone', 'collectionDate', 'startTime', 'endTime', 'wasteType', 'status']}
        projection.update(zone=projection_zone, acceptedItems=[], instructions='')
        trip = {
            'requestCollection': 'schedules', 'requestId': 'schedule_003',
            'residentId': '', 'assignedDriverId': 'municipal-1',
            'assignedDriverUid': driver, 'assignedVehicleId': 'v1',
            'driverName': driver, 'driverPhone': '', 'driverAvatarUrl': '',
            'vehicleNumber': 'v1', 'status': 'scheduled',
        }
        def field(value):
            if isinstance(value, list): return {'arrayValue': {'values': []}}
            return {'stringValue': value}
        writes = [{'update': {
            'name': self.root.split('/v1/')[1] + '/' + path,
            'fields': {key: {'timestampValue': value} if key == 'collectionDate' else field(value) for key, value in data.items()},
        }} for path, data in [
            ('schedules/schedule_003', schedule),
            ('resident_schedules/schedule_003', projection),
            ('driver_trips/schedules_schedule_003', trip),
        ]]
        return self.call(':commit', uid, 'POST', {'writes': writes})

    def test_new_assigned_schedule_and_trip_save_atomically(self):
        status, body = self.save()
        self.assertEqual(status, 200, body)
        self.assertEqual(self.call('/schedules/schedule_003', 'officer')[0], 200)
        self.assertEqual(self.call('/resident_schedules/schedule_003', 'one')[0], 200)
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', 'd1')[0], 200)

    def test_actual_municipal_officer_role_supports_all_assignments(self):
        self.assertEqual(self.write('users/officer', {'role': 'municipal_officer'}, '__seed__', True), 200)
        self.assertEqual(self.save()[0], 200)
        for driver, vehicle in [('municipal-1', 'v1'), ('municipal-1', None), (None, 'v1'), (None, None)]:
            with self.subTest(driver=driver, vehicle=vehicle):
                self.assertEqual(self.planning_save(driver=driver, vehicle=vehicle, clear_trip=True)[0], 200)
        # A requested role does not grant permissions to an existing Resident.
        self.assertEqual(self.write('users/one', {'role': 'resident', 'requestedRole': 'municipal_officer'}, '__seed__', True), 200)
        self.assertEqual(self.planning_save(uid='one')[0], 403)

    def test_reassignment_uses_new_source_state(self):
        self.assertEqual(self.save()[0], 200)
        self.assertEqual(self.write('drivers/municipal-1', {'authUid': 'd2'}, '__seed__', True), 200)
        status, body = self.save(driver='d2')
        self.assertEqual(status, 200, body)
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', 'd1')[0], 403)
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', 'd2')[0], 200)

    def test_non_officer_and_forged_assignments_are_rejected_without_partial_writes(self):
        for uid in ['one', 'd1', None]:
            self.assertEqual(self.save(uid=uid)[0], 403)
        self.assertEqual(self.save(driver='d2')[0], 403)
        self.assertEqual(self.call('/schedules/schedule_003', '__seed__')[0], 404)

    def test_mismatched_resident_projection_is_rejected_atomically(self):
        self.assertEqual(self.save(projection_zone='Wrong zone')[0], 403)
        self.assertEqual(self.call('/schedules/schedule_003', '__seed__')[0], 404)
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', '__seed__')[0], 404)

    def test_unassigned_schedule_and_projection_save_together(self):
        schedule = {
            'scheduleId': 'schedule_003', 'zone': 'Malabe',
            'collectionDate': '2026-10-12T18:30:00Z',
            'startTime': '08:00', 'endTime': '17:00',
            'wasteType': 'mixed', 'status': 'scheduled',
        }
        projection = {**schedule, 'acceptedItems': [], 'instructions': ''}
        del projection['scheduleId']
        writes = [{'update': {
            'name': self.root.split('/v1/')[1] + '/' + path,
            'fields': {key: {'timestampValue': value} if key == 'collectionDate'
                       else {'arrayValue': {'values': []}} if isinstance(value, list)
                       else {'stringValue': value} for key, value in data.items()},
        }} for path, data in [('schedules/schedule_003', schedule),
                             ('resident_schedules/schedule_003', projection)]]
        for uid in ['one', 'd1', None]:
            self.assertEqual(self.call(':commit', uid, 'POST', {'writes': writes})[0], 403)
        status, body = self.call(':commit', 'officer', 'POST', {'writes': writes})
        self.assertEqual(status, 200, body)
        self.assertEqual(self.call('/schedules/schedule_003', 'officer')[0], 200)
        self.assertEqual(self.call('/resident_schedules/schedule_003', 'one')[0], 200)
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', '__seed__')[0], 404)

    def test_driver_link_matches_canonical_uid_and_normalized_email(self):
        # Legacy profile identity is its document path; uid is optional but
        # must agree when present. requestedRole is never approval.
        self.assertEqual(self.write('users/d1', {'role': 'driver', 'email': ' D1@Example.Test '}, '__seed__'), 200)
        self.assertEqual(self.write('drivers/municipal-1', {'driverId': 'municipal-1', 'authUid': 'd1', 'email': 'd1@example.test'}, 'officer'), 200)
        self.assertEqual(self.write('users/d1', {'uid': 'd2'}, '__seed__', True), 200)
        self.assertEqual(self.write('drivers/municipal-1', {'driverId': 'municipal-1', 'authUid': 'd1', 'email': 'd1@example.test'}, 'officer'), 403)
        self.assertEqual(self.write('users/d1', {'role': 'resident', 'requestedRole': 'driver', 'email': 'd1@example.test'}, '__seed__'), 200)
        self.assertEqual(self.write('drivers/municipal-1', {'driverId': 'municipal-1', 'authUid': 'd1', 'email': 'd1@example.test'}, 'officer'), 403)
        self.assertEqual(self.write('drivers/municipal-1', {'driverId': 'municipal-1', 'authUid': 'd2', 'email': 'd2@example.test'}, 'one'), 403)

    def planning_save(self, uid='officer', driver='municipal-1', vehicle='v1', zone='Malabe', projection_zone=None, projection=True, trip=False, clear_trip=False):
        schedule = {'scheduleId': 'schedule_003', 'zone': zone,
                    'collectionDate': '2026-10-12T18:30:00Z', 'startTime': '08:00',
                    'endTime': '17:00', 'wasteType': 'mixed', 'status': 'scheduled',
                    'assignedDriverId': driver, 'assignedDriverName': 'Driver One' if driver else None,
                    'assignedDriverUid': None, 'assignedVehicleId': vehicle}
        view = {key: schedule[key] for key in ['zone', 'collectionDate', 'startTime', 'endTime', 'wasteType', 'status']}
        view.update(acceptedItems=[], instructions='', zone=projection_zone or zone)
        records = [('schedules/schedule_003', schedule)]
        if projection:
            records.append(('resident_schedules/schedule_003', view))
        if trip:
            records.append(('driver_trips/schedules_schedule_003', {
                'requestCollection': 'schedules', 'requestId': 'schedule_003',
                'assignedDriverId': driver, 'assignedDriverUid': None,
                'assignedVehicleId': vehicle, 'residentId': '',
            }))
        def field(key, value):
            if value is None: return {'nullValue': None}
            if isinstance(value, list): return {'arrayValue': {'values': []}}
            return {'timestampValue': value} if key == 'collectionDate' else {'stringValue': value}
        writes = [{'update': {'name': self.root.split('/v1/')[1] + '/' + path,
            'fields': {key: field(key, value) for key, value in data.items()}}}
            for path, data in records]
        if clear_trip:
            writes.append({'delete': self.root.split('/v1/')[1] + '/driver_trips/schedules_schedule_003'})
        return self.call(':commit', uid, 'POST', {'writes': writes})

    def test_updates_support_each_assignment_combination_and_remove_old_trip(self):
        for driver, vehicle in [('municipal-1', 'v1'), ('municipal-1', None), (None, 'v1'), (None, None)]:
            with self.subTest(driver=driver, vehicle=vehicle):
                self.assertEqual(self.save()[0], 200)
                # Clearing a previous verified trip is part of the same batch.
                self.assertEqual(self.planning_save(uid='one', driver=driver, vehicle=vehicle, clear_trip=True)[0], 403)
                self.assertEqual(self.call('/driver_trips/schedules_schedule_003', 'd1')[0], 200)
                status, body = self.planning_save(driver=driver, vehicle=vehicle, clear_trip=True)
                self.assertEqual(status, 200, body)
                self.assertEqual(self.call('/resident_schedules/schedule_003', 'one')[0], 200)
                self.assertEqual(self.call('/driver_trips/schedules_schedule_003', '__seed__')[0], 404)
                status, saved = self.call('/schedules/schedule_003', 'officer')
                self.assertEqual(status, 200, saved)
                self.assertEqual(saved['fields']['assignedDriverId'], {'stringValue': driver} if driver else {'nullValue': None})
                self.assertEqual(saved['fields']['assignedVehicleId'], {'stringValue': vehicle} if vehicle else {'nullValue': None})

    def test_officer_creates_and_updates_planning_assignment_without_trip(self):
        status, body = self.planning_save()
        self.assertEqual(status, 200, body)
        status, body = self.planning_save(zone='Malabe East')
        self.assertEqual(status, 200, body)
        for uid in ['one', 'd1', None]:
            self.assertEqual(self.planning_save(uid=uid, zone='Unauthorized change')[0], 403)
        for path, uid in [('schedules/schedule_003', 'officer'), ('resident_schedules/schedule_003', 'one')]:
            status, body = self.call('/' + path, uid)
            self.assertEqual(status, 200, body)
            self.assertEqual(body['fields']['zone']['stringValue'], 'Malabe East')
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', '__seed__')[0], 404)
        self.assertEqual(self.call('/schedules/schedule_003', 'd1')[0], 403)

    def test_planning_driver_and_vehicle_are_optional_and_independent(self):
        for driver, vehicle in [('municipal-1', None), (None, 'v1'), (None, None)]:
            status, body = self.planning_save(driver=driver, vehicle=vehicle)
            self.assertEqual(status, 200, body)
        self.assertEqual(self.write('vehicles/v1', {'assignedDriverId': 'municipal-2'}, '__seed__', True), 200)
        self.assertEqual(self.planning_save()[0], 200)
        self.assertEqual(self.call('/driver_trips/schedules_schedule_003', '__seed__')[0], 404)

    def test_planning_assignment_requires_real_records_and_officer_authorization(self):
        for uid in ['one', 'd1', None]:
            self.assertEqual(self.planning_save(uid=uid)[0], 403)
        self.assertEqual(self.planning_save(driver='missing-driver')[0], 403)
        self.assertEqual(self.planning_save(vehicle='missing-vehicle')[0], 403)
        self.assertEqual(self.planning_save(trip=True)[0], 403)
        self.assertEqual(self.planning_save(projection=False)[0], 403)
        self.assertEqual(self.planning_save(projection_zone='Wrong zone')[0], 403)
        for path in ['schedules/schedule_003', 'resident_schedules/schedule_003', 'driver_trips/schedules_schedule_003']:
            self.assertEqual(self.call('/' + path, '__seed__')[0], 404)

    def test_projection_write_can_succeed_but_main_planning_write_was_denied_by_old_policy(self):
        # Seed source only to isolate the projection rule from the schedule rule.
        self.assertEqual(self.write('schedules/schedule_003', {
            'zone': 'Malabe', 'collectionDate': '2026-10-13', 'startTime': '08:00',
            'endTime': '17:00', 'wasteType': 'mixed', 'status': 'scheduled',
            'assignedDriverId': 'municipal-1'}, '__seed__'), 200)
        self.assertEqual(self.write('resident_schedules/schedule_003', {
            'zone': 'Malabe', 'collectionDate': '2026-10-13', 'startTime': '08:00',
            'endTime': '17:00', 'wasteType': 'mixed', 'status': 'scheduled',
            'acceptedItems': [], 'instructions': ''}, 'officer'), 200)

    def test_trip_write_is_authorized_when_its_verified_source_already_exists(self):
        self.assertEqual(self.write('schedules/schedule_003', {
            'assignedDriverId': 'municipal-1', 'assignedDriverUid': 'd1',
            'assignedVehicleId': 'v1'}, '__seed__'), 200)
        status = self.write('driver_trips/schedules_schedule_003', {
            'requestCollection': 'schedules', 'requestId': 'schedule_003',
            'assignedDriverId': 'municipal-1', 'assignedDriverUid': 'd1',
            'assignedVehicleId': 'v1', 'residentId': ''}, 'officer')
        self.assertEqual(status, 200)

    def test_existing_read_and_location_permissions_are_preserved(self):
        self.test_resident_can_read_only_owned_request_and_trip()
        self.test_residents_read_only_safe_schedule_projection()
        self.test_driver_can_read_only_assigned_trip_and_schedule()
        self.test_driver_coordinates_cannot_change_assignment_or_another_trip()
        self.test_pending_signup_request_cannot_self_assign_or_approve_role()

if __name__ == '__main__':
    names = [name for name in ScheduleSaveRules.__dict__ if name.startswith('test_')]
    result = unittest.TextTestRunner(verbosity=2).run(unittest.TestSuite(ScheduleSaveRules(name) for name in names))
    raise SystemExit(not result.wasSuccessful())
