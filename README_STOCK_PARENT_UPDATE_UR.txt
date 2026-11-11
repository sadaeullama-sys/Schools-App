School Management System - Stock & Parent Management Update

Included in this update:
1. Stock Management page added to Principal navigation and dashboard.
2. Add/purchase stock items with item name, category, quantity, unit and purchase price.
3. Stock Giving / Issued tab. Issue items to a student or staff member; available quantity is reduced automatically.
4. Issue history stores recipient, class/admission reference, quantity, date and remarks.
5. Parent Management navigation entry opens the existing Firebase Parent Registration Requests workflow.
6. Parent access request approval links a parent account to a student admission/roll number, as supported by the existing app code.

Important limitations:
- Stock records are currently stored locally on the device using SharedPreferences. They do not yet sync between different phones or computers.
- Parent registration/approval uses Firebase collections parentRequests, parentAccess, students and schoolPrincipals. Principal access must be configured in Firestore as documented in the existing setup guide and firestore.rules.
- Staff Login is still a placeholder in this project; Staff account creation and staff authentication are not included in this update.
- Build and test the APK using the included GitHub Actions workflow. This source ZIP has not been built on a physical Android device in this session.

Android upload:
1. Download and extract this ZIP.
2. Upload the complete Schools-App-main folder contents to your GitHub repository (replace existing files).
3. Run the repository's Actions workflow to build the APK.
