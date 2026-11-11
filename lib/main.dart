import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  runApp(const SchoolManagementApp());
}

const Color navy = Color(0xFF092B50);
const Color blue = Color(0xFF1769AA);
const Color lightBlue = Color(0xFFEAF3FC);
const Color gold = Color(0xFFD6A947);
const Color background = Color(0xFFF3F6FA);

const String adminUsername = 'Muhammad Ilyas';

// Admin password کو اپنے محفوظ مقام پر رکھیں۔
const String adminPassword = '03135353153';

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Management System',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  void initState() {
    super.initState();
    checkApp();
  }

  String? startupError;

  Future<void> checkApp() async {
    try {
      // Allow the first frame to render before loading local preferences.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final p = await SharedPreferences.getInstance();

      final active = p.getBool('academy_license_active') ?? false;
      final username = p.getString('academy_customer_username') ?? '';

      if (!mounted) return;

      final Widget next = !active
          ? const LicensePage()
          : (username.isEmpty ? const SetupPage() : const LoginPage());

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => next),
      );
    } catch (e, st) {
      debugPrint('School Management startup error: $e\n$st');
      if (!mounted) return;
      setState(() => startupError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 54, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text('App startup problem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('The app could not load its saved settings. Please try again.'),
                  const SizedBox(height: 8),
                  SelectableText(startupError!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => setState(() => startupError = null), child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ================= DEVICE ID =================

Future<String> getDeviceId() async {
  final p = await SharedPreferences.getInstance();

  String id = p.getString('academy_device_id') ?? '';

  if (id.isEmpty) {
    final random = Random.secure();

    id = List.generate(
      24,
      (_) => random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();

    await p.setString('academy_device_id', id);
  }

  return id;
}

// یہ محفوظ شدہ App Installation ID ہے، حقیقی hardware ID نہیں۔

// ================= LICENSE PAGE =================

class LicensePage extends StatefulWidget {
  const LicensePage({super.key});

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final keyController = TextEditingController();

  String deviceId = 'Loading...';
  String error = '';

  static int logoTaps = 0;

  @override
  void initState() {
    super.initState();
    loadDeviceId();
  }

  Future<void> loadDeviceId() async {
    final id = await getDeviceId();

    if (!mounted) return;

    setState(() => deviceId = id);
  }

  Future<void> activate() async {
    final p = await SharedPreferences.getInstance();

    final savedKey =
        p.getString('academy_generated_license') ?? '';

    if (keyController.text.trim().isEmpty) {
      setState(() => error = 'براہ کرم لائسنس کی درج کریں');
      return;
    }

    if (keyController.text.trim() != savedKey) {
      setState(() => error = 'غلط لائسنس کی');
      return;
    }

    final licensedDevice =
        p.getString('academy_license_device') ?? '';

    if (licensedDevice != deviceId) {
      setState(() => error = 'یہ لائسنس اس ڈیوائس کے لیے نہیں ہے');
      return;
    }

    await p.setBool('academy_license_active', true);

    await p.setString(
      'academy_name',
      p.getString('academy_license_school') ?? 'My School',
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupPage()),
    );
  }

  @override
  void dispose() {
    keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [navy, blue, Color(0xFF397FC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          logoTaps++;

                          if (logoTaps >= 5) {
                            logoTaps = 0;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLoginPage(),
                              ),
                            );
                          }
                        },
                        child: const CircleAvatar(
                          radius: 48,
                          backgroundColor: lightBlue,
                          child: Icon(
                            Icons.school,
                            size: 55,
                            color: navy,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'SCHOOL MANAGEMENT SYSTEM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Device ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                deviceId,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: deviceId),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Device ID کاپی ہوگئی'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: keyController,
                        decoration: const InputDecoration(
                          labelText: 'Enter License Key',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: activate,
                          child: const Text('ACTIVATE LICENSE'),
                        ),
                      ),

                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 20),

                      const Text(
                        'License Support: 03161847676',
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= SCHOOL LOGIN SETUP =================

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  String error = '';

  Future<void> save() async {
    if (username.text.trim().isEmpty ||
        password.text.isEmpty ||
        password.text != confirm.text) {
      setState(() {
        error = 'تمام معلومات درست درج کریں';
      });
      return;
    }

    final p = await SharedPreferences.getInstance();

    await p.setString(
      'academy_customer_username',
      username.text.trim(),
    );

    await p.setString(
      'academy_customer_password',
      password.text,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create School Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 65, color: navy),
                  const SizedBox(height: 15),
                  const Text(
                    'Create Your School Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (error.isNotEmpty)
                    Text(error, style: const TextStyle(color: Colors.red)),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: save,
                      child: const Text('SAVE ACCOUNT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ================= SCHOOL USER LOGIN =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool obscurePassword = true;
  bool rememberMe = true;
  bool loading = false;
  String error = '';
  String schoolName = 'School Management System';

  @override
  void initState() {
    super.initState();
    loadLoginDetails();
  }

  Future<void> loadLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      schoolName = prefs.getString('academy_name') ?? 'School Management System';
      username.text = prefs.getString('academy_customer_username') ?? '';
      rememberMe = prefs.getBool('academy_remember_me') ?? true;
    });
  }

  Future<void> login() async {
    if (loading) return;
    setState(() { loading = true; error = ''; });
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('academy_customer_username') ?? '';
    final savedPassword = prefs.getString('academy_customer_password') ?? '';
    if (username.text.trim() != savedUsername || password.text != savedPassword) {
      if (!mounted) return;
      setState(() { loading = false; error = 'غلط یوزرنیم یا پاس ورڈ۔ دوبارہ کوشش کریں۔'; });
      return;
    }
    await prefs.setBool('academy_remember_me', rememberMe);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061D39), Color(0xFF0D4D86), Color(0xFF1681C5)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 14,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(radius: 48, backgroundColor: lightBlue,
                          child: Icon(Icons.school, size: 55, color: navy)),
                        const SizedBox(height: 16),
                        Text(schoolName, textAlign: TextAlign.center,
                          style: const TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        const Text('SCHOOL MANAGEMENT SYSTEM',
                          style: TextStyle(color: blue, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                        const SizedBox(height: 25),
                        TextField(controller: username, textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
                        const SizedBox(height: 14),
                        TextField(controller: password, obscureText: obscurePassword,
                          onSubmitted: (_) => login(),
                          decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(onPressed: () => setState(() => obscurePassword = !obscurePassword),
                              icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off)))),
                        const SizedBox(height: 8),
                        Row(children: [
                          Checkbox(value: rememberMe, onChanged: (v) => setState(() => rememberMe = v ?? false)),
                          const Text('Remember Me'), const Spacer(),
                          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPasswordResetPage())), child: const Text('Forgot Password?')),
                        ]),
                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, height: 52,
                          child: FilledButton.icon(onPressed: loading ? null : login,
                            icon: loading ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login),
                            label: const Text('LOGIN'))),
                        const SizedBox(height: 14),
                        const Text('Authorized School Account', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== RECOVERY ID + ONE-TIME ADMIN RESET CODE ==============
class AdminPasswordResetPage extends StatefulWidget {
  const AdminPasswordResetPage({super.key});
  @override
  State<AdminPasswordResetPage> createState() => _AdminPasswordResetPageState();
}

class _AdminPasswordResetPageState extends State<AdminPasswordResetPage> {
  final reference = TextEditingController();
  final resetCode = TextEditingController();
  final newPass = TextEditingController();
  final confirmPass = TextEditingController();
  String? generatedReference;
  String message = '';
  bool done = false;

  String makeDigits(int length) {
    final r = Random.secure();
    return List.generate(length, (_) => r.nextInt(10).toString()).join();
  }

  Future<void> createRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final ref = 'SMS-${makeDigits(6)}';
    final requests = jsonDecode(prefs.getString('academy_recovery_requests') ?? '{}') as Map<String, dynamic>;
    requests[ref] = {'createdAt': DateTime.now().millisecondsSinceEpoch, 'device': await getDeviceId(), 'used': false};
    await prefs.setString('academy_recovery_requests', jsonEncode(requests));
    if (!mounted) return;
    setState(() { generatedReference = ref; message = 'یہ Reference ID ایڈمن کو دیں۔'; });
  }

  Future<void> applyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final ref = reference.text.trim().toUpperCase();
    final requests = jsonDecode(prefs.getString('academy_recovery_requests') ?? '{}') as Map<String, dynamic>;
    final req = requests[ref];
    if (req is! Map || req['used'] == true) { setState(() => message = 'Reference ID درست نہیں یا پہلے استعمال ہو چکی ہے۔'); return; }
    final codes = jsonDecode(prefs.getString('academy_recovery_codes') ?? '{}') as Map<String, dynamic>;
    final entry = codes[ref];
    if (entry is! Map || entry['used'] == true || (entry['expires'] as int? ?? 0) < DateTime.now().millisecondsSinceEpoch || entry['code'] != resetCode.text.trim()) {
      setState(() => message = 'Reset Code غلط، ختم شدہ یا پہلے استعمال ہو چکا ہے۔'); return;
    }
    if (newPass.text.length < 8 || newPass.text != confirmPass.text) {
      setState(() => message = 'نیا پاس ورڈ کم از کم 8 حروف کا ہو اور دونوں پاس ورڈ ایک جیسے ہوں۔'); return;
    }
    await prefs.setString('academy_customer_password', newPass.text);
    req['used'] = true;
    entry['used'] = true;
    requests[ref] = req;
    codes[ref] = entry;
    await prefs.setString('academy_recovery_requests', jsonEncode(requests));
    await prefs.setString('academy_recovery_codes', jsonEncode(codes));
    if (!mounted) return;
    setState(() { done = true; message = 'پاس ورڈ کامیابی سے تبدیل ہوگیا۔ اب نئے پاس ورڈ سے Login کریں۔'; });
  }

  @override
  void dispose() { reference.dispose(); resetCode.dispose(); newPass.dispose(); confirmPass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Password Recovery')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.lock_reset, size: 58, color: navy),
      const Text('پہلے Recovery Reference ID بنائیں۔ یہ ID ایڈمن کو دیں، ایڈمن آپ کو ایک بار استعمال ہونے والا Reset Code دے گا۔', textAlign: TextAlign.center),
      const SizedBox(height: 14),
      if (generatedReference == null) FilledButton.icon(onPressed: createRequest, icon: const Icon(Icons.confirmation_number), label: const Text('Generate Recovery Reference ID')),
      if (generatedReference != null) Card(color: lightBlue, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [const Text('Your Recovery Reference ID'), SelectableText(generatedReference!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navy)), const Text('یہ ID ایڈمن کو بتائیں۔')]))),
      const Divider(height: 28),
      TextField(controller: reference, decoration: const InputDecoration(labelText: 'Recovery Reference ID (SMS-xxxxxx)')),
      const SizedBox(height: 10),
      TextField(controller: resetCode, decoration: const InputDecoration(labelText: 'One-time Reset Code')),
      const SizedBox(height: 10),
      TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
      const SizedBox(height: 10),
      TextField(controller: confirmPass, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
      if (message.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: done ? Colors.green : navy))),
      FilledButton.icon(onPressed: done ? null : applyReset, icon: const Icon(Icons.password), label: const Text('Verify Code & Reset Password')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRecoveryIssuePage())), icon: const Icon(Icons.admin_panel_settings), label: const Text('Admin: Issue Recovery Code')),
      if (done) OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login')),
    ]),
  );
}

class AdminRecoveryIssuePage extends StatefulWidget {
  const AdminRecoveryIssuePage({super.key});
  @override
  State<AdminRecoveryIssuePage> createState() => _AdminRecoveryIssuePageState();
}

class _AdminRecoveryIssuePageState extends State<AdminRecoveryIssuePage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  final ref = TextEditingController();
  bool authorized = false;
  String message = '';
  String? issuedCode;

  Future<void> issue() async {
    if (!authorized) {
      if (user.text.trim() != adminUsername || pass.text != adminPassword) { setState(() => message = 'Admin login درست نہیں۔'); return; }
      setState(() { authorized = true; message = 'Admin verified. اب صارف کی Reference ID درج کریں۔'; });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final id = ref.text.trim().toUpperCase();
    final requests = jsonDecode(prefs.getString('academy_recovery_requests') ?? '{}') as Map<String, dynamic>;
    final request = requests[id];
    if (request is! Map || request['used'] == true) { setState(() => message = 'یہ Reference ID موجود نہیں یا پہلے استعمال ہو چکی ہے۔'); return; }
    final code = List.generate(8, (_) => Random.secure().nextInt(10).toString()).join();
    final codes = jsonDecode(prefs.getString('academy_recovery_codes') ?? '{}') as Map<String, dynamic>;
    codes[id] = {'code': code, 'expires': DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch, 'used': false};
    await prefs.setString('academy_recovery_codes', jsonEncode(codes));
    if (!mounted) return;
    setState(() { issuedCode = code; message = 'یہ کوڈ صارف کو دیں۔ 15 منٹ بعد ختم ہو جائے گا اور ایک بار استعمال ہوگا۔'; });
  }

  @override
  void dispose() { user.dispose(); pass.dispose(); ref.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Recovery Requests')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.admin_panel_settings, size: 58, color: navy),
      if (!authorized) ...[
        TextField(controller: user, decoration: const InputDecoration(labelText: 'Admin Username')),
        const SizedBox(height: 10),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Admin Password')),
      ] else ...[
        const Text('Admin Login Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: ref, decoration: const InputDecoration(labelText: 'User Recovery Reference ID')),
      ],
      if (message.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(message)),
      if (issuedCode != null) Card(color: lightBlue, child: Padding(padding: const EdgeInsets.all(16), child: SelectableText('RESET CODE: $issuedCode', textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: navy)))),
      FilledButton(onPressed: issue, child: Text(authorized ? 'Verify ID & Generate One-time Code' : 'Admin Login')),
    ]),
  );
}

// ================= ADMIN LOGIN =================

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  void login() {
    if (username.text.trim() == adminUsername &&
        password.text == adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminPanelPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong Admin Login'),
        ),
      );
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: username,
              decoration: const InputDecoration(
                labelText: 'Admin Username',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Admin Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ADMIN LICENSE GENERATOR =================

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final school = TextEditingController();
  final phone = TextEditingController();
  final deviceId = TextEditingController();

  String duration = '1 Month';
  String generatedKey = '';

  Future<void> generate() async {
    if (school.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        deviceId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter School, Mobile and Device ID'),
        ),
      );
      return;
    }

    final random = Random.secure();

    final code = List.generate(
      20,
      (_) => random.nextInt(16).toRadixString(16).toUpperCase(),
    ).join();

    final key = 'SMS-$code';

    final p = await SharedPreferences.getInstance();

    await p.setString('academy_generated_license', key);
    await p.setString('academy_license_school', school.text.trim());
    await p.setString('academy_license_phone', phone.text.trim());
    await p.setString('academy_license_device', deviceId.text.trim());
    await p.setString('academy_license_duration', duration);

    setState(() {
      generatedKey = key;
    });
  }

  @override
  void dispose() {
    school.dispose();
    phone.dispose();
    deviceId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin License Generator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.verified_user,
            size: 60,
            color: blue,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: school,
            decoration: const InputDecoration(
              labelText: 'School Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Customer Mobile Number',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: deviceId,
            decoration: const InputDecoration(
              labelText: 'Customer Device ID',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: duration,
            decoration: const InputDecoration(
              labelText: 'License Duration',
            ),
            items: const [
              DropdownMenuItem(
                value: '1 Month',
                child: Text('1 Month'),
              ),
              DropdownMenuItem(
                value: '3 Months',
                child: Text('3 Months'),
              ),
              DropdownMenuItem(
                value: '1 Year',
                child: Text('1 Year'),
              ),
              DropdownMenuItem(
                value: 'Lifetime',
                child: Text('Lifetime'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => duration = v);
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: generate,
            icon: const Icon(Icons.key),
            label: const Text('Generate License Key'),
          ),
          if (generatedKey.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Generated License Key'),
            SelectableText(
              generatedKey,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: generatedKey),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Key Copied'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Key'),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Note: This is a local prototype. Secure activation '
            'on another device and expiry enforcement are not implemented.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// ================= HOME DASHBOARD DATA =================

const schoolClasses = [
  'Play Group',
  'Nursery',
  'Prep',
  'First',
  'Second',
  'Third',
  'Fourth',
  'Fifth',
  'Sixth',
  'Seventh',
  'Eighth',
  'Ninth',
  'Tenth',
];

List<String> schoolSubjects(String c) {
  if ([
    'First',
    'Second',
    'Third',
    'Fourth',
    'Fifth'
  ].contains(c)) {
    return [
      'English',
      'Urdu',
      'Mathematics',
      'General Knowledge',
      'Islamiat'
    ];
  }

  if ([
    'Sixth',
    'Seventh',
    'Eighth'
  ].contains(c)) {
    return [
      'English',
      'Urdu',
      'Mathematics',
      'Science',
      'Islamiat',
      'Computer',
      'Social Studies'
    ];
  }

  return [
    'English',
    'Urdu',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer',
    'Islamiat',
    'Pakistan Studies'
  ];
}

Future<List<Map<String, dynamic>>> readData(String key) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(key);

  if (raw == null) return [];

  try {
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map(
        (e) => Map<String, dynamic>.from(e),
      ),
    );
  } catch (_) {
    return [];
  }
}

Future<void> writeData(
  String key,
  List<Map<String, dynamic>> data,
) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(key, jsonEncode(data));
}
// ============ PART 3/4 ============
// SCHOOL DASHBOARD AND HOME PAGE

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  String school = 'School Management System';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> transport = [];
  List<Map<String, dynamic>> salaries = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> notices = [];
  List<Map<String, dynamic>> syllabusItems = [];
  List<Map<String, dynamic>> dateSheetItems = [];

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    final p = await SharedPreferences.getInstance();

    final s = await readData('academy_students');
    final f = await readData('academy_fees');
    final a = await readData('academy_attendance');
    final m = await readData('academy_marks');
    final t = await readData('academy_transport');
    final sal = await readData('academy_salaries');
    final ex = await readData('academy_expenses');
    final n = await readData('academy_notices');
    final sy = await readData('academy_syllabus');
    final ds = await readData('academy_date_sheet');

    if (!mounted) return;

    setState(() {
      school = p.getString('academy_name') ??
          'School Management System';
      students = s;
      fees = f;
      attendance = a;
      marks = m;
      transport = t;
      salaries = sal;
      expenses = ex;
      notices = n;
      syllabusItems = sy;
      dateSheetItems = ds;
    });
  }

  Future<void> saveAll() async {
    await writeData('academy_students', students);
    await writeData('academy_fees', fees);
    await writeData('academy_attendance', attendance);
    await writeData('academy_marks', marks);
    await writeData('academy_transport', transport);
    await writeData('academy_salaries', salaries);
    await writeData('academy_expenses', expenses);
    await writeData('academy_notices', notices);
    await writeData('academy_syllabus', syllabusItems);
    await writeData('academy_date_sheet', dateSheetItems);
    await loadAll();
  }

  double get totalFees => fees.fold<double>(
        0,
        (a, e) =>
            a + (double.tryParse('${e['amount']}') ?? 0),
      );

  double get totalExpenses => expenses.fold<double>(
        0,
        (a, e) =>
            a + (double.tryParse('${e['amount']}') ?? 0),
      );

  double get totalSalaries => salaries.fold<double>(
        0,
        (a, e) =>
            a + (double.tryParse('${e['amount']}') ?? 0),
      );

  Widget statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboard() {
    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0B2E59),
                  Color(0xFF2875B8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.school,
                    color: Color(0xFF123B70),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        school,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'School Management Dashboard',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              statCard(
                'Total Students',
                '${students.length}',
                Icons.people,
                Colors.blue,
              ),
              statCard(
                'Fee Received',
                'Rs ${totalFees.toStringAsFixed(0)}',
                Icons.payments,
                Colors.green,
              ),
              statCard(
                'Attendance Records',
                '${attendance.length}',
                Icons.fact_check,
                Colors.orange,
              ),
              statCard(
                'Exam Records',
                '${marks.length}',
                Icons.menu_book,
                Colors.purple,
              ),
              statCard(
                'School Expenses',
                'Rs ${totalExpenses.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                Colors.red,
              ),
              statCard(
                'Staff Salaries',
                'Rs ${totalSalaries.toStringAsFixed(0)}',
                Icons.badge,
                Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('School Portals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())), icon: const Icon(Icons.admin_panel_settings), label: const Text('Admin Login')),
                  FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolePortalPage(role: 'Staff'))), icon: const Icon(Icons.badge), label: const Text('Staff Login')),
                  FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolePortalPage(role: 'Parent'))), icon: const Icon(Icons.family_restroom), label: const Text('Parent Login')),
                ]),
                const SizedBox(height: 6),
                const Text('Separate staff and parent accounts need to be created by the school administrator.', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Teaching & Communication', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: .9, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
            _dashboardTile(context, 'Notice Board', Icons.campaign, Colors.pink, 11),
            _dashboardTile(context, 'Date Sheet', Icons.calendar_month, Colors.cyan, 12),
            _dashboardTile(context, 'Syllabus', Icons.menu_book, Colors.green, 13),
          ]),
          const SizedBox(height: 18),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_add),
                label: const Text('Add Student'),
                onPressed: () =>
                    setState(() => selected = 1),
              ),
              ActionChip(
                avatar: const Icon(Icons.payments),
                label: const Text('Collect Fee'),
                onPressed: () =>
                    setState(() => selected = 2),
              ),
              ActionChip(
                avatar: const Icon(Icons.fact_check),
                label: const Text('Attendance'),
                onPressed: () =>
                    setState(() => selected = 3),
              ),
              ActionChip(
                avatar: const Icon(Icons.school),
                label: const Text('Exams'),
                onPressed: () =>
                    setState(() => selected = 4),
              ),
              ActionChip(
                avatar: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF Reports'),
                onPressed: () =>
                    setState(() => selected = 5),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.account_tree,
                color: Color(0xFF123B70),
              ),
              title: const Text(
                'Organization Workflow',
              ),
              subtitle: const Text(
                'School hierarchy and departments',
              ),
              trailing:
                  const Icon(Icons.arrow_forward_ios),
              onTap: () =>
                  setState(() => selected = 9),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Recent Fee Payments',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          ...fees.reversed.take(5).map(
            (f) => Card(
              child: ListTile(
                leading:
                    const Icon(Icons.receipt_long),
                title: Text(
                  '${f['studentName'] ?? ''}',
                ),
                subtitle: Text(
                  '${f['date'] ?? ''}',
                ),
                trailing: Text(
                  'Rs ${f['amount'] ?? 0}',
                ),
              ),
            ),
          ),

          if (fees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No fee payments recorded yet.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _dashboardTile(BuildContext context, String title, IconData icon, Color color, int page) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => selected = page),
      child: Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color, size: 26)),
        const SizedBox(height: 7), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[

      dashboard(),

      StudentsModule(
        students: students,
        onSave: (v) async {
          students = v;
          await saveAll();
        },
      ),

      FeesModule(
        students: students,
        fees: fees,
        onSave: (v) async {
          fees = v;
          await saveAll();
        },
      ),

      AttendanceModule(
        students: students,
        records: attendance,
        onSave: (v) async {
          attendance = v;
          await saveAll();
        },
      ),

      ExamsModule(
        students: students,
        marks: marks,
        onSave: (v) async {
          marks = v;
          await saveAll();
        },
      ),

      ReportsModule(
        school: school,
        students: students,
        fees: fees,
        marks: marks,
      ),

      ClassDocumentsModule(
        school: school,
        students: students,
        fees: fees,
        marks: marks,
      ),

      TransportModule(
        records: transport,
        onSave: (v) async {
          transport = v;
          await saveAll();
        },
      ),

      SalaryModule(
        records: salaries,
        onSave: (v) async {
          salaries = v;
          await saveAll();
        },
      ),

      SchoolExpensesModule(
        records: expenses,
        onSave: (v) async {
          expenses = v;
          await saveAll();
        },
      ),

      OrganizationChartPage(school: school),
      SchoolNoticeModule(records: notices, onSave: (v) async { notices = v; await saveAll(); }),
      SchoolPlannerModule(title: 'Date Sheet', storageKey: 'academy_date_sheet', records: dateSheetItems, onSave: (v) async { dateSheetItems = v; await saveAll(); }, dateMode: true),
      SchoolPlannerModule(title: 'Syllabus', storageKey: 'academy_syllabus', records: syllabusItems, onSave: (v) async { syllabusItems = v; await saveAll(); }),
    ];

    const titles = [
      'Dashboard',
      'Students',
      'Fees',
      'Attendance',
      'Exams / DMC',
      'Reports',
      'Class-wise Cards & Slips',
      'Transport',
      'Staff Salary',
      'School Expenses',
      'Organization Workflow',
      'Notice Board',
      'Date Sheet',
      'Syllabus',
    ];

    const icons = [
      Icons.home,
      Icons.people,
      Icons.payments,
      Icons.fact_check,
      Icons.school,
      Icons.picture_as_pdf,
      Icons.card_membership,
      Icons.directions_bus,
      Icons.badge,
      Icons.account_balance_wallet,
      Icons.account_tree,
      Icons.campaign,
      Icons.calendar_month,
      Icons.menu_book,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selected == 0
              ? school
              : titles[selected],
        ),
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF123B70),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  school,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            for (int i = 0; i < titles.length; i++)
              ListTile(
                leading: Icon(icons[i]),
                title: Text(titles[i]),
                selected: selected == i,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selected = i);
                },
              ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: pages[selected],

      bottomNavigationBar: selected < 6
          ? NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (v) {
                setState(() => selected = v);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people),
                  label: 'Students',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments),
                  label: 'Fees',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check),
                  label: 'Attendance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school),
                  label: 'Exams',
                ),
                NavigationDestination(
                  icon: Icon(Icons.picture_as_pdf),
                  label: 'Reports',
                ),
              ],
            )
          : null,
    );
  }
}
 // ============== PART 4 ==============
 // STUDENTS, FEES, ATTENDANCE, EXAMS


class RolePortalPage extends StatelessWidget {
  final String role;
  const RolePortalPage({super.key, required this.role});
  @override
  Widget build(BuildContext context) {
    final user = TextEditingController();
    final pass = TextEditingController();
    return Scaffold(appBar: AppBar(title: Text('$role Login')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(role == 'Parent' ? Icons.family_restroom : role == 'Staff' ? Icons.badge : Icons.admin_panel_settings, size: 54, color: navy),
      const SizedBox(height: 12), Text('$role Portal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18), TextField(controller: user, decoration: const InputDecoration(labelText: 'Username / Student ID')),
      const SizedBox(height: 12), TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
      const SizedBox(height: 16), FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portal accounts are not configured yet. Please ask the school administrator to create secure staff/parent accounts.'))), child: const Text('Login')),
      const SizedBox(height: 8), const Text('Ask the school administrator for your portal login details.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]))))));
  }
}

class SchoolNoticeModule extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const SchoolNoticeModule({super.key, required this.records, required this.onSave});
  @override
  State<SchoolNoticeModule> createState() => _SchoolNoticeModuleState();
}
class _SchoolNoticeModuleState extends State<SchoolNoticeModule> {
  late List<Map<String, dynamic>> items;
  @override
  void initState() { super.initState(); items = List<Map<String, dynamic>>.from(widget.records); }
  Future<void> add() async {
    final title = TextEditingController(); final body = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Add School Notice'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Notice title')), TextField(controller: body, maxLines: 4, decoration: const InputDecoration(labelText: 'Notice details'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))]));
    if (ok == true && title.text.trim().isNotEmpty) { setState(() => items.insert(0, {'title': title.text.trim(), 'body': body.text.trim(), 'date': DateTime.now().toString().substring(0, 10)})); widget.onSave(items); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: background, body: ListView(padding: const EdgeInsets.all(14), children: [FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: const Text('Add Notice')), const SizedBox(height: 10), if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No notices yet. Add your first school notice.'))), ...items.asMap().entries.map((e) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.campaign)), title: Text('${e.value['title'] ?? ''}'), subtitle: Text('${e.value['body'] ?? ''}\n${e.value['date'] ?? ''}'), isThreeLine: true, trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { setState(() => items.removeAt(e.key)); widget.onSave(items); }))))]));
}

class SchoolPlannerModule extends StatefulWidget {
  final String title; final String storageKey; final List<Map<String, dynamic>> records; final ValueChanged<List<Map<String, dynamic>>> onSave; final bool dateMode;
  const SchoolPlannerModule({super.key, required this.title, required this.storageKey, required this.records, required this.onSave, this.dateMode = false});
  @override
  State<SchoolPlannerModule> createState() => _SchoolPlannerModuleState();
}
class _SchoolPlannerModuleState extends State<SchoolPlannerModule> {
  late List<Map<String, dynamic>> items;
  @override
  void initState() { super.initState(); items = List<Map<String, dynamic>>.from(widget.records); }
  Future<void> add() async {
    final cls = TextEditingController();
    final subject = TextEditingController();
    final detail = TextEditingController();
    DateTime date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, refresh) {
            return AlertDialog(
              title: Text('Add ${widget.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cls,
                      decoration: const InputDecoration(labelText: 'Class'),
                    ),
                    TextField(
                      controller: subject,
                      decoration: InputDecoration(
                        labelText: widget.dateMode
                            ? 'Subject / Paper'
                            : 'Subject / Chapter',
                      ),
                    ),
                    if (widget.dateMode)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            refresh(() => date = d);
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text('${date.day}/${date.month}/${date.year}'),
                      ),
                    TextField(
                      controller: detail,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: widget.dateMode
                            ? 'Time / Instructions'
                            : 'Syllabus details',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true &&
        cls.text.trim().isNotEmpty &&
        subject.text.trim().isNotEmpty) {
      setState(() {
        items.add({
          'class': cls.text.trim(),
          'subject': subject.text.trim(),
          'detail': detail.text.trim(),
          'date': widget.dateMode
              ? date.toIso8601String().substring(0, 10)
              : '',
        });
      });
      widget.onSave(items);
    }

    cls.dispose();
    subject.dispose();
    detail.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: Text('Add ${widget.title}')), const SizedBox(height: 10), if (items.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('No ${widget.title.toLowerCase()} entries yet.'))), ...items.asMap().entries.map((e) => Card(child: ListTile(leading: Icon(widget.dateMode ? Icons.event : Icons.menu_book, color: blue), title: Text('${e.value['subject'] ?? ''} — Class ${e.value['class'] ?? ''}'), subtitle: Text('${e.value['date'] ?? ''}  ${e.value['detail'] ?? ''}'), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { setState(() => items.removeAt(e.key)); widget.onSave(items); }))))]);
}

class StudentsModule extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const StudentsModule({
    super.key,
    required this.students,
    required this.onSave,
  });

  Future<void> addStudent(BuildContext context) async {
    final name = TextEditingController();
    final father = TextEditingController();
    final roll = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final monthlyFee = TextEditingController();
    final dob = TextEditingController();

    String cls = schoolClasses.first;
    String gender = 'Male';
    String photoPath = '';

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Student Registration'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: photoPath.isNotEmpty ? FileImage(File(photoPath)) : null,
                      child: photoPath.isEmpty ? const Icon(Icons.person_add, size: 38) : null,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 75,
                          maxWidth: 900,
                        );
                        if (picked != null) setDialogState(() => photoPath = picked.path);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Upload Student Photo'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Student Name *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter student name'
                              : null,
                    ),
                    TextFormField(
                      controller: father,
                      decoration: const InputDecoration(
                        labelText: 'Father Name *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter father name'
                              : null,
                    ),
                    TextFormField(
                      controller: roll,
                      decoration: const InputDecoration(
                        labelText: 'Roll / Admission Number',
                      ),
                    ),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Parent Contact',
                      ),
                    ),
                    TextFormField(
                      controller: dob,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                      ),
                    ),
                    TextFormField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: cls,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                      ),
                      items: schoolClasses
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => cls = v);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => gender = v);
                        }
                      },
                    ),
                    TextFormField(
                      controller: monthlyFee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Fee (Rs)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save Student'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final record = <String, dynamic>{
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'name': name.text.trim(),
        'father': father.text.trim(),
        'roll': roll.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'dob': dob.text.trim(),
        'class': cls,
        'gender': gender,
        'totalFee': monthlyFee.text.trim(),
        'registrationFee': '0',
        'guardian': '',
        'photoPath': photoPath,
        'admissionDate':
            DateTime.now().toString().substring(0, 10),
      };

      onSave([...students, record]);
    }

    name.dispose();
    father.dispose();
    roll.dispose();
    phone.dispose();
    address.dispose();
    monthlyFee.dispose();
    dob.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => addStudent(context),
          icon: const Icon(Icons.person_add),
          label: const Text('New Student Registration'),
        ),
        const SizedBox(height: 12),
        ...students.map(
          (s) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: (s['photoPath'] != null && '${s['photoPath']}'.isNotEmpty && File('${s['photoPath']}').existsSync())
                    ? FileImage(File('${s['photoPath']}')) : null,
                child: (s['photoPath'] == null || '${s['photoPath']}'.isEmpty || !File('${s['photoPath']}').existsSync())
                    ? const Icon(Icons.person) : null,
              ),
              title: Text('${s['name']}'),
              subtitle: Text(
                'Father: ${s['father']}\n'
                'Class: ${s['class']} | Roll: ${s['roll']}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    onSave(
                      students
                          .where((x) => x['id'] != s['id'])
                          .toList(),
                    );
                  }
                  if (v == 'id') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentIDCard(
                          school: 'School Management System',
                          student: s,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'id',
                    child: Text('Student ID Card'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Student'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (students.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text('No students registered'),
            ),
          ),
      ],
    );
  }
}


// ============== MONTHLY FEES MODULE ==============

class FeesModule extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> fees;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const FeesModule({
    super.key,
    required this.students,
    required this.fees,
    required this.onSave,
  });

  @override
  State<FeesModule> createState() => _FeesModuleState();
}

class _FeesModuleState extends State<FeesModule> {
  String selectedClass = 'All';
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String money(num value) => 'Rs ${value.toStringAsFixed(0)}';
  String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get visibleStudents => widget.students.where((s) =>
      selectedClass == 'All' || '${s['class']}' == selectedClass).toList();

  double paidFor(String studentId, String month) => widget.fees
      .where((f) => '${f['studentId']}' == studentId && '${f['month']}' == month)
      .fold<double>(0, (sum, f) => sum + (double.tryParse('${f['amount']}') ?? 0));

  double monthlyFee(Map<String, dynamic> s) =>
      double.tryParse('${s['totalFee'] ?? 0}') ?? 0;

  Future<DateTime?> chooseDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040),
    helpText: 'Select fee month / date',
  );

  Future<void> collect(Map<String, dynamic> student) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    DateTime paymentDate = DateTime.now();
    DateTime dueDate = DateTime(selectedMonth.year, selectedMonth.month, 10);
    String type = 'Monthly Fee';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Fee Payment - ${student['name']}'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Class: ${student['class']}  |  Roll: ${student['roll']}'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Fee Type'),
              items: const ['Monthly Fee', 'Admission Fee', 'Transport Fee', 'Other']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setDialogState(() => type = v ?? type),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fee Month'),
              subtitle: Text(monthKey(selectedMonth)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final d = await showDatePicker(
                  context: dialogContext,
                  initialDate: selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                  helpText: 'Choose any date in the fee month',
                );
                if (d != null) setState(() => selectedMonth = DateTime(d.year, d.month));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payment Date'),
              subtitle: Text(paymentDate.toString().substring(0, 10)),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final d = await showDatePicker(
                  context: dialogContext,
                  initialDate: paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                );
                if (d != null) setDialogState(() => paymentDate = d);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due Date'),
              subtitle: Text(dueDate.toString().substring(0, 10)),
              trailing: const Icon(Icons.event_available),
              onTap: () async {
                final d = await showDatePicker(
                  context: dialogContext,
                  initialDate: dueDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                );
                if (d != null) setDialogState(() => dueDate = d);
              },
            ),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Received Amount (Rs)',
                helperText: 'Monthly fee: ${money(monthlyFee(student))}',
              ),
            ),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Note / Remarks')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save Payment')),
          ],
        ),
      ),
    );

    final received = double.tryParse(amount.text.trim()) ?? 0;
    if (ok == true && received > 0) {
      final m = monthKey(selectedMonth);
      widget.onSave([
        ...widget.fees,
        {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'studentId': student['id'],
          'studentName': student['name'],
          'father': student['father'],
          'roll': student['roll'],
          'class': student['class'],
          'amount': received,
          'feeType': type,
          'month': m,
          'date': paymentDate.toString().substring(0, 10),
          'dueDate': dueDate.toString().substring(0, 10),
          'note': note.text.trim(),
        }
      ]);
    }
    amount.dispose();
    note.dispose();
  }

  Future<void> printSlip(Map<String, dynamic> s) async {
    final m = monthKey(selectedMonth);
    final monthly = monthlyFee(s);
    final paid = paidFor('${s['id']}', m);
    final due = (monthly - paid).clamp(0, double.infinity).toDouble();
    final payments = widget.fees.where((f) =>
      '${f['studentId']}' == '${s['id']}' && '${f['month']}' == m).toList();
    final doc = pw.Document();
    doc.addPage(pw.Page(pageFormat: PdfPageFormat.a5, margin: const pw.EdgeInsets.all(24), build: (_) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 2)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Center(child: pw.Text('SCHOOL MANAGEMENT SYSTEM', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
          pw.Center(child: pw.Text('MONTHLY FEE VOUCHER', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.Divider(thickness: 2),
          pw.Text('Voucher Date: ${DateTime.now().toString().substring(0,10)}'),
          pw.Text('Fee Month: $m'),
          pw.SizedBox(height: 12),
          pw.Text('Student: ${s['name']}'),
          pw.Text('Father: ${s['father'] ?? ''}'),
          pw.Text('Class: ${s['class']}     Roll: ${s['roll']}'),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ['Description', 'Amount (Rs.)'],
            data: [
              ['Monthly Fee', monthly.toStringAsFixed(0)],
              ['Received This Month', paid.toStringAsFixed(0)],
              ['Remaining Balance', due.toStringAsFixed(0)],
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Payment entries:'),
          ...payments.map((p) => pw.Text('${p['date']}  -  Rs ${p['amount']} (${p['feeType'] ?? 'Fee'})')),
          pw.Spacer(),
          pw.Text('Cashier Signature: __________________'),
          pw.SizedBox(height: 10),
          pw.Text('Parent Signature: __________________'),
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('Please keep this voucher for your record.', style: const pw.TextStyle(fontSize: 9))),
        ]),
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final m = monthKey(selectedMonth);
    final expected = visibleStudents.fold<double>(0, (a, s) => a + monthlyFee(s));
    final received = visibleStudents.fold<double>(0, (a, s) => a + paidFor('${s['id']}', m));
    final dueTotal = (expected - received).clamp(0, double.infinity).toDouble();
    return ListView(padding: const EdgeInsets.all(14), children: [
      const Text('Monthly Fee Management', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: selectedClass,
        decoration: const InputDecoration(labelText: 'Filter by Class'),
        items: ['All', ...schoolClasses].map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Classes' : c))).toList(),
        onChanged: (v) => setState(() => selectedClass = v ?? 'All'),
      ),
      Card(child: ListTile(
        leading: const Icon(Icons.calendar_month, color: blue),
        title: const Text('Selected Fee Month'),
        subtitle: Text(m),
        trailing: const Icon(Icons.edit_calendar),
        onTap: () async {
          final d = await chooseDate(selectedMonth);
          if (d != null) setState(() => selectedMonth = DateTime(d.year, d.month));
        },
      )),
      Row(children: [
        _feeSummary('Expected', expected, Colors.blue),
        _feeSummary('Received', received, Colors.green),
        _feeSummary('Due', dueTotal, Colors.red),
      ]),
      const SizedBox(height: 10),
      for (final s in visibleStudents) Builder(builder: (context) {
        final paid = paidFor('${s['id']}', m);
        final fee = monthlyFee(s);
        final due = (fee - paid).clamp(0, double.infinity).toDouble();
        return Card(child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('${s['name']}'.isNotEmpty ? '${s['name']}'.substring(0,1).toUpperCase() : '?')),
              title: Text('${s['name']}'),
              subtitle: Text('${s['class']} • Roll ${s['roll']} • Fee month $m'),
              trailing: Text(money(due), style: TextStyle(color: due > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
            ),
            Row(children: [
              Expanded(child: Text('Fee: ${money(fee)}')),
              Expanded(child: Text('Paid: ${money(paid)}')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => collect(s), icon: const Icon(Icons.add_card), label: const Text('Receive Fee'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.tonalIcon(onPressed: () => printSlip(s), icon: const Icon(Icons.receipt_long), label: const Text('Print Slip'))),
            ]),
          ]),
        ));
      }),
      if (visibleStudents.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No students in this class.')),
    ]);
  }

  Widget _feeSummary(String title, double amount, Color color) => Expanded(
    child: Card(child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        FittedBox(child: Text(money(amount), style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
    )),
  );
}


// ============== ATTENDANCE MODULE ==============

class AttendanceModule extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const AttendanceModule({
    super.key,
    required this.students,
    required this.records,
    required this.onSave,
  });

  Future<void> mark(BuildContext context) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found')),
      );
      return;
    }

    final today =
        DateTime.now().toString().substring(0, 10);

    final status = <String, bool>{
      for (final s in students) '${s['id']}': true,
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) =>
            AlertDialog(
          title: Text('Attendance - $today'),
          content: SizedBox(
            width: 350,
            height: 400,
            child: ListView(
              children: students.map((s) {
                final id = '${s['id']}';

                return CheckboxListTile(
                  value: status[id] ?? true,
                  title: Text('${s['name']}'),
                  subtitle: Text(
                    '${s['class']} | ${s['roll']}',
                  ),
                  onChanged: (v) {
                    setDialogState(() {
                      status[id] = v ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Save Attendance'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final todayRecords = students.map((s) {
        return <String, dynamic>{
          'studentId': s['id'],
          'studentName': s['name'],
          'class': s['class'],
          'date': today,
          'status': (status['${s['id']}'] ?? true)
              ? 'Present'
              : 'Absent',
        };
      }).toList();

      onSave([
        ...records.where((r) => r['date'] != today),
        ...todayRecords,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => mark(context),
          icon: const Icon(Icons.fact_check),
          label: const Text('Mark Attendance'),
        ),
        const SizedBox(height: 12),
        ...records.reversed.map(
          (r) => Card(
            child: ListTile(
              leading: Icon(
                r['status'] == 'Present'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: r['status'] == 'Present'
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text('${r['studentName']}'),
              subtitle: Text(
                '${r['class']} | ${r['date']}',
              ),
              trailing: Text('${r['status']}'),
            ),
          ),
        ),
      ],
    );
  }
}
// ============== EXAMS MODULE ==============
class ExamsModule extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> marks;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const ExamsModule({
    super.key,
    required this.students,
    required this.marks,
    required this.onSave,
  });

  Future<void> addMarks(BuildContext context) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register students first'),
        ),
      );
      return;
    }

    String studentId = '${students.first['id']}';

    final exam = TextEditingController(
      text: 'Monthly Test',
    );
    final subject = TextEditingController();
    final total = TextEditingController(text: '100');
    final obtained = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) =>
            AlertDialog(
          title: const Text('Add Exam Marks'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: studentId,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                  ),
                  items: students
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: '${s['id']}',
                          child: Text('${s['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => studentId = v);
                    }
                  },
                ),
                TextField(
                  controller: exam,
                  decoration: const InputDecoration(
                    labelText: 'Exam Name',
                    ),
                ),
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                  ),
                ),
                TextField(
                  controller: total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Marks',
                  ),
                ),
                TextField(
                  controller: obtained,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Obtained Marks',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Save Marks'),
            ),
          ],
        ),
      ),
    );
    final maxMarks = double.tryParse(total.text) ?? 0;
    final gotMarks =
        double.tryParse(obtained.text) ?? -1;

    if (saved == true &&
        subject.text.trim().isNotEmpty &&
        maxMarks > 0 &&
        gotMarks >= 0 &&
        gotMarks <= maxMarks) {
      final student = students.firstWhere(
        (s) => '${s['id']}' == studentId,
      );

      onSave([
        ...marks,
        {
          'studentId': studentId,
          'studentName': student['name'],
          'roll': student['roll'],
          'class': student['class'],
          'exam': exam.text.trim(),
          'subject': subject.text.trim(),
          'total': maxMarks,
          'obtained': gotMarks,
          'date':
              DateTime.now().toString().substring(0, 10),},
      ]);
    }

    exam.dispose();
    subject.dispose();
    total.dispose();
    obtained.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => addMarks(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Exam Marks'),
        ),
        const SizedBox(height: 12),
        ...marks.reversed.map(
          (m) => Card(
            child: ListTile(
              title: Text(
                '${m['studentName']} - ${m['subject']}',
              ),
              subtitle: Text(
                '${m['exam']} | ${m['class']}',
              ),
              trailing: Text(
                '${m['obtained']} / ${m['total']}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================= MISSING MODULES ADDED =================

class TransportModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const TransportModule({super.key, required this.records, required this.onSave});

  Future<void> add(BuildContext context) async {
    final name = TextEditingController();
    final route = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Add Transport Record'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Student Name')),
        TextField(controller: route, decoration: const InputDecoration(labelText: 'Route / Pickup Point')),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Rs')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    ));
    final value = double.tryParse(amount.text) ?? 0;
    if (ok == true && name.text.trim().isNotEmpty && value >= 0) {
      onSave([...records, {'student': name.text.trim(), 'route': route.text.trim(), 'amount': value, 'date': DateTime.now().toIso8601String()}]);
    }
    name.dispose(); route.dispose(); amount.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleRecordPage(
    title: 'Transport Records', addLabel: 'Add Transport', records: records,
    titleOf: (r) => '${r['student']}', subtitleOf: (r) => '${r['route']} • ${r['date']}',
    amountOf: (r) => r['amount'], onAdd: () => add(context), onSave: onSave,
  );
}

class SalaryModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const SalaryModule({super.key, required this.records, required this.onSave});

  Future<void> add(BuildContext context) async {
    final name = TextEditingController();
    final role = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Add Staff Salary'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Employee Name')),
        TextField(controller: role, decoration: const InputDecoration(labelText: 'Designation')),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Salary Rs')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    ));
    final value = double.tryParse(amount.text) ?? 0;
    if (ok == true && name.text.trim().isNotEmpty && value >= 0) {
      onSave([...records, {'name': name.text.trim(), 'role': role.text.trim(), 'amount': value, 'date': DateTime.now().toIso8601String()}]);
    }
    name.dispose(); role.dispose(); amount.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleRecordPage(
    title: 'Staff Salary', addLabel: 'Add Salary', records: records,
    titleOf: (r) => '${r['name']}', subtitleOf: (r) => '${r['role']} • ${r['date']}',
    amountOf: (r) => r['amount'], onAdd: () => add(context), onSave: onSave,
  );
}

class SchoolExpensesModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const SchoolExpensesModule({super.key, required this.records, required this.onSave});

  Future<void> add(BuildContext context) async {
    final title = TextEditingController();
    final category = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Add School Expense'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Rs')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    ));
    final value = double.tryParse(amount.text) ?? 0;
    if (ok == true && title.text.trim().isNotEmpty && value >= 0) {
      onSave([...records, {'title': title.text.trim(), 'category': category.text.trim(), 'amount': value, 'date': DateTime.now().toIso8601String()}]);
    }
    title.dispose(); category.dispose(); amount.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleRecordPage(
    title: 'School Expenses', addLabel: 'Add Expense', records: records,
    titleOf: (r) => '${r['title']}', subtitleOf: (r) => '${r['category']} • ${r['date']}',
    amountOf: (r) => r['amount'], onAdd: () => add(context), onSave: onSave,
  );
}

class _SimpleRecordPage extends StatelessWidget {
  final String title, addLabel;
  final List<Map<String, dynamic>> records;
  final String Function(Map<String, dynamic>) titleOf, subtitleOf;
  final dynamic Function(Map<String, dynamic>) amountOf;
  final VoidCallback onAdd;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const _SimpleRecordPage({required this.title, required this.addLabel, required this.records, required this.titleOf, required this.subtitleOf, required this.amountOf, required this.onAdd, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(0, (a, r) => a + (double.tryParse('${amountOf(r)}') ?? 0));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Card(child: ListTile(title: Text(title), subtitle: Text('Total: Rs ${total.toStringAsFixed(0)}'), leading: const Icon(Icons.account_balance_wallet))),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(addLabel)),
      ...records.asMap().entries.map((e) => Card(child: ListTile(
        title: Text(titleOf(e.value)), subtitle: Text(subtitleOf(e.value)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('Rs ${amountOf(e.value)}'), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { final copy = [...records]..removeAt(e.key); onSave(copy); })]),
      ))),
      if (records.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No records yet')),
    ]);
  }
}


// ============== CLASS-WISE AUTO DOCUMENTS ==============

class ClassDocumentsModule extends StatefulWidget {
  final String school;
  final List<Map<String, dynamic>> students, fees, marks;
  const ClassDocumentsModule({super.key, required this.school, required this.students, required this.fees, required this.marks});

  @override
  State<ClassDocumentsModule> createState() => _ClassDocumentsModuleState();
}

class _ClassDocumentsModuleState extends State<ClassDocumentsModule> {
  String selectedClass = 'First';
  String selectedExam = 'All Exams';
  DateTime feeMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> get classStudents => widget.students
      .where((s) => '${s['class']}' == selectedClass).toList();

  String get monthKey => '${feeMonth.year}-${feeMonth.month.toString().padLeft(2, '0')}';

  double feeOf(Map<String, dynamic> s) => double.tryParse('${s['totalFee'] ?? 0}') ?? 0;

  double paidOf(Map<String, dynamic> s) => widget.fees.where((f) =>
      '${f['studentId']}' == '${s['id']}' && '${f['month']}' == monthKey)
      .fold<double>(0, (a, f) => a + (double.tryParse('${f['amount']}') ?? 0));

  Future<void> chooseFeeMonth() async {
    final d = await showDatePicker(
      context: context, initialDate: feeMonth,
      firstDate: DateTime(2020), lastDate: DateTime(2040),
      helpText: 'Select month for fee vouchers',
    );
    if (d != null) setState(() => feeMonth = DateTime(d.year, d.month));
  }

  Future<void> makeClassPdf(String kind) async {
    final list = classStudents;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اس کلاس میں کوئی طالب علم موجود نہیں۔')));
      return;
    }
    if (kind == 'DMC' && !widget.marks.any((m) => '${m['class']}' == selectedClass)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اس کلاس کے امتحانی نمبر پہلے درج کریں۔')));
      return;
    }

    final doc = pw.Document();
    for (final s in list) {
      final imagePath = '${s['photoPath'] ?? ''}';
      pw.MemoryImage? photo;
      if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
        photo = pw.MemoryImage(await File(imagePath).readAsBytes());
      }

      if (kind == 'ID CARD') {
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a5, build: (_) => pw.Center(child: pw.Container(
          width: 350, padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.blue900, width: 2),
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text(widget.school, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text('STUDENT IDENTITY CARD', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
            pw.SizedBox(height: 12),
            if (photo != null) pw.Container(width: 82, height: 92, child: pw.Image(photo, fit: pw.BoxFit.cover)),
            pw.SizedBox(height: 8),
            pw.Text('${s['name']}', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
            pw.Text('Father: ${s['father'] ?? ''}'),
            pw.Text('Roll No: ${s['roll'] ?? ''}     Class: ${s['class'] ?? ''}'),
            pw.Text('DOB: ${s['dob'] ?? ''}     Contact: ${s['phone'] ?? ''}'),
            pw.SizedBox(height: 14),
            pw.Text('Admission: ${s['admissionDate'] ?? ''}'),
            pw.SizedBox(height: 14),
            pw.Text('Principal Signature: __________________'),
          ]),
        ))));
      } else if (kind == 'FEE SLIP') {
        final monthly = feeOf(s);
        final paid = paidOf(s);
        final due = (monthly - paid).clamp(0, double.infinity).toDouble();
        final payments = widget.fees.where((f) =>
          '${f['studentId']}' == '${s['id']}' && '${f['month']}' == monthKey).toList();
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a5, margin: const pw.EdgeInsets.all(22), build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 2)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            pw.Center(child: pw.Text(widget.school, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
            pw.Center(child: pw.Text('MONTHLY FEE VOUCHER', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Divider(thickness: 2),
            pw.Text('Voucher No: ${s['id']}-$monthKey'),
            pw.Text('Issue Date: ${DateTime.now().toString().substring(0,10)}'),
            pw.Text('Fee Month: $monthKey'),
            pw.SizedBox(height: 12),
            pw.Text('Student: ${s['name']}'),
            pw.Text('Father: ${s['father'] ?? ''}'),
            pw.Text('Class: ${s['class']}    Roll: ${s['roll']}'),
            pw.SizedBox(height: 14),
            pw.Table.fromTextArray(headers: ['Fee Description', 'Amount (Rs.)'], data: [
              ['Monthly Tuition Fee', monthly.toStringAsFixed(0)],
              ['Received', paid.toStringAsFixed(0)],
              ['Balance Due', due.toStringAsFixed(0)],
            ]),
            pw.SizedBox(height: 12),
            pw.Text('Payments:'),
            ...payments.map((p) => pw.Text('${p['date']}  Rs ${p['amount']}')),
            pw.Spacer(),
            pw.Text('Cashier Signature: __________________'),
            pw.SizedBox(height: 12),
            pw.Text('Parent Signature: __________________'),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('Please submit fee before the due date.', style: const pw.TextStyle(fontSize: 9))),
          ]),
        )));
      } else if (kind == 'DMC') {
        final rows = widget.marks.where((m) =>
          '${m['studentId']}' == '${s['id']}' &&
          (selectedExam == 'All Exams' || '${m['exam']}' == selectedExam)).toList();
        final total = rows.fold<double>(0, (a, m) => a + (double.tryParse('${m['total']}') ?? 0));
        final obtained = rows.fold<double>(0, (a, m) => a + (double.tryParse('${m['obtained']}') ?? 0));
        final percent = total > 0 ? obtained / total * 100 : 0.0;
        final grade = percent >= 90 ? 'A+' : percent >= 80 ? 'A' : percent >= 70 ? 'B' : percent >= 60 ? 'C' : percent >= 50 ? 'D' : 'Needs Improvement';
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(28), build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 2)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            pw.Center(child: pw.Text(widget.school, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
            pw.Center(child: pw.Text('DETAILED MARKS CERTIFICATE', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold))),
            pw.Divider(thickness: 2),
            pw.Text('Student Name: ${s['name']}'),
            pw.Text('Father Name: ${s['father'] ?? ''}'),
            pw.Text('Class: ${s['class']}    Roll No: ${s['roll']}'),
            pw.Text('Exam: $selectedExam     Session: ${DateTime.now().year}'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Sr.', 'Subject', 'Total', 'Obtained', '%', 'Grade'],
              data: rows.asMap().entries.map((e) {
                final m = e.value;
                final t = double.tryParse('${m['total']}') ?? 0;
                final o = double.tryParse('${m['obtained']}') ?? 0;
                final pct = t > 0 ? o / t * 100 : 0.0;
                final g = pct >= 90 ? 'A+' : pct >= 80 ? 'A' : pct >= 70 ? 'B' : pct >= 60 ? 'C' : pct >= 50 ? 'D' : 'F';
                return ['${e.key + 1}', '${m['subject']}', t.toStringAsFixed(0), o.toStringAsFixed(0), '${pct.toStringAsFixed(1)}%', g];
              }).toList(),
            ),
            pw.SizedBox(height: 14),
            pw.Text('Total Marks: ${total.toStringAsFixed(0)}'),
            pw.Text('Obtained Marks: ${obtained.toStringAsFixed(0)}'),
            pw.Text('Percentage: ${percent.toStringAsFixed(2)}%'),
            pw.Text('Overall Grade: $grade'),
            pw.Text('Result: ${rows.isEmpty ? 'NO MARKS' : percent >= 33 ? 'PASS' : 'FAIL'}'),
            pw.Spacer(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Class Teacher: ______________'),
              pw.Text('Principal: ______________'),
            ]),
            pw.SizedBox(height: 12),
            pw.Center(child: pw.Text('School-issued result document', style: const pw.TextStyle(fontSize: 9))),
          ]),
        )));
      } else {
        doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(35), build: (_) => pw.Center(child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
          pw.Text(widget.school, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 28),
          pw.Text('SCHOOL LEAVING CERTIFICATE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 25),
          pw.Text('This is to certify that ${s['name']}, son/daughter of ${s['father']}, Roll No. ${s['roll']}, Class ${s['class']}, was a student of this institution.', textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 24),
          pw.Text('Date of Birth: ${s['dob'] ?? ''}'),
          pw.Text('Date of Issue: ${DateTime.now().toString().substring(0,10)}'),
          pw.SizedBox(height: 45),
          pw.Text('Principal Signature: __________________'),
        ]))));
      }
    }
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final examNames = widget.marks.map((m) => '${m['exam']}').toSet().toList();
    final count = classStudents.length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Class-wise Auto Documents', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: selectedClass,
        decoration: const InputDecoration(labelText: 'Select Class'),
        items: schoolClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => selectedClass = v ?? schoolClasses.first),
      ),
      Card(child: ListTile(leading: const Icon(Icons.groups, color: blue), title: Text('$selectedClass Students'), trailing: Text('$count'))),
      Card(child: ListTile(
        leading: const Icon(Icons.calendar_month, color: blue),
        title: const Text('Fee Month / ماہانہ فیس کا مہینہ'),
        subtitle: Text(monthKey),
        trailing: const Icon(Icons.edit_calendar),
        onTap: chooseFeeMonth,
      )),
      DropdownButtonFormField<String>(
        value: selectedExam,
        decoration: const InputDecoration(labelText: 'Select Exam for DMC'),
        items: ['All Exams', ...examNames].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => selectedExam = v ?? 'All Exams'),
      ),
      const SizedBox(height: 12),
      for (final item in [
        ('ID CARD', 'Generate Class Student Cards (PDF)', Icons.badge),
        ('FEE SLIP', 'Generate Monthly Fee Slips (PDF)', Icons.receipt_long),
        ('DMC', 'Generate Class DMCs (PDF)', Icons.school),
        ('LEAVING', 'Generate Leaving Certificates (PDF)', Icons.workspace_premium),
      ])
        Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: lightBlue, child: Icon(item.$3, color: blue)),
          title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Class: $selectedClass • Students: $count'),
          trailing: const Icon(Icons.picture_as_pdf),
          onTap: () => makeClassPdf(item.$1),
        )),
      const SizedBox(height: 8),
      const Text('ہر منتخب کلاس کے ہر طالب علم کی الگ PDF دستاویز بنے گی۔ فیس سلپ منتخب مہینے کے حساب سے ہوگی۔ DMC کے لیے پہلے Exams میں نمبر درج کریں۔', style: TextStyle(color: Colors.black54)),
    ]);
  }
}


class StudentIDCard extends StatelessWidget {
  final String school;
  final Map<String, dynamic> student;
  const StudentIDCard({super.key, required this.school, required this.student});

  Future<void> printCard() async {
    final doc = pw.Document();
    final path = '${student['photoPath'] ?? ''}';
    pw.MemoryImage? photo;
    if (path.isNotEmpty && File(path).existsSync()) photo = pw.MemoryImage(File(path).readAsBytesSync());
    doc.addPage(pw.Page(build: (context) => pw.Center(child: pw.Container(
      width: 300, padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 2, color: PdfColors.blue900), borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text(school, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10), pw.Text('STUDENT ID CARD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (photo != null) pw.Container(width: 70, height: 80, child: pw.Image(photo, fit: pw.BoxFit.cover)),
        pw.Divider(), pw.Text('Name: ${student['name'] ?? ''}'),
        pw.Text('Father: ${student['father'] ?? ''}'), pw.Text('Roll: ${student['roll'] ?? ''}'),
        pw.Text('Class: ${student['class'] ?? ''}'), pw.Text('Phone: ${student['phone'] ?? ''}'),
      ]),
    ))));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final path = '${student['photoPath'] ?? ''}';
    final hasPhoto = path.isNotEmpty && File(path).existsSync();
    return Scaffold(
      appBar: AppBar(title: const Text('Student ID Card'), actions: [IconButton(onPressed: printCard, icon: const Icon(Icons.picture_as_pdf))]),
      body: Center(child: Card(child: Container(width: 330, padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.school, size: 42, color: blue), Text(school, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        const Divider(height: 25), CircleAvatar(radius: 35, backgroundImage: hasPhoto ? FileImage(File(path)) : null, child: hasPhoto ? null : const Icon(Icons.person, size: 35)),
        const SizedBox(height: 12), Text('${student['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('Father: ${student['father']}'), Text('Roll: ${student['roll']}'), Text('Class: ${student['class']}'), Text('Phone: ${student['phone']}'),
      ])))),
    );
  }
}

class ReportsModule extends StatelessWidget {
  final String school;
  final List<Map<String, dynamic>> students, fees, marks;
  const ReportsModule({super.key, required this.school, required this.students, required this.fees, required this.marks});

  Future<void> makeReport() async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(build: (context) => [
      pw.Text(school, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.Text('School Summary Report'), pw.Divider(),
      pw.Text('Total Students: ${students.length}'),
      pw.Text('Fee Payments: ${fees.length}'),
      pw.Text('Exam Records: ${marks.length}'),
      pw.SizedBox(height: 15),
      pw.Table.fromTextArray(headers: ['Student', 'Class', 'Roll'], data: students.map((s) => ['${s['name']}', '${s['class']}', '${s['roll']}']).toList()),
    ]));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(school, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: blue)),
    const SizedBox(height: 8),
    Card(child: ListTile(title: const Text('Students'), trailing: Text('${students.length}'))),
    Card(child: ListTile(title: const Text('Fee Records'), trailing: Text('${fees.length}'))),
    Card(child: ListTile(title: const Text('Exam Records'), trailing: Text('${marks.length}'))),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: makeReport, icon: const Icon(Icons.picture_as_pdf), label: const Text('Generate School PDF Report')),
  ]);
}

class OrganizationChartPage extends StatelessWidget {
  final String school;
  const OrganizationChartPage({super.key, required this.school});

  Widget node(String title, Color color) => Container(
    width: 260, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Text(school, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: blue)),
    const SizedBox(height: 20), Center(child: node('Owner / Director', navy)),
    const Center(child: Icon(Icons.arrow_downward, color: blue)),
    Center(child: node('Principal / Headmaster', blue)),
    const Center(child: Icon(Icons.arrow_downward, color: blue)),
    for (final item in ['Academic Department', 'Administration Department', 'Accounts Department', 'HR / Staff Department', 'Transport Department', 'Facilities & Support'])
      Card(child: ListTile(leading: const Icon(Icons.account_tree, color: blue), title: Text(item), subtitle: const Text('Reports to Principal / Headmaster'))),
    const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Employee logins are disabled'), subtitle: Text('This chart displays responsibilities only.'))),
  ]);
}
