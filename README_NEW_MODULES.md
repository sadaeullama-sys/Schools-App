# Added school management modules

This update keeps the existing app source and adds three dashboard/drawer modules:

- Staff Management: create/edit/delete staff accounts with generated Staff ID and password.
- Parent Management: create/edit/delete parent accounts, link each parent to a student, and approve/reject access.
- Stock Management: create/edit/delete inventory items, record category/supplier/purchase price/quantity, issue stock to a student or staff member, deduct quantity, and view issue history.

The new records are stored locally using SharedPreferences on the current installation. Staff and Parent portal login checks these locally stored IDs/passwords. This is not secure multi-device/cloud authentication: accounts do not sync between phones, passwords are not protected by a server-side identity system, and the parent login currently confirms the linked child rather than providing a full parent dashboard. For production multi-device use, Firebase Authentication and Firestore security rules must be implemented and tested.

APK build and on-device testing must be run through the included GitHub Actions workflow / a Flutter environment.
