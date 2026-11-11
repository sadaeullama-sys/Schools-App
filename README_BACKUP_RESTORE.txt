BACKUP & RESTORE

A Backup & Restore page has been added to the dashboard. It exports all SharedPreferences values to a JSON backup file and restores a selected JSON backup. Restore replaces the current local app preferences, so create a backup first.

This is a local-device backup. It does not sync data to Firebase or another phone. After replacing project files, run `flutter pub get` before building the APK.
