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
  runApp(const SchoolManagementApp());
}

const Color navy = Color(0xFF092B50);
const Color blue = Color(0xFF1769AA);
const Color lightBlue = Color(0xFFEAF3FC);
const Color gold = Color(0xFFD6A947);
const Color background = Color(0xFFF3F6FA);

const String adminUsername = 'Muhammad Ilyas';

// اپنا Admin password یہاں اپنے موبائل میں درج کریں۔
const String adminPassword = 'CHANGE_THIS_PASSWORD';

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

  Future<void> checkApp() async {
    final p = await SharedPreferences.getInstance();

    final active = p.getBool('academy_license_active') ?? false;
    final username = p.getString('academy_customer_username') ?? '';

    if (!mounted) return;

    Widget next;

    if (!active) {
      next = const LicensePage();
    } else if (username.isEmpty) {
      next = const SetupPage();
    } else {
      next = const LoginPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
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

                      const SizedBox(height: 15),

                      const Text(
                        'License Support',
                        style: TextStyle(color: Colors.grey),
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
// ================= SETUP PAGE =================

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  final schoolName = TextEditingController();

  Future<void> save() async {
    if (username.text.trim().isEmpty ||
        password.text.isEmpty ||
        schoolName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمام خانے پُر کریں')),
      );
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

    await p.setString(
      'academy_name',
      schoolName.text.trim(),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    schoolName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school,
                    size: 65,
                    color: blue,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Create School Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: schoolName,
                    decoration: const InputDecoration(
                      labelText: 'School Name',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 20),
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

// ================= LOGIN PAGE =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  String error = '';
  String school = 'New Iqra Children Academy';

  static int logoTaps = 0;

  @override
  void initState() {
    super.initState();
    loadSchool();
  }

  Future<void> loadSchool() async {
    final p = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      school = p.getString('academy_name') ??
          'New Iqra Children Academy';
    });
  }

  Future<void> login() async {
    final p = await SharedPreferences.getInstance();

    final savedUser =
        p.getString('academy_customer_username') ?? '';

    final savedPass =
        p.getString('academy_customer_password') ?? '';

    if (username.text.trim() == savedUser &&
        password.text == savedPass) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } else {
      setState(() {
        error = 'Incorrect Username or Password';
      });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [navy, blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
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
                                builder: (_) =>
                                    const AdminLoginPage(),
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
                      const SizedBox(height: 15),
                      Text(
                        school,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text('School Management System'),
                      const SizedBox(height: 25),
                      TextField(
                        controller: username,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        onSubmitted: (_) => login(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: login,
                          child: const Text('LOGIN'),
                        ),
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
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

// ================= ADMIN LOGIN =================

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() =>
      _AdminLoginPageState();
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
            const Icon(
              Icons.admin_panel_settings,
              size: 65,
              color: blue,
            ),
            const SizedBox(height: 20),
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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: login,
                child: const Text('ADMIN LOGIN'),
              ),
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
  State<AdminPanelPage> createState() =>
      _AdminPanelPageState();
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
          content: Text('Enter all customer details'),
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

    await p.setString(
      'academy_generated_license',
      key,
    );

    await p.setString(
      'academy_license_school',
      school.text.trim(),
    );

    await p.setString(
      'academy_license_phone',
      phone.text.trim(),
    );

    await p.setString(
      'academy_license_device',
      deviceId.text.trim(),
    );

    await p.setString(
      'academy_license_duration',
      duration,
    );

    if (!mounted) return;

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
      appBar: AppBar(
        title: const Text('Admin License Generator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.verified_user,
            size: 65,
            color: blue,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: school,
            decoration: const InputDecoration(
              labelText: 'Customer School Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
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
          FilledButton.icon(
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
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: generatedKey),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('License Key Copied'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Key'),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Prototype only: this local generator does not '
            'provide secure cross-device activation or expiry enforcement.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// ================= DATA STORAGE HELPERS =================

const List<String> schoolClasses = [
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

List<String> schoolSubjects(String cls) {
  if ([
    'First',
    'Second',
    'Third',
    'Fourth',
    'Fifth',
  ].contains(cls)) {
    return [
      'English',
      'Urdu',
      'Mathematics',
      'General Knowledge',
      'Islamiat',
    ];
  }

  if ([
    'Sixth',
    'Seventh',
    'Eighth',
  ].contains(cls)) {
    return [
      'English',
      'Urdu',
      'Mathematics',
      'Science',
      'Islamiat',
      'Computer',
      'Social Studies',
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
    'Pakistan Studies',
  ];
}

Future<List<Map<String, dynamic>>> readData(String key) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(key);

  if (raw == null) return [];

  try {
    final decoded = jsonDecode(raw) as List;

    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> writeData(
  String key,
  List<Map<String, dynamic>> data,
) async {
  final p = await SharedPreferences.getInstance();

  await p.setString(
    key,
    jsonEncode(data),
  );
}
 // ================= HOME DASHBOARD =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;

  String school = 'New Iqra Children Academy';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> transport = [];
  List<Map<String, dynamic>> salaries = [];
  List<Map<String, dynamic>> expenses = [];

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

    if (!mounted) return;

    setState(() {
      school = p.getString('academy_name') ??
          'New Iqra Children Academy';
      students = s;
      fees = f;
      attendance = a;
      marks = m;
      transport = t;
      salaries = sal;
      expenses = ex;
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
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 31),
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
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navy, blue],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 29,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.school,
                    color: navy,
                    size: 34,
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
                          fontSize: 18,
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
            childAspectRatio: 1.35,
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
                Icons.school,
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
                label: const Text('Add Marks'),
                onPressed: () =>
                    setState(() => selected = 4),
              ),
              ActionChip(
                avatar: const Icon(Icons.picture_as_pdf),
                label: const Text('Reports'),
                onPressed: () =>
                    setState(() => selected = 5),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: lightBlue,
                child: Icon(
                  Icons.account_tree,
                  color: navy,
                ),
              ),
              title: const Text(
                'Organization Workflow',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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

          const SizedBox(height: 18),

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
                leading: const Icon(
                  Icons.receipt_long,
                  color: blue,
                ),
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
              padding: EdgeInsets.all(18),
              child: Text(
                'No fee payments recorded yet.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
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
    ];

    const titles = [
      'Dashboard',
      'Students',
      'Fees',
      'Attendance',
      'Exams / DMC',
      'Reports',
      'Transport',
      'Staff Salary',
      'School Expenses',
      'Organization Workflow',
    ];

    const icons = [
      Icons.home,
      Icons.people,
      Icons.payments,
      Icons.fact_check,
      Icons.school,
      Icons.picture_as_pdf,
      Icons.directions_bus,
      Icons.badge,
      Icons.account_balance_wallet,
      Icons.account_tree,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selected == 0 ? school : titles[selected],
        ),
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: navy,
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
// ================= TRANSPORT MODULE =================

class TransportModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const TransportModule({
    super.key,
    required this.records,
    required this.onSave,
  });

  Future<void> addRecord(BuildContext context) async {
    final student = TextEditingController();
    final route = TextEditingController();
    final amount = TextEditingController();
    final month = TextEditingController(
      text: DateTime.now().toString().substring(0, 7),
    );

    final key = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Transport Record'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: student,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Enter student name'
                          : null,
                ),
                TextFormField(
                  controller: route,
                  decoration: const InputDecoration(
                    labelText: 'Route / Pickup Point',
                  ),
                ),
                TextFormField(
                  controller: month,
                  decoration: const InputDecoration(
                    labelText: 'Month (YYYY-MM)',
                  ),
                ),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Transport Fee (Rs)',
                  ),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0
                          ? 'Enter valid amount'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      onSave([
        ...records,
        {
          'student': student.text.trim(),
          'route': route.text.trim(),
          'month': month.text.trim(),
          'amount': double.parse(amount.text),
          'date': DateTime.now().toIso8601String(),
        },
      ]);
    }

    student.dispose();
    route.dispose();
    amount.dispose();
    month.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(
      0,
      (a, r) =>
          a + (double.tryParse('${r['amount']}') ?? 0),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addRecord(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Transport'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _financeSummary('Total Transport Fees', total),
          const SizedBox(height: 12),
          ...records.asMap().entries.map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                  color: blue,
                ),
                title: Text('${e.value['student']}'),
                subtitle: Text(
                  '${e.value['route'] ?? ''} • '
                  '${e.value['month'] ?? ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs ${e.value['amount']}'),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        final copy = [...records]
                          ..removeAt(e.key);
                        onSave(copy);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (records.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No transport records yet'),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= STAFF SALARY MODULE =================

class SalaryModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const SalaryModule({
    super.key,
    required this.records,
    required this.onSave,
  });

  Future<void> addSalary(BuildContext context) async {
    final name = TextEditingController();
    final role = TextEditingController();
    final amount = TextEditingController();
    final month = TextEditingController(
      text: DateTime.now().toString().substring(0, 7),
    );

    final key = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Staff Salary'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Enter name'
                          : null,
                ),
                TextFormField(
                  controller: role,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                  ),
                ),
                TextFormField(
                  controller: month,
                  decoration: const InputDecoration(
                    labelText: 'Salary Month (YYYY-MM)',
                  ),
                ),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Salary Paid (Rs)',
                  ),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0
                          ? 'Enter valid amount'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      onSave([
        ...records,
        {
          'name': name.text.trim(),
          'role': role.text.trim(),
          'month': month.text.trim(),
          'amount': double.parse(amount.text),
          'date': DateTime.now().toIso8601String(),
        },
      ]);
    }

    name.dispose();
    role.dispose();
    amount.dispose();
    month.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(
      0,
      (a, r) =>
          a + (double.tryParse('${r['amount']}') ?? 0),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addSalary(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Salary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _financeSummary('Total Salary Paid', total),
          const SizedBox(height: 12),
          ...records.asMap().entries.map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.badge,
                  color: blue,
                ),
                title: Text('${e.value['name']}'),
                subtitle: Text(
                  '${e.value['role'] ?? ''} • '
                  '${e.value['month'] ?? ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs ${e.value['amount']}'),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        final copy = [...records]
                          ..removeAt(e.key);
                        onSave(copy);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (records.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No salary records yet'),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= SCHOOL EXPENSES MODULE =================

class SchoolExpensesModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const SchoolExpensesModule({
    super.key,
    required this.records,
    required this.onSave,
  });

  Future<void> addExpense(BuildContext context) async {
    final title = TextEditingController();
    final category = TextEditingController();
    final amount = TextEditingController();

    final key = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add School Expense'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Expense Description',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Enter description'
                          : null,
                ),
                TextFormField(
                  controller: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Rent, Electricity, Stationery',
                  ),
                ),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Rs)',
                  ),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0
                          ? 'Enter valid amount'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      onSave([
        ...records,
        {
          'title': title.text.trim(),
          'category': category.text.trim(),
          'amount': double.parse(amount.text),
          'date': DateTime.now().toIso8601String(),
        },
      ]);
    }

    title.dispose();
    category.dispose();
    amount.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(
      0,
      (a, r) =>
          a + (double.tryParse('${r['amount']}') ?? 0),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _financeSummary('Total School Expenses', total),
          const SizedBox(height: 12),
          ...records.asMap().entries.map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: blue,
                ),
                title: Text('${e.value['title']}'),
                subtitle: Text(
                  '${e.value['category'] ?? ''} • '
                  '${e.value['date'].toString().split('T').first}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs ${e.value['amount']}'),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        final copy = [...records]
                          ..removeAt(e.key);
                        onSave(copy);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (records.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No school expenses yet'),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= FINANCE SUMMARY =================

Widget _financeSummary(String title, double amount) {
  return Card(
    color: lightBlue,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: navy,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title)),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    ),
  );
}
// ================= STUDENTS MODULE =================

class StudentsModule extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final VoidCallback onSave;

  const StudentsModule(this.students, this.onSave, {super.key});

  @override
  State<StudentsModule> createState() => _StudentsModuleState();
}

class _StudentsModuleState extends State<StudentsModule> {
  final name = TextEditingController();
  final father = TextEditingController();
  final roll = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final guardian = TextEditingController();

  String selectedClass = 'Nursery';
  String photoPath = '';

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => photoPath = image.path);
    }
  }

  void addStudent() {
    if (name.text.trim().isEmpty ||
        father.text.trim().isEmpty ||
        roll.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Father Name and Roll No are required')),
      );
      return;
    }

    final exists = widget.students.any(
      (s) => s['roll'].toString() == roll.text.trim(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This Roll Number already exists')),
      );
      return;
    }

    widget.students.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name.text.trim(),
      'father': father.text.trim(),
      'roll': roll.text.trim(),
      'phone': phone.text.trim(),
      'address': address.text.trim(),
      'guardian': guardian.text.trim(),
      'class': selectedClass,
      'photo': photoPath,
      'date': DateTime.now().toString().substring(0, 10),
    });

    widget.onSave();

    name.clear();
    father.clear();
    roll.clear();
    phone.clear();
    address.clear();
    guardian.clear();

    setState(() => photoPath = '');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student Added Successfully')),
    );
  }

  Widget field(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Student Registration',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        Center(
          child: GestureDetector(
            onTap: pickPhoto,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: photoPath.isNotEmpty
                  ? FileImage(File(photoPath))
                  : null,
              child: photoPath.isEmpty
                  ? const Icon(Icons.camera_alt, size: 35)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 15),

        field('Student Name', name),
        field('Father Name', father),
        field('Registration / Roll Number', roll),
        field('Contact Number', phone,
            type: TextInputType.phone),
        field('Address', address),
        field('Guardian Name', guardian),

        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(
            labelText: 'Class',
            border: OutlineInputBorder(),
          ),
          items: schoolClasses.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedClass = v);
          },
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: addStudent,
          icon: const Icon(Icons.person_add),
          label: const Text('Save Student'),
        ),

        const Divider(height: 30),

        Text(
          'Registered Students (${widget.students.length})',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),

        ...widget.students.reversed.map((s) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: (s['photo'] != null &&
                        s['photo'].toString().isNotEmpty &&
                        File(s['photo'].toString()).existsSync())
                    ? FileImage(File(s['photo'].toString()))
                    : null,
                child: (s['photo'] == null ||
                        s['photo'].toString().isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(s['name'] ?? ''),
              subtitle: Text(
                'Father: ${s['father'] ?? ''}\n'
                'Roll: ${s['roll'] ?? ''} | Class: ${s['class'] ?? ''}\n'
                'Phone: ${s['phone'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    widget.students.remove(s);
                  });
                  widget.onSave();
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}


// ================= FEES MODULE =================

class FeesModule extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> fees;
  final VoidCallback onSave;

  const FeesModule(this.students, this.fees, this.onSave, {super.key});

  @override
  State<FeesModule> createState() => _FeesModuleState();
}

class _FeesModuleState extends State<FeesModule> {
  String? selectedStudent;
  String feeType = 'Monthly Fee';
  String month = 'January';

  final amount = TextEditingController();
  final note = TextEditingController();

  void collectFee() {
    if (selectedStudent == null || amount.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select student and enter amount')),
      );
      return;
    }

    final value = double.tryParse(amount.text.trim());

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final student = widget.students.firstWhere(
      (s) => s['id'].toString() == selectedStudent,
    );

    widget.fees.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': student['id'],
      'studentName': student['name'],
      'roll': student['roll'],
      'class': student['class'],
      'type': feeType,
      'month': month,
      'amount': value,
      'note': note.text.trim(),
      'date': DateTime.now().toString().substring(0, 10),
    });

    widget.onSave();
    amount.clear();
    note.clear();

    setState(() => selectedStudent = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fee Received Successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.fees.fold<double>(
      0,
      (sum, f) => sum + ((f['amount'] as num?)?.toDouble() ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Fee Collection',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet,
                color: Colors.green),
            title: const Text('Total Fee Received'),
            subtitle: Text(
              'Rs. ${total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedStudent,
          decoration: const InputDecoration(
            labelText: 'Select Student',
            border: OutlineInputBorder(),
          ),
          items: widget.students.map((s) {
            return DropdownMenuItem<String>(
              value: s['id'].toString(),
              child: Text('${s['name']} - ${s['roll']}'),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedStudent = v),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: feeType,
          decoration: const InputDecoration(
            labelText: 'Fee Type',
            border: OutlineInputBorder(),
          ),
          items: [
            'Monthly Fee',
            'Weekly Fee',
            'Admission Fee',
            'Annual Fee',
            'Exam Fee',
            'Other Fee',
          ].map((v) => DropdownMenuItem(
            value: v,
            child: Text(v),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => feeType = v);
          },
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: month,
          decoration: const InputDecoration(
            labelText: 'Month',
            border: OutlineInputBorder(),
          ),
          items: [
            'January', 'February', 'March', 'April',
            'May', 'June', 'July', 'August',
            'September', 'October', 'November', 'December',
          ].map((v) => DropdownMenuItem(
            value: v,
            child: Text(v),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => month = v);
          },
        ),

        const SizedBox(height: 12),

        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Received Amount (PKR)',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: note,
          decoration: const InputDecoration(
            labelText: 'Remarks',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: collectFee,
          icon: const Icon(Icons.payments),
          label: const Text('Collect Fee'),
        ),

        const Divider(height: 30),

        const Text(
          'Fee History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        ...widget.fees.reversed.map((f) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(f['studentName'] ?? ''),
              subtitle: Text(
                '${f['type']} | ${f['month']}\n'
                'Roll: ${f['roll']} | Date: ${f['date']}',
              ),
              isThreeLine: true,
              trailing: Text(
                'Rs. ${f['amount']}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
          );
        }),
      ],
    );
  }
}


// ================= ATTENDANCE MODULE =================

class AttendanceModule extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> records;
  final VoidCallback onSave;

  const AttendanceModule(this.students, this.records, this.onSave,
      {super.key});

  @override
  State<AttendanceModule> createState() => _AttendanceModuleState();
}

class _AttendanceModuleState extends State<AttendanceModule> {
  DateTime selectedDate = DateTime.now();
  String selectedClass = 'All Classes';

  String get dateText =>
      selectedDate.toString().substring(0, 10);

  List<Map<String, dynamic>> get visibleStudents {
    if (selectedClass == 'All Classes') {
      return widget.students;
    }

    return widget.students
        .where((s) => s['class'] == selectedClass)
        .toList();
  }

  void markAttendance(Map<String, dynamic> student, String status) {
    final index = widget.records.indexWhere((r) =>
        r['studentId'].toString() == student['id'].toString() &&
        r['date'] == dateText);

    final record = {
      'studentId': student['id'],
      'studentName': student['name'],
      'roll': student['roll'],
      'class': student['class'],
      'date': dateText,
      'status': status,
    };

    if (index >= 0) {
      widget.records[index] = record;
    } else {
      widget.records.add(record);
    }

    widget.onSave();
    setState(() {});
  }

  String statusFor(Map<String, dynamic> student) {
    final record = widget.records.where((r) =>
        r['studentId'].toString() == student['id'].toString() &&
        r['date'] == dateText);

    if (record.isEmpty) return 'Not Marked';
    return record.first['status'] ?? 'Not Marked';
  }

  @override
  Widget build(BuildContext context) {
    final present = widget.records.where(
      (r) => r['date'] == dateText && r['status'] == 'Present',
    ).length;

    final absent = widget.records.where(
      (r) => r['date'] == dateText && r['status'] == 'Absent',
    ).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Student Attendance',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Attendance Date'),
            subtitle: Text(dateText),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(
            labelText: 'Filter Class',
            border: OutlineInputBorder(),
          ),
          items: [
            'All Classes',
            ...schoolClasses,
          ].map((v) => DropdownMenuItem(
            value: v,
            child: Text(v),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedClass = v);
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _attendanceCount('Present', present, Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _attendanceCount('Absent', absent, Colors.red),
            ),
          ],
        ),

        const SizedBox(height: 15),

        ...visibleStudents.map((student) {
          final status = statusFor(student);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student['name']} (${student['roll']})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  Text('Class: ${student['class']}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Present'
                                ? Colors.green
                                : status == 'Absent'
                                    ? Colors.red
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            markAttendance(student, 'Present'),
                        child: const Text('Present'),
                      ),
                      TextButton(
                        onPressed: () =>
                            markAttendance(student, 'Absent'),
                        child: const Text('Absent'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _attendanceCount(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color)),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= EXAMS MODULE =================

class ExamsModule extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> marks;
  final VoidCallback onSave;

  const ExamsModule(this.students, this.marks, this.onSave,
      {super.key});

  @override
  State<ExamsModule> createState() => _ExamsModuleState();
}

class _ExamsModuleState extends State<ExamsModule> {
  String? selectedStudent;
  String selectedSubject = 'English';
  String examName = 'Monthly Test';

  final totalMarks = TextEditingController();
  final obtainedMarks = TextEditingController();

  void saveMarks() {
    if (selectedStudent == null ||
        totalMarks.text.trim().isEmpty ||
        obtainedMarks.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all required fields')),
      );
      return;
    }

    final total = double.tryParse(totalMarks.text.trim());
    final obtained = double.tryParse(obtainedMarks.text.trim());

    if (total == null || obtained == null ||
        total <= 0 || obtained < 0 || obtained > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid marks')),
      );
      return;
    }

    final student = widget.students.firstWhere(
      (s) => s['id'].toString() == selectedStudent,
    );

    final percentage = (obtained / total) * 100;

    String grade;
    if (percentage >= 80) {
      grade = 'A+';
    } else if (percentage >= 70) {
      grade = 'A';
    } else if (percentage >= 60) {
      grade = 'B';
    } else if (percentage >= 50) {
      grade = 'C';
    } else if (percentage >= 40) {
      grade = 'D';
    } else {
      grade = 'Fail';
    }

    widget.marks.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': student['id'],
      'studentName': student['name'],
      'roll': student['roll'],
      'class': student['class'],
      'exam': examName,
      'subject': selectedSubject,
      'total': total,
      'obtained': obtained,
      'percentage': percentage,
      'grade': grade,
      'date': DateTime.now().toString().substring(0, 10),
    });

    widget.onSave();

    totalMarks.clear();
    obtainedMarks.clear();
    setState(() => selectedStudent = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marks Saved Successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Exams & Results',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedStudent,
          decoration: const InputDecoration(
            labelText: 'Select Student',
            border: OutlineInputBorder(),
          ),
          items: widget.students.map((s) {
            return DropdownMenuItem<String>(
              value: s['id'].toString(),
              child: Text('${s['name']} - ${s['roll']}'),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedStudent = v),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: examName,
          decoration: const InputDecoration(
            labelText: 'Exam',
            border: OutlineInputBorder(),
          ),
          items: [
            'Monthly Test',
            'First Term',
            'Mid Term',
            'Final Term',
            'Annual Exam',value: v,
            child: Text(v),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => examName = v);
          },
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedSubject,
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
          ),
          items: schoolSubjects.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text(v),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedSubject = v);
          },
        ),

        const SizedBox(height: 12),

        TextField(
          controller: totalMarks,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Marks',
            border: OutlineInputBorder(),
          ),
        ),
            const SizedBox(height: 12),

        TextField(
          controller: obtainedMarks,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Obtained Marks',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: saveMarks,
          icon: const Icon(Icons.save),
          label: const Text('Save Result'),
        ),

        const Divider(height: 30),

        const Text(
          'Saved Marks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        ...widget.marks.reversed.map((m) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(
                '${m['studentName']} - ${m['subject']}',
              ),
              subtitle: Text(
                '${m['exam']} | Roll: ${m['roll']}\n'
                'Obtained: ${m['obtained']} / ${m['total']}'
                ' | Grade: ${m['grade']}',
              ),
              isThreeLine: true,
              trailing: Text(
                '${(m['percentage'] as num).toStringAsFixed(1)}%',
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  
        }
        // ================= REPORTS MODULE =================

class ReportsModule extends StatelessWidget {
  final String school;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> fees;
  final List<Map<String, dynamic>> marks;

  const ReportsModule(
    this.school,
    this.students,
    this.fees,
    this.marks, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final feeTotal = fees.fold<double>(
      0,
      (sum, f) => sum + ((f['amount'] as num?)?.toDouble() ?? 0),
    );

    final average = marks.isEmpty
        ? 0.0
        : marks.fold<double>(
              0,
              (sum, m) =>
                  sum + ((m['percentage'] as num?)?.toDouble() ?? 0),
            ) /
            marks.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '$school - Reports',
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        _reportCard(
          'Total Students',
          '${students.length}',
          Icons.people,
          Colors.blue,
        ),
        _reportCard(
          'Total Fee Received',
          'Rs. ${feeTotal.toStringAsFixed(0)}',
          Icons.payments,
          Colors.green,
        ),
        _reportCard(
          'Total Exam Records',
          '${marks.length}',
          Icons.menu_book,
          Colors.orange,
        ),
        _reportCard(
          'Average Marks Percentage',
          '${average.toStringAsFixed(1)}%',
          Icons.percent,
          Colors.purple,
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: () async {
            await printClassResultPdf(school, students, marks);
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Print Class Results PDF'),
        ),

        ElevatedButton.icon(
          onPressed: () async {
            await printFeePdf(school, fees);
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('Print Fee Report PDF'),
        ),

        ElevatedButton.icon(
          onPressed: () async {
            await printStudentListPdf(school, students);
          },
          icon: const Icon(Icons.people),
          label: const Text('Print Students List PDF'),
        ),
      ],
    );
  }

  Widget _reportCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


// ================= STUDENT ID CARD =================

class StudentIDCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final String school;

  const StudentIDCard({
    super.key,
    required this.student,
    required this.school,
  });

  @override
  Widget build(BuildContext context) {
    final photo = student['photo']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Card'),
      ),
      body: Center(
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.all(20),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school,
                  size: 35,
                  color: Colors.blue,
                ),
                const SizedBox(height: 5),
                Text(
                  school,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),

                CircleAvatar(
                  radius: 42,
                  backgroundImage: photo.isNotEmpty &&
                          File(photo).existsSync()
                      ? FileImage(File(photo))
                      : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),

                const SizedBox(height: 12),

                Text(
                  student['name']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _info('Father Name', student['father']),
                _info('Roll Number', student['roll']),
                _info('Class', student['class']),
                _info('Contact', student['phone']),

                const SizedBox(height: 12),

                Text(
                  'STUDENT ID CARD',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }
}


// ================= ORGANIZATION CHART =================

class OrganizationChartPage extends StatelessWidget {
  final String school;

  const OrganizationChartPage({
    super.key,
    required this.school,
  });

  Widget chartBox(String title, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Chart')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(
              school,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: chartBox(
              'Principal / Head',
              Icons.person,
              Colors.blue,
            ),
          ),

          const Center(
            child: Icon(Icons.arrow_downward, size: 30),
          ),

          Center(
            child: chartBox(
              'Administration',
              Icons.admin_panel_settings,
              Colors.purple,
            ),
          ),

          const Center(
            child: Icon(Icons.arrow_downward, size: 30),
          ),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              chartBox('Teaching Staff', Icons.school, Colors.green),
              chartBox('Accounts Department', Icons.calculate, Colors.orange),
              chartBox('Office Staff', Icons.business, Colors.teal),
              chartBox('Support Staff', Icons.support_agent, Colors.red),
            ],
          ),
        ],
      ),
    );
  }
}


// ================= PDF HELPERS =================

Future<void> _printPdf(
  String fileName,
  pw.Document pdf,
) async {
  await Printing.layoutPdf(
    name: fileName,
    onLayout: (format) async => pdf.save(),
  );
}

pw.Widget _pdfHeader(String school, String heading) {
  return pw.Column(
    children: [
      pw.Text(
        school,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        heading,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Divider(),
      pw.SizedBox(height: 10),
    ],
  );
}


// ================= STUDENTS PDF =================

Future<void> printStudentListPdf(
  String school,
  List<Map<String, dynamic>> students,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        _pdfHeader(school, 'Student Registration Report'),

        pw.TableHelper.fromTextArray(
          headers: [
            'Roll No',
            'Student Name',
            'Father Name',
            'Class',
            'Contact',
          ],
          data: students.map((s) {
            return [
              s['roll']?.toString() ?? '',
              s['name']?.toString() ?? '',
              s['father']?.toString() ?? '',
              s['class']?.toString() ?? '',
              s['phone']?.toString() ?? '',
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 15),

        pw.Text('Total Students: ${students.length}'),
      ],
    ),
  );

  await _printPdf('Student_Report.pdf', pdf);
}


// ================= FEE PDF =================

Future<void> printFeePdf(
  String school,
  List<Map<String, dynamic>> fees,
) async {
  final pdf = pw.Document();

  final total = fees.fold<double>(
    0,
    (sum, f) => sum + ((f['amount'] as num?)?.toDouble() ?? 0),
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        _pdfHeader(school, 'Fee Collection Report'),

        pw.TableHelper.fromTextArray(
          headers: [
            'Date',
            'Student',
            'Roll No',
            'Fee Type',
            'Month',
            'Amount',
          ],
          data: fees.map((f) {
            return [
              f['date']?.toString() ?? '',
              f['studentName']?.toString() ?? '',
              f['roll']?.toString() ?? '',
              f['type']?.toString() ?? '',
              f['month']?.toString() ?? '',
              'Rs. ${f['amount']}',
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 15),

        pw.Text(
          'Total Received: Rs. ${total.toStringAsFixed(0)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  await _printPdf('Fee_Report.pdf', pdf);
}


// ================= CLASS RESULT PDF =================

Future<void> printClassResultPdf(
  String school,
  List<Map<String, dynamic>> students,
  List<Map<String, dynamic>> marks,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        _pdfHeader(school, 'Examination Result Report'),

        pw.TableHelper.fromTextArray(
          headers: [
            'Roll No',
            'Student Name',
            'Class',
            'Exam',
            'Subject',
            'Obtained',
            'Total',
            'Grade',
          ],
          data: marks.map((m) {
            return [
              m['roll']?.toString() ?? '',
              m['studentName']?.toString() ?? '',
              m['class']?.toString() ?? '',
              m['exam']?.toString() ?? '',
              m['subject']?.toString() ?? '',
              m['obtained']?.toString() ?? '',
              m['total']?.toString() ?? '',
              m['grade']?.toString() ?? '',
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 15),

        pw.Text('Total Students: ${students.length}'),
      ],
    ),
  );

  await _printPdf('Examination_Results.pdf', pdf);
}


// ================= SINGLE STUDENT DMC PDF =================

Future<void> printDmcPdf(
  String school,
  Map<String, dynamic> student,
  List<Map<String, dynamic>> marks,
) async {
  final studentMarks = marks.where(
    (m) => m['studentId'].toString() ==
        student['id'].toString(),
  ).toList();

  final pdf = pw.Document();

  final obtained = studentMarks.fold<double>(
    0,
    (sum, m) =>
        sum + ((m['obtained'] as num?)?.toDouble() ?? 0),
  );

  final total = studentMarks.fold<double>(
    0,
    (sum, m) =>
        sum + ((m['total'] as num?)?.toDouble() ?? 0),
  );

  final percentage = total == 0 ? 0.0 : obtained / total * 100;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        _pdfHeader(school, 'Detailed Marks Certificate'),

        pw.Text('Student Name: ${student['name']}'),
        pw.Text('Father Name: ${student['father']}'),
        pw.Text('Roll Number: ${student['roll']}'),
        pw.Text('Class: ${student['class']}'),

        pw.SizedBox(height: 15),

        pw.TableHelper.fromTextArray(
          headers: ['Exam', 'Subject', 'Total', 'Obtained', 'Grade'],
          data: studentMarks.map((m) {
            return [
              m['exam']?.toString() ?? '',
              m['subject']?.toString() ?? '',
              m['total']?.toString() ?? '',
              m['obtained']?.toString() ?? '',
              m['grade']?.toString() ?? '',
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 15),

        pw.Text('Total Marks: ${total.toStringAsFixed(0)}'),
        pw.Text('Obtained Marks: ${obtained.toStringAsFixed(0)}'),
        pw.Text('Percentage: ${percentage.toStringAsFixed(1)}%'),

        pw.SizedBox(height: 40),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Teacher Signature: ______________'),
            pw.Text('Principal Signature: ______________'),
          ],
        ),
      ],
    ),
  );

  await _printPdf('Student_DMC.pdf', pdf);
}


// ================= FEE RECEIPT PDF =================

Future<void> printFeeReceiptPdf(
  String school,
  Map<String, dynamic> fee,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfHeader(school, 'Fee Payment Receipt'),

            pw.Text('Receipt Date: ${fee['date']}'),
            pw.SizedBox(height: 10),
            pw.Text('Student: ${fee['studentName']}'),
            pw.Text('Roll Number: ${fee['roll']}'),
            pw.Text('Class: ${fee['class']}'),
            pw.Text('Fee Type: ${fee['type']}'),
            pw.Text('Month: ${fee['month']}'),

            pw.SizedBox(height: 20),

            pw.Text(
              'Amount Received: Rs. ${fee['amount']}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),
            pw.Text('Remarks: ${fee['note'] ?? ''}'),

            pw.Spacer(),

            pw.Text('Cashier Signature: __________________'),
          ],
        ),
      ),
    ),
  );

  await _printPdf('Fee_Receipt.pdf', pdf);
}
