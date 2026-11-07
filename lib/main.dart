import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

void main() {
  runApp(const SchoolManagementApp());
}

const adminUsername = 'Muhammad Ilyas';
const adminPassword = '03135353153';

const blue = Color(0xFF123B70);

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCHOOL MANAGEMENT SYSTEM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xfff3f6fa),
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
    check();
  }

  Future<void> check() async {
    final p = await SharedPreferences.getInstance();

    final active = p.getBool('academy_license_active') ?? false;
    final username =
        p.getString('academy_customer_username') ?? '';

    if (!mounted) return;

    Widget page;

    if (!active) {
      page = const LicensePage();
    } else if (username.isEmpty) {
      page = const SetupPage();
    } else {
      page = const LoginPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LicensePage extends StatefulWidget {
  const LicensePage({super.key});

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final keyController = TextEditingController();

  String error = '';
  static int taps = 0;

  Future<void> activate() async {
    final p = await SharedPreferences.getInstance();

    final saved =
        p.getString('academy_generated_license') ?? '';

    if (keyController.text.trim().isEmpty ||
        keyController.text.trim() != saved) {
      setState(() {
        error = 'Invalid License Key';
      });
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
      appBar: AppBar(title: const Text('License Activation')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      taps++;
                      if (taps >= 5) {
                        taps = 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginPage(),
                          ),
                        );
                      }
                    },
                    child: const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.school, size: 45),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SCHOOL MANAGEMENT SYSTEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'Enter License Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: activate,
                      child: const Text('Activate License'),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 15),
                  const Text('License Support: 03161847676'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  Future<void> save() async {
    if (username.text.trim().isEmpty ||
        password.text.isEmpty) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create School Login')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Your School Account',
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              child: const Text('Save Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  String error = '';
  static int taps = 0;

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      taps++;
                      if (taps >= 5) {
                        taps = 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginPage(),
                          ),
                        );
                      }
                    },
                    child: const CircleAvatar(
                      radius: 45,
                      child: Icon(Icons.school, size: 48),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SCHOOL MANAGEMENT SYSTEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: blue,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      child: const Text('LOGIN'),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
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
              if (v != null) setState(() => duration = v);
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
            'Important: This is a local prototype. '
            'It does not yet provide secure activation on a separate phone, '
            'real device verification, or expiry enforcement.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
// ================= HOME DASHBOARD =================

const schoolClasses = [
  'First', 'Second', 'Third', 'Fourth', 'Fifth',
  'Sixth', 'Seventh', 'Eighth', 'Ninth', 'Tenth'
];

List<String> schoolSubjects(String c) {
  if (['First','Second','Third','Fourth','Fifth'].contains(c)) {
    return ['English','Urdu','Mathematics','General Knowledge','Islamiat'];
  }
  if (['Sixth','Seventh','Eighth'].contains(c)) {
    return ['English','Urdu','Mathematics','Science','Islamiat','Computer','Social Studies'];
  }
  return ['English','Urdu','Mathematics','Physics','Chemistry','Biology','Computer','Islamiat','Pakistan Studies'];
}

Future<List<Map<String,dynamic>>> readData(String key) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(key);
  if (raw == null) return [];
  try {
    return List<Map<String,dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String,dynamic>.from(e))
    );
  } catch (_) {
    return [];
  }
}

Future<void> writeData(String key, List<Map<String,dynamic>> data) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(key, jsonEncode(data));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  String school = 'My School';

  List<Map<String,dynamic>> students = [];
  List<Map<String,dynamic>> fees = [];
  List<Map<String,dynamic>> attendance = [];
  List<Map<String,dynamic>> marks = [];

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    final p = await SharedPreferences.getInstance();

    final name = p.getString('academy_name') ?? 'My School';
    final s = await readData('academy_students');
    final f = await readData('academy_fees');
    final a = await readData('academy_attendance');
    final m = await readData('academy_marks');

    if (!mounted) return;

    setState(() {
      school = name;
      students = s;
      fees = f;
      attendance = a;
      marks = m;
    });
  }

  Future<void> saveAll() async {
    await writeData('academy_students', students);
    await writeData('academy_fees', fees);
    await writeData('academy_attendance', attendance);
    await writeData('academy_marks', marks);
    await loadAll();
  }

  double get totalFees => fees.fold(
    0.0,
    (a, e) => a + (double.tryParse('${e['amount']}') ?? 0),
  );

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 29),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }

  Widget dashboard() {
    final today = DateTime.now().toString().substring(0, 10);
    final todayAttendance = attendance.where((a) => '${a['date']}' == today).toList();
    final present = todayAttendance.where((a) => '${a['status']}' == 'Present').length;
    final received = totalFees;
    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF082B59), Color(0xFF1764A5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.16), shape: BoxShape.circle),
                child: const Icon(Icons.school, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(school, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('School Management Dashboard', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(DateTime.now().toString().substring(0, 10), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.42,
            children: [
              statCard('Total Students', '${students.length}', Icons.people, const Color(0xFF1769D2)),
              statCard("Today's Attendance", '$present / ${todayAttendance.length}', Icons.calendar_month, const Color(0xFF159B58)),
              statCard('Fee Collected', 'Rs ${received.toStringAsFixed(0)}', Icons.payments, const Color(0xFF7435B8)),
              statCard('Exam Records', '${marks.length}', Icons.workspace_premium, const Color(0xFFE34B55)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: blue)),
          const SizedBox(height: 10),
          Wrap(spacing: 9, runSpacing: 9, children: [
            ActionChip(avatar: const Icon(Icons.person_add, color: Colors.white), backgroundColor: const Color(0xFF1769D2), label: const Text('Add Student', style: TextStyle(color: Colors.white)), onPressed: () => setState(() => selected = 1)),
            ActionChip(avatar: const Icon(Icons.payments, color: Colors.white), backgroundColor: const Color(0xFF159B58), label: const Text('Collect Fee', style: TextStyle(color: Colors.white)), onPressed: () => setState(() => selected = 2)),
            ActionChip(avatar: const Icon(Icons.fact_check, color: Colors.white), backgroundColor: const Color(0xFFE58B19), label: const Text('Attendance', style: TextStyle(color: Colors.white)), onPressed: () => setState(() => selected = 3)),
            ActionChip(avatar: const Icon(Icons.assessment, color: Colors.white), backgroundColor: const Color(0xFF7435B8), label: const Text('Reports', style: TextStyle(color: Colors.white)), onPressed: () => setState(() => selected = 5)),
          ]),
          const SizedBox(height: 20),
          const Text('Recent Fee Payments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: blue)),
          const SizedBox(height: 8),
          ...fees.reversed.take(5).map((f) => Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE5F5EC), child: Icon(Icons.payments, color: Color(0xFF159B58))),
              title: Text('${f['studentName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${f['date'] ?? ''}'),
              trailing: Text('Rs ${f['amount'] ?? 0}', style: const TextStyle(color: Color(0xFF159B58), fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(selected == 0
            ? school
            : ['Home','Students','Fees','Attendance','Exams','Reports'][selected]),
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(school,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  )),
              ),
            ),

            for (int i = 0; i < 6; i++)
              ListTile(
                leading: Icon([
                  Icons.home,
                  Icons.people,
                  Icons.payments,
                  Icons.fact_check,
                  Icons.school,
                  Icons.picture_as_pdf,
                ][i]),
                title: Text([
                  'Dashboard',
                  'Students',
                  'Fees',
                  'Attendance',
                  'Exams / DMC',
                  'Reports',
                ][i]),
                selected: selected == i,
                onTap: () {
                  setState(() => selected = i);
                  Navigator.pop(context);
                },
              ),

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

      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (v) {
          setState(() => selected = v);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(
            icon: Icon(Icons.payments), label: 'Fees'),
          NavigationDestination(
            icon: Icon(Icons.fact_check), label: 'Attendance'),
          NavigationDestination(
            icon: Icon(Icons.school), label: 'Exams'),
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf), label: 'Reports'),
        ],
      ),
    );
  }
}

// ================= STUDENTS MODULE =================

class StudentsModule extends StatelessWidget {
  final List<Map<String,dynamic>> students;
  final ValueChanged<List<Map<String,dynamic>>> onSave;

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
    final fee = TextEditingController();

    String cls = schoolClasses.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name,
                  decoration: const InputDecoration(labelText: 'Student Name')),
                const SizedBox(height: 8),
                TextField(controller: father,
                  decoration: const InputDecoration(labelText: 'Father Name')),
                const SizedBox(height: 8),
                TextField(controller: roll,
                  decoration: const InputDecoration(labelText: 'Roll Number')),
                const SizedBox(height: 8),
                TextField(controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 8),
                TextField(controller: fee,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monthly Fee')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: cls,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: schoolClasses.map((v) =>
                    DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => set(() => cls = v ?? cls),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      final newStudent = {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'name': name.text.trim(),
        'father': father.text.trim(),
        'roll': roll.text.trim(),
        'phone': phone.text.trim(),
        'class': cls,
        'totalFee': fee.text.trim(),
        'admissionDate': DateTime.now().toString().substring(0, 10),
      };

      onSave([...students, newStudent]);
    }

    name.dispose();
    father.dispose();
    roll.dispose();
    phone.dispose();
    fee.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        FilledButton.icon(
          onPressed: () => addStudent(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Student'),
        ),

        ...students.map((s) => Card(
          child: ListTile(
            onTap: () {
              final prefsFuture = SharedPreferences.getInstance();
              prefsFuture.then((prefs) {
                final schoolName = prefs.getString('academy_name') ?? 'My School';
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StudentIDCard(school: schoolName, student: s),
                ));
              });
            },
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('${s['name']}'),
            subtitle: Text(
              'Father: ${s['father']} • Roll: ${s['roll']} • ${s['class']}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') {
                  onSave(students.where(
                    (x) => x['id'] != s['id'],
                  ).toList());
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Student'),
                ),
              ],
            ),
          ),
        )),

        if (students.isEmpty)
          const Padding(
            padding: EdgeInsets.all(25),
            child: Center(child: Text('No Students Added')),
          ),
      ],
    );
  }
}

// ================= FEES MODULE =================

class FeesModule extends StatelessWidget {
  final List<Map<String,dynamic>> students;
  final List<Map<String,dynamic>> fees;
  final ValueChanged<List<Map<String,dynamic>>> onSave;

  const FeesModule({
    super.key,
    required this.students,
    required this.fees,
    required this.onSave,
  });

  Future<void> collect(BuildContext context) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add students first')),
      );
      return;
    }

    final amount = TextEditingController();
    final month = TextEditingController(
      text: DateTime.now().month.toString(),
    );

    String? selected = '${students.first['id']}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Collect Fee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                items: students.map((s) => DropdownMenuItem(
                  value: '${s['id']}',
                  child: Text('${s['name']}'),
                )).toList(),
                onChanged: (v) => set(() => selected = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Rs'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: month,
                decoration: const InputDecoration(labelText: 'Month'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && (double.tryParse(amount.text) ?? 0) > 0) {
      final s = students.firstWhere(
        (x) => '${x['id']}' == selected,
      );

      onSave([...fees, {
        'studentId': s['id'],
        'studentName': s['name'],
        'roll': s['roll'],
        'class': s['class'],
        'amount': amount.text,
        'month': month.text,
        'date': DateTime.now().toString().substring(0, 10),
      }]);
    }

    amount.dispose();
    month.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        FilledButton.icon(
          onPressed: () => collect(context),
          icon: const Icon(Icons.add),
          label: const Text('Collect Fee'),
        ),

        ...fees.reversed.map((f) => Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('${f['studentName']}'),
            subtitle: Text('${f['class']} • ${f['month']} • ${f['date']}'),
            trailing: Text('Rs ${f['amount']}'),
          ),
        )),
      ],
    );
  }
}

// ================= ATTENDANCE MODULE =================

class AttendanceModule extends StatelessWidget {
  final List<Map<String,dynamic>> students;
  final List<Map<String,dynamic>> records;
  final ValueChanged<List<Map<String,dynamic>>> onSave;

  const AttendanceModule({
    super.key,
    required this.students,
    required this.records,
    required this.onSave,
  });

  Future<void> mark(BuildContext context) async {
    if (students.isEmpty) return;

    final today = DateTime.now().toString().substring(0, 10);
    final result = <Map<String,dynamic>>[];

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Attendance $today'),
        content: SizedBox(
          width: 350,
          height: 400,
          child: ListView(
            children: students.map((s) {
              bool present = true;
              return StatefulBuilder(
                builder: (c, set) => CheckboxListTile(
                  value: present,
                  title: Text('${s['name']}'),
                  subtitle: Text('${s['class']} • ${s['roll']}'),
                  onChanged: (v) {
                    present = v ?? true;
                    set(() {});
                    result.removeWhere(
                      (x) => x['studentId'] == s['id'],
                    );
                    result.add({
                      'studentId': s['id'],
                      'studentName': s['name'],
                      'class': s['class'],
                      'date': today,
                      'status': present ? 'Present' : 'Absent',
                    });
                  },
                );
              },
            );
          }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result.isNotEmpty) {
      onSave([
        ...records.where((x) => x['date'] != today),
        ...result,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        FilledButton.icon(
          onPressed: () => mark(context),
          icon: const Icon(Icons.fact_check),
          label: const Text('Mark Today Attendance'),
        ),
        ...records.reversed.map((a) => Card(
          child: ListTile(
            title: Text('${a['studentName']}'),
            subtitle: Text('${a['class']} • ${a['date']}'),
            trailing: Text('${a['status']}'),
          ),
        )),
      ],
    );
  }
}

// ================= EXAMS MODULE =================

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
        const SnackBar(content: Text('Add students first')),
      );
      return;
    }
    String? studentId = '${students.first['id']}';
    final exam = TextEditingController(text: 'Monthly Test');
    final subject = TextEditingController();
    final total = TextEditingController(text: '100');
    final obtained = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Add Exam Marks'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: studentId,
                items: students.map((s) => DropdownMenuItem<String>(
                  value: '${s['id']}', child: Text('${s['name']}'),
                )).toList(),
                onChanged: (v) => set(() => studentId = v),
                decoration: const InputDecoration(labelText: 'Student'),
              ),
              TextField(controller: exam, decoration: const InputDecoration(labelText: 'Exam Name')),
              TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')),
              TextField(controller: total, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Marks')),
              TextField(controller: obtained, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Obtained Marks')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final totalValue = double.tryParse(total.text) ?? 0;
    final obtainedValue = double.tryParse(obtained.text) ?? 0;
    if (ok == true && studentId != null && subject.text.trim().isNotEmpty && totalValue > 0 && obtainedValue >= 0 && obtainedValue <= totalValue) {
      final student = students.firstWhere((s) => '${s['id']}' == studentId);
      onSave([...marks, {
        'studentId': studentId,
        'studentName': student['name'],
        'roll': student['roll'],
        'class': student['class'],
        'exam': exam.text.trim(),
        'subject': subject.text.trim(),
        'total': totalValue,
        'obtained': obtainedValue,
        'date': DateTime.now().toString().substring(0, 10),
      }]);
    }
    exam.dispose(); subject.dispose(); total.dispose(); obtained.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(onPressed: () => addMarks(context), icon: const Icon(Icons.add), label: const Text('Add Marks')),
      ...marks.reversed.map((m) => Card(child: ListTile(
        title: Text('${m['studentName']} - ${m['subject']}'),
        subtitle: Text('${m['exam']} • ${m['class']} • ${m['date']}'),
        trailing: Text('${m['obtained']}/${m['total']}'),
      ))),
      if (marks.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No exam records'))),
    ],
  );
}

// ================= REPORTS MODULE =================

class ReportsModule extends StatefulWidget {
  final String school;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> fees;
  final List<Map<String, dynamic>> marks;

  const ReportsModule({
    super.key,
    required this.school,
    required this.students,
    required this.fees,
    required this.marks,
  });

  @override
  State<ReportsModule> createState() => _ReportsModuleState();
}

class _ReportsModuleState extends State<ReportsModule> {
  String selectedClass = schoolClasses.first;

  Future<void> exportClassResult() async {
    final classStudents = widget.students.where((s) => '${s['class']}' == selectedClass).toList();
    if (classStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No students in this class')));
      return;
    }
    await printClassResultPdf(widget.school, selectedClass, classStudents, widget.marks);
  }

  @override
  Widget build(BuildContext context) {
    final received = widget.fees.fold<double>(0, (sum, f) => sum + (double.tryParse('${f['amount']}') ?? 0));
    return ListView(padding: const EdgeInsets.all(14), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF082B59), Color(0xFF1764A5)]),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.assessment, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(widget.school, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Reports & Result Centre', style: TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 12),
      Card(child: ListTile(leading: const Icon(Icons.people, color: blue), title: const Text('Total Students'), trailing: Text('${widget.students.length}'))),
      Card(child: ListTile(leading: const Icon(Icons.payments, color: Colors.green), title: const Text('Fees Received'), trailing: Text('Rs ${received.toStringAsFixed(0)}'))),
      Card(child: ListTile(leading: const Icon(Icons.school, color: Colors.deepPurple), title: const Text('Exam Entries'), trailing: Text('${widget.marks.length}'))),
      const SizedBox(height: 12),
      const Text('Class-wise Combined Result PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blue)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: selectedClass,
        decoration: const InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
        items: schoolClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) { if (v != null) setState(() => selectedClass = v); },
      ),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: exportClassResult, icon: const Icon(Icons.picture_as_pdf), label: const Text('Print / Save Whole Class Result PDF')),
      const SizedBox(height: 16),
      const Text('Individual Student Result PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blue)),
      const SizedBox(height: 6),
      ...widget.students.map((student) {
        final studentMarks = widget.marks.where((m) => '${m['studentId']}' == '${student['id']}').toList();
        return Card(
          child: ExpansionTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('${student['name'] ?? ''}'),
            subtitle: Text('Class ${student['class'] ?? ''} • Roll ${student['roll'] ?? ''}'),
            children: [
              if (studentMarks.isEmpty)
                const ListTile(title: Text('No result records for this student')),
              if (studentMarks.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Print Complete Student Result PDF'),
                  subtitle: Text('${studentMarks.length} subject/exam records'),
                  trailing: IconButton(
                    tooltip: 'Print individual result PDF',
                    icon: const Icon(Icons.print, color: blue),
                    onPressed: () => printIndividualResultPdf(widget.school, student, studentMarks),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('View Student ID Card'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentIDCard(school: widget.school, student: student))),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('View Fee Card'),
                onTap: () {
                  final studentFees = widget.fees.where((f) => '${f['studentId']}' == '${student['id']}').toList();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFeeCard(school: widget.school, student: student, fees: studentFees)));
                },
              ),
            ],
          ),
        );
      }),
    ]);
  }
}

// ================= RESULT PDF HELPERS =================

pw.Widget _pdfSchoolHeader(String school, String subtitle) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFF123B70),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Text(school, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontSize: 19, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 5),
      pw.Text(subtitle, style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
    ]),
  );
}

Future<void> printIndividualResultPdf(String school, Map<String, dynamic> student, List<Map<String, dynamic>> records) async {
  final doc = pw.Document();
  final total = records.fold<double>(0, (a, m) => a + (double.tryParse('${m['total']}') ?? 0));
  final obtained = records.fold<double>(0, (a, m) => a + (double.tryParse('${m['obtained']}') ?? 0));
  final percent = total == 0 ? 0.0 : obtained / total * 100;
  final grade = percent >= 80 ? 'A+' : percent >= 70 ? 'A' : percent >= 60 ? 'B' : percent >= 50 ? 'C' : percent >= 40 ? 'D' : 'Fail';
  doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
    _pdfSchoolHeader(school, 'INDIVIDUAL STUDENT RESULT / DMC'),
    pw.SizedBox(height: 18),
    pw.Text('Student: ${student['name'] ?? ''}'),
    pw.Text('Father Name: ${student['father'] ?? ''}'),
    pw.Text('Class: ${student['class'] ?? ''}    Roll No: ${student['roll'] ?? ''}'),
    pw.SizedBox(height: 16),
    pw.TableHelper.fromTextArray(
      headers: const ['Exam', 'Subject', 'Total', 'Obtained', '%'],
      data: records.map((m) {
        final t = double.tryParse('${m['total']}') ?? 0;
        final o = double.tryParse('${m['obtained']}') ?? 0;
        return ['${m['exam'] ?? ''}', '${m['subject'] ?? ''}', '$t', '$o', t == 0 ? '0' : '${(o / t * 100).toStringAsFixed(1)}%'];
      }).toList(),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: PdfColors.grey400),
    ),
    pw.SizedBox(height: 18),
    pw.Text('Grand Total: ${total.toStringAsFixed(0)}'),
    pw.Text('Obtained Marks: ${obtained.toStringAsFixed(0)}'),
    pw.Text('Percentage: ${percent.toStringAsFixed(2)}%'),
    pw.Text('Grade: $grade'),
    pw.Text('Result: ${percent >= 40 ? 'PASS' : 'FAIL'}'),
    pw.SizedBox(height: 45),
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Class Teacher Signature'), pw.Text('Principal Signature')]),
  ]));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

Future<void> printClassResultPdf(String school, String className, List<Map<String, dynamic>> students, List<Map<String, dynamic>> allMarks) async {
  final doc = pw.Document();
  final rows = <List<String>>[];
  for (final student in students) {
    final records = allMarks.where((m) => '${m['studentId']}' == '${student['id']}').toList();
    final total = records.fold<double>(0, (a, m) => a + (double.tryParse('${m['total']}') ?? 0));
    final obtained = records.fold<double>(0, (a, m) => a + (double.tryParse('${m['obtained']}') ?? 0));
    final percent = total == 0 ? 0.0 : obtained / total * 100;
    final grade = percent >= 80 ? 'A+' : percent >= 70 ? 'A' : percent >= 60 ? 'B' : percent >= 50 ? 'C' : percent >= 40 ? 'D' : 'Fail';
    rows.add(['${student['roll'] ?? ''}', '${student['name'] ?? ''}', total.toStringAsFixed(0), obtained.toStringAsFixed(0), '${percent.toStringAsFixed(1)}%', grade, percent >= 40 && total > 0 ? 'PASS' : 'FAIL']);
  }
  doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape, build: (_) => [
    _pdfSchoolHeader(school, 'CLASS $className — COMBINED RESULT'),
    pw.SizedBox(height: 14),
    pw.Text('Generated: ${DateTime.now().toString().substring(0, 10)}'),
    pw.SizedBox(height: 12),
    pw.TableHelper.fromTextArray(
      headers: const ['Roll No', 'Student Name', 'Total', 'Obtained', 'Percentage', 'Grade', 'Result'],
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: PdfColors.grey400),
    ),
    pw.SizedBox(height: 30),
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Class Teacher Signature'), pw.Text('Principal Signature')]),
  ]));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

Future<void> printStudentIdCardPdf(String school, Map<String, dynamic> student) async {
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (_) => pw.Center(
      child: pw.Container(
        width: 330,
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFF123B70), width: 2),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
          _pdfSchoolHeader(school, 'STUDENT ID CARD'),
          pw.SizedBox(height: 18),
          pw.Text('${student['name'] ?? ''}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Father Name: ${student['father'] ?? ''}'),
          pw.Text('Roll Number: ${student['roll'] ?? ''}'),
          pw.Text('Class: ${student['class'] ?? ''}'),
          pw.Text('Contact: ${student['phone'] ?? ''}'),
          pw.SizedBox(height: 35),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Student Signature'), pw.Text('Principal Signature')]),
        ]),
      ),
    ),
  ));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ================= STUDENT ID CARD =================

class StudentIDCard extends StatelessWidget {
  final String school;
  final Map<String, dynamic> student;

  const StudentIDCard({
    super.key,
    required this.school,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Card'),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        actions: [IconButton(tooltip: 'Print / Save ID PDF', icon: const Icon(Icons.picture_as_pdf), onPressed: () => printStudentIdCardPdf(school, student))],
      ),
      backgroundColor: const Color(0xffeef3fa),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: 370,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: blue.withOpacity(.16), blurRadius: 18, offset: const Offset(0, 8))],
              border: Border.all(color: const Color(0xffd5e1f0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xff082b59), Color(0xff1764a5)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                  ),
                  child: Column(children: [
                    const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.school, color: blue, size: 32)),
                    const SizedBox(height: 9),
                    Text(school.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text('STUDENT ID CARD', style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const CircleAvatar(radius: 48, backgroundColor: Color(0xffe7effa), child: Icon(Icons.person, size: 55, color: blue)),
                    const SizedBox(height: 12),
                    Text('${student['name'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: blue)),
                    const SizedBox(height: 14),
                    _idDetail('Father Name', student['father']),
                    _idDetail('Roll Number', student['roll']),
                    _idDetail('Class', student['class']),
                    _idDetail('Contact No.', student['phone']),
                    const SizedBox(height: 18),
                    const Divider(),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Student Signature', style: TextStyle(fontSize: 11)), Text('Principal Signature', style: TextStyle(fontSize: 11))]),
                    const SizedBox(height: 14),
                    const Text('Education Today  |  Bright Future Tomorrow', style: TextStyle(color: Colors.black54, fontSize: 10)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _idDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
        Expanded(child: Text('${value ?? ''}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

// ================= FEE CARD =================

class StudentFeeCard extends StatelessWidget {
  final String school;
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> fees;

  const StudentFeeCard({
    super.key,
    required this.school,
    required this.student,
    required this.fees,
  });

  @override
  Widget build(BuildContext context) {
    final records = fees.where(
      (f) => '${f['studentId']}' == '${student['id']}',
    ).toList();

    final received = records.fold<double>(
      0,
      (a, f) => a + (double.tryParse('${f['amount']}') ?? 0),
    );

    final monthly = double.tryParse(
      '${student['totalFee']}',
    ) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Fee Card')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 45, color: blue),
                  Text(
                    school,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 30),
                  Text('Student: ${student['name']}'),
                  Text('Father: ${student['father']}'),
                  Text('Roll: ${student['roll']}'),
                  Text('Class: ${student['class']}'),
                  const Divider(height: 30),
                  _feeRow('Monthly Fee', monthly),
                  _feeRow('Total Received', received),
                  _feeRow(
                    'Outstanding',
                    (monthly - received).clamp(0, double.infinity),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          ...records.map(
            (f) => Card(
              child: ListTile(
                title: Text('Month: ${f['month']}'),
                subtitle: Text('${f['date']}'),
                trailing: Text('Rs ${f['amount']}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ================= DMC RESULT CARD =================

class StudentDMC extends StatelessWidget {
  final String school;
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> marks;

  const StudentDMC({
    super.key,
    required this.school,
    required this.student,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    final records = marks.where(
      (m) => '${m['studentId']}' == '${student['id']}',
    ).toList();

    final total = records.fold<double>(
      0,
      (a, m) => a + (double.tryParse('${m['total']}') ?? 0),
    );

    final obtained = records.fold<double>(
      0,
      (a, m) => a + (double.tryParse('${m['obtained']}') ?? 0),
    );

    final percent = total == 0 ? 0.0 : obtained / total * 100;

    final grade = percent >= 80 ? 'A+' :
        percent >= 70 ? 'A' :
        percent >= 60 ? 'B' :
        percent >= 50 ? 'C' :
        percent >= 40 ? 'D' : 'Fail';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DMC / Result Card'),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        actions: [IconButton(tooltip: 'Print / Save PDF', icon: const Icon(Icons.picture_as_pdf), onPressed: () => printIndividualResultPdf(school, student, records))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 45, color: blue),
                  Text(
                    school,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 25),
                  const Text(
                    'DETAILED MARKS CERTIFICATE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text('Student: ${student['name']}'),
                  Text('Father: ${student['father']}'),
                  Text('Roll Number: ${student['roll']}'),
                  Text('Class: ${student['class']}'),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Row(
                    children: [
                      Expanded(child: Text('Subject')),
                      Text('Total'),
                      SizedBox(width: 15),
                      Text('Obtained'),
                    ],
                  ),
                  const Divider(),
                  ...records.map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(child: Text('${m['subject']}')),
                          Text('${m['total']}'),
                          const SizedBox(width: 15),
                          Text('${m['obtained']}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 25),
                  _resultRow('Total Marks', total),
                  _resultRow('Obtained Marks', obtained),
                  _resultRow('Percentage', percent, suffix: '%'),
                  _resultRow('Grade', grade.toString()),
                  _resultRow(
                    'Result',
                    percent >= 40 ? 'PASS' : 'FAIL',
                  ),
                  const SizedBox(height: 35),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Teacher Signature'),
                      Text('Principal Signature'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, dynamic value, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value$suffix',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ================= SCHOOL CERTIFICATES =================

class SchoolCertificate extends StatelessWidget {
  final String school;
  final Map<String, dynamic> student;
  final String certificateType;

  const SchoolCertificate({
    super.key,
    required this.school,
    required this.student,
    required this.certificateType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(certificateType)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Card(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 50, color: blue),
                  Text(
                    school,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: blue,
                    ),
                  ),
                  const Divider(height: 35),
                  Text(
                    certificateType.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'This is to certify that ${student['name']}, '
                    'son/daughter of ${student['father']}, '
                    'Roll Number ${student['roll']}, '
                    'Class ${student['class']}, '
                    'is/was a student of this school.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Teacher Signature'),
                      Text('Principal Signature'),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Date: ${DateTime.now().toString().substring(0, 10)}',
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
    
