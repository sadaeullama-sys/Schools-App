School Management System - Update Notes

Changes in this package:
1. PDF actions now share the generated PDF directly instead of opening Android Print Spooler preview. This is intended to avoid the Android "Sorry, that didn't work. Try again" print-preview error. Choose Save to Drive / Files from the Android share sheet if available.
2. Syllabus form now has Class and Subject dropdowns, Chapter/Unit, and syllabus details.
3. Date Sheet form now has Class and Subject dropdowns, a date picker, a separate time picker, and paper instructions/details.
4. Syllabus and Date Sheet can be exported as PDF using the share sheet.
5. Existing school approval and license generator code is retained.

Important remaining work:
- Staff and Parent account creation / ID-password authentication are not yet implemented in this package. The current Staff/Parent portal screen still displays that accounts are not configured. This requires a secure account-provisioning flow and Firestore rules, not just a UI change.
- This ZIP has not been built or tested on a physical Android device in this environment. Build the APK with the included GitHub Actions workflow and test the PDF share action on your phone.
