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
                    const CircleAvatar(
                      radius: 38,
                      child: Icon(Icons.person_add, size: 38),
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
        'photoPath': '',
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
              leading: const CircleAvatar(
                child: Icon(Icons.person),
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
                          school: 'New Iqra Children Academy',
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

// ============== FEES MODULE ==============

class FeesModule extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> fees;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const FeesModule({
    super.key,
    required this.students,
    required this.fees,
    required this.onSave,
  });

  Future<void> collect(BuildContext context) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register a student first'),
        ),
      );
      return;
    }

    final amount = TextEditingController();
    final month = TextEditingController(
      text: DateTime.now().toString().substring(0, 7),
    );

    String selectedId = '${students.first['id']}';
    String feeType = 'Monthly';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Collect Student Fee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedId,
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
                      setDialogState(() => selectedId = v);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: feeType,
                  decoration: const InputDecoration(
                    labelText: 'Fee Type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Monthly',
                      child: Text('Monthly'),
                    ),
                    DropdownMenuItem(
                      value: 'Weekly',
                      child: Text('Weekly'),
                    ),
                    DropdownMenuItem(
                      value: 'Admission',
                      child: Text('Admission'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => feeType = v);
                    }
                  },
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Received Amount (Rs)',
                  ),
                ),
                TextField(
                  controller: month,
                  decoration: const InputDecoration(
                    labelText: 'Month / Week',
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
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );

    final paid = double.tryParse(amount.text) ?? 0;

    if (saved == true && paid > 0) {
      final student = students.firstWhere(
        (s) => '${s['id']}' == selectedId,
      );

      onSave([
        ...fees,
        {
          'studentId': student['id'],
          'studentName': student['name'],
          'roll': student['roll'],
          'class': student['class'],
          'amount': paid,
          'feeType': feeType,
          'month': month.text.trim(),
          'date':
              DateTime.now().toString().substring(0, 10),
        },
      ]);
    }

    amount.dispose();
    month.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => collect(context),
          icon: const Icon(Icons.payments),
          label: const Text('Collect Fee'),
        ),
        const SizedBox(height: 12),
        ...fees.reversed.map(
          (f) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('${f['studentName']}'),
              subtitle: Text(
                '${f['feeType'] ?? 'Monthly'} | '
                '${f['month']} | ${f['date']}',
              ),
              trailing: Text('Rs ${f['amount']}'),
            ),
          ),
        ),
      ],
    );
  }
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

class StudentIDCard extends StatelessWidget {
  final String school;
  final Map<String, dynamic> student;
  const StudentIDCard({super.key, required this.school, required this.student});

  Future<void> printCard() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (context) => pw.Center(child: pw.Container(
      width: 300, padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 2, color: PdfColors.blue900), borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text(school, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10), pw.Text('STUDENT ID CARD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Divider(), pw.Text('Name: ${student['name'] ?? ''}'),
        pw.Text('Father: ${student['father'] ?? ''}'), pw.Text('Roll: ${student['roll'] ?? ''}'),
        pw.Text('Class: ${student['class'] ?? ''}'), pw.Text('Phone: ${student['phone'] ?? ''}'),
      ]),
    ))));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student ID Card'), actions: [IconButton(onPressed: printCard, icon: const Icon(Icons.picture_as_pdf))]),
    body: Center(child: Card(child: Container(width: 330, padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.school, size: 42, color: blue), Text(school, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
      const Divider(height: 25), const CircleAvatar(radius: 35, child: Icon(Icons.person, size: 35)),
      const SizedBox(height: 12), Text('${student['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text('Father: ${student['father']}'), Text('Roll: ${student['roll']}'), Text('Class: ${student['class']}'), Text('Phone: ${student['phone']}'),
    ])))),
  );
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
