# Multi-School registration setup

This update adds self-registration for schools and Firebase Email/Password principal authentication.

## Firebase Console setup
1. Authentication > Sign-in method > Email/Password: enable.
2. Firestore Database > Rules: publish the contents of `firestore.rules`.
3. A school registers in the app using Register New School. Firebase Authentication creates its principal account and Firestore creates `schools/{schoolId}` with `status: pending`.
4. To approve: Firebase Console > Firestore Database > Data > `schools` > open the new school document > edit `status` from `pending` to `approved` and save. To reject, set it to `rejected`.
5. Principal signs in using the email and password created during school registration. Pending/rejected schools cannot enter the dashboard.

## Important limitations in this version
- No separate System Owner panel is included, per product decision. Approval is done manually in Firebase Console.
- Existing local school modules remain in the app. This change stores school registration and verifies approval; it does not yet migrate every existing student/fee/attendance record to Firestore.
- Parent/Staff accounts and child-level authorization are not yet connected to this multi-school tenant model.
- Never use test-mode Firestore rules. Keep the supplied rules published.
