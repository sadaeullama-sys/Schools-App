import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Map<String,dynamic>> transport = [];
  List<Map<String,dynamic>> salaries = [];
  List<Map<String,dynamic>> expenses = [];

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
    final t = await readData('academy_transport');
    final sal = await readData('academy_salaries');
    final ex = await readData('academy_expenses');

    if (!mounted) return;

    setState(() {
      school = name;
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

  double get totalFees => fees.fold(
    0.0,
    (a, e) => a + (double.tryParse('${e['amount']}') ?? 0),
  );

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            )),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xff0b2e59), Color(0xff2875b8)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: blue.withOpacity(.18), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Row(children: [
              const CircleAvatar(radius: 27, backgroundColor: Colors.white, child: Icon(Icons.school, color: blue, size: 30)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(school, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 3),
                const Text('School Management Dashboard', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              const Icon(Icons.notifications_none, color: Colors.white),
            ]),
          ),
          const SizedBox(height: 15),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              statCard('Total Students', '${students.length}',
                  Icons.people, Colors.blue),
              statCard('Fee Received',
                  'Rs ${totalFees.toStringAsFixed(0)}',
                  Icons.payments, Colors.green),
              statCard('Attendance Records', '${attendance.length}',
                  Icons.fact_check, Colors.orange),
              statCard('Exam Records', '${marks.length}',
                  Icons.school, Colors.purple),
            ],
          ),

          const SizedBox(height: 18),
          const Text('Quick Actions',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_add),
                label: const Text('Add Student'),
                onPressed: () => setState(() => selected = 1),
              ),
              ActionChip(
                avatar: const Icon(Icons.payments),
                label: const Text('Collect Fee'),
                onPressed: () => setState(() => selected = 2),
              ),
              ActionChip(
                avatar: const Icon(Icons.fact_check),
                label: const Text('Attendance'),
                onPressed: () => setState(() => selected = 3),
              ),
              ActionChip(
                avatar: const Icon(Icons.school),
                label: const Text('Add Marks'),
                onPressed: () => setState(() => selected = 4),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: blue,
                child: Icon(Icons.account_tree, color: Colors.white),
              ),
              title: const Text(
                'Organization Workflow',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'School hierarchy, departments and staff responsibilities',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => setState(() => selected = 9),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  const Text('School Hierarchy Preview', style: TextStyle(fontWeight: FontWeight.bold, color: blue)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(9)),
                    child: const Text('Owner / Director', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.arrow_downward, color: blue),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF245A91), borderRadius: BorderRadius.circular(9)),
                    child: const Text('Principal / Headmaster', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.arrow_downward, color: blue),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: const [
                      Chip(label: Text('Academic')),
                      Chip(label: Text('Administration')),
                      Chip(label: Text('Accounts')),
                      Chip(label: Text('HR / Staff')),
                      Chip(label: Text('Transport')),
                      Chip(label: Text('Facilities')),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => selected = 9),
                    icon: const Icon(Icons.account_tree),
                    label: const Text('Open Full Organization Chart'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text('Recent Fee Payments',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),

          ...fees.reversed.take(5).map((f) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.payments),
              ),
              title: Text('${f['studentName'] ?? ''}'),
              subtitle: Text('${f['date'] ?? ''}'),
              trailing: Text('Rs ${f['amount'] ?? 0}'),
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
      TransportModule(records: transport, onSave: (v) async { transport = v; await saveAll(); }),
      SalaryModule(records: salaries, onSave: (v) async { salaries = v; await saveAll(); }),
      SchoolExpensesModule(records: expenses, onSave: (v) async { expenses = v; await saveAll(); }),
      OrganizationChartPage(school: school),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(selected == 0
            ? school
            : ['Home','Students','Fees','Attendance','Exams','Reports','Transport','Staff Salary','School Expenses','Organization Workflow'][selected]),
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

            for (int i = 0; i < 10; i++)
              ListTile(
                leading: Icon([
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
                ][i]),
                title: Text([
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

      bottomNavigationBar: selected < 6 ? NavigationBar(
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
      ) : null,
    );
  }
}

// ================= TRANSPORT MODULE =================
class TransportModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const TransportModule({super.key, required this.records, required this.onSave});

  Future<void> addRecord(BuildContext context) async {
    final student = TextEditingController();
    final route = TextEditingController();
    final amount = TextEditingController();
    final month = TextEditingController(text: DateTime.now().toString().substring(0, 7));
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Transport Record'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: student, decoration: const InputDecoration(labelText: 'Student Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter student name' : null),
        TextFormField(controller: route, decoration: const InputDecoration(labelText: 'Route / Pickup Point')),
        TextFormField(controller: month, decoration: const InputDecoration(labelText: 'Month (YYYY-MM)')),
        TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Transport Fee (Rs)'), validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Enter valid amount' : null),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Save'))],
    ));
    if (ok == true) onSave([...records, {'student': student.text.trim(), 'route': route.text.trim(), 'month': month.text.trim(), 'amount': double.parse(amount.text), 'date': DateTime.now().toIso8601String()}]);
    student.dispose(); route.dispose(); amount.dispose(); month.dispose();
  }

  @override Widget build(BuildContext context) {
    final total = records.fold<double>(0, (a, r) => a + (double.tryParse('${r['amount']}') ?? 0));
    return Scaffold(floatingActionButton: FloatingActionButton.extended(onPressed: () => addRecord(context), icon: const Icon(Icons.add), label: const Text('Add Transport')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _financeSummary('Total Transport Fees', total),
        const SizedBox(height: 12),
        ...records.asMap().entries.map((e) => Card(child: ListTile(leading: const Icon(Icons.directions_bus, color: blue), title: Text('${e.value['student']}'), subtitle: Text('${e.value['route'] ?? ''} • ${e.value['month'] ?? ''}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('Rs ${e.value['amount']}'), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { final copy = [...records]..removeAt(e.key); onSave(copy); })])))),
        if (records.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No transport records yet'))),
      ]));
  }
}

// ================= STAFF SALARY MODULE =================
class SalaryModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const SalaryModule({super.key, required this.records, required this.onSave});

  Future<void> addSalary(BuildContext context) async {
    final name = TextEditingController(); final role = TextEditingController();
    final amount = TextEditingController(); final month = TextEditingController(text: DateTime.now().toString().substring(0, 7));
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add Staff Salary'), content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Employee Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null),
      TextFormField(controller: role, decoration: const InputDecoration(labelText: 'Designation')),
      TextFormField(controller: month, decoration: const InputDecoration(labelText: 'Salary Month (YYYY-MM)')),
      TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Salary Paid (Rs)'), validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Enter valid amount' : null),
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Save'))]));
    if (ok == true) onSave([...records, {'name': name.text.trim(), 'role': role.text.trim(), 'month': month.text.trim(), 'amount': double.parse(amount.text), 'date': DateTime.now().toIso8601String()}]);
    name.dispose(); role.dispose(); amount.dispose(); month.dispose();
  }

  @override Widget build(BuildContext context) {
    final total = records.fold<double>(0, (a, r) => a + (double.tryParse('${r['amount']}') ?? 0));
    return Scaffold(floatingActionButton: FloatingActionButton.extended(onPressed: () => addSalary(context), icon: const Icon(Icons.add), label: const Text('Add Salary')),
      body: ListView(padding: const EdgeInsets.all(16), children: [_financeSummary('Total Salary Paid', total), const SizedBox(height: 12),
        ...records.asMap().entries.map((e) => Card(child: ListTile(leading: const Icon(Icons.badge, color: blue), title: Text('${e.value['name']}'), subtitle: Text('${e.value['role'] ?? ''} • ${e.value['month'] ?? ''}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('Rs ${e.value['amount']}'), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { final copy = [...records]..removeAt(e.key); onSave(copy); })])))),
        if (records.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No salary records yet'))),
      ]));
  }
}

// ================= SCHOOL EXPENSES MODULE =================
class SchoolExpensesModule extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onSave;
  const SchoolExpensesModule({super.key, required this.records, required this.onSave});

  Future<void> addExpense(BuildContext context) async {
    final title = TextEditingController(); final category = TextEditingController(); final amount = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add School Expense'), content: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Expense Description'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null),
      TextFormField(controller: category, decoration: const InputDecoration(labelText: 'Category (Rent, Electricity, Stationery...)')),
      TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs)'), validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Enter valid amount' : null),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Save'))]));
    if (ok == true) onSave([...records, {'title': title.text.trim(), 'category': category.text.trim(), 'amount': double.parse(amount.text), 'date': DateTime.now().toIso8601String()}]);
    title.dispose(); category.dispose(); amount.dispose();
  }

  @override Widget build(BuildContext context) {
    final total = records.fold<double>(0, (a, r) => a + (double.tryParse('${r['amount']}') ?? 0));
    return Scaffold(floatingActionButton: FloatingActionButton.extended(onPressed: () => addExpense(context), icon: const Icon(Icons.add), label: const Text('Add Expense')),
      body: ListView(padding: const EdgeInsets.all(16), children: [_financeSummary('Total School Expenses', total), const SizedBox(height: 12),
        ...records.asMap().entries.map((e) => Card(child: ListTile(leading: const Icon(Icons.account_balance_wallet, color: blue), title: Text('${e.value['title']}'), subtitle: Text('${e.value['category'] ?? ''} • ${e.value['date'].toString().split('T').first}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('Rs ${e.value['amount']}'), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { final copy = [...records]..removeAt(e.key); onSave(copy); })])))),
        if (records.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No school expenses yet'))),
      ]));
  }
}

Widget _financeSummary(String title, double amount) => Card(color: const Color(0xffe8f0fb), child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.account_balance_wallet, color: blue, size: 32), const SizedBox(width: 14), Expanded(child: Text(title)), Text('Rs ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: blue))])));

// ================= STUDENTS MODULE =================

class StudentsModule extends StatelessWidget {
  final List<Map<String,dynamic>> students;
  final ValueChanged<List<Map<String,dynamic>>> onSave;
  const StudentsModule({super.key, required this.students, required this.onSave});

  Future<void> addStudent(BuildContext context) async {
    final name=TextEditingController(), father=TextEditingController(), roll=TextEditingController();
    final phone=TextEditingController(), fee=TextEditingController(), regFee=TextEditingController();
    final dob=TextEditingController(), address=TextEditingController(), guardian=TextEditingController();
    String cls=schoolClasses.first, gender='Male', photo='';
    final picker=ImagePicker();
    final ok=await showDialog<bool>(context:context, builder:(c)=>StatefulBuilder(builder:(c,set)=>AlertDialog(
      title:const Text('Professional Student Registration'),
      content:SizedBox(width:420, child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min, children:[
        GestureDetector(onTap:() async { final x=await picker.pickImage(source:ImageSource.gallery,imageQuality:75,maxWidth:900); if(x!=null)set(()=>photo=x.path); }, child:CircleAvatar(radius:42,backgroundColor:const Color(0xffe5edf8),backgroundImage:photo.isNotEmpty?FileImage(File(photo)):null,child:photo.isEmpty?const Icon(Icons.add_a_photo,size:30,color:blue):null)),
        const SizedBox(height:6),const Text('Tap to add student photo'),
        TextField(controller:name,decoration:const InputDecoration(labelText:'Student Full Name *')),
        TextField(controller:father,decoration:const InputDecoration(labelText:'Father Name *')),
        TextField(controller:roll,decoration:const InputDecoration(labelText:'Roll Number / Admission No.')),
        TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Parent Contact Number')),
        TextField(controller:guardian,decoration:const InputDecoration(labelText:'Guardian / Emergency Contact')),
        TextField(controller:dob,decoration:const InputDecoration(labelText:'Date of Birth')),
        TextField(controller:address,decoration:const InputDecoration(labelText:'Home Address')),
        DropdownButtonFormField<String>(value:cls,decoration:const InputDecoration(labelText:'Class'),items:schoolClasses.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>set(()=>cls=v??cls)),
        DropdownButtonFormField<String>(value:gender,decoration:const InputDecoration(labelText:'Gender'),items:const [DropdownMenuItem(value:'Male',child:Text('Male')),DropdownMenuItem(value:'Female',child:Text('Female'))],onChanged:(v)=>set(()=>gender=v??gender)),
        TextField(controller:fee,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Monthly Tuition Fee (Rs.)')),
        TextField(controller:regFee,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Registration / Admission Fee (Rs.)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Register Student'))],
    )));
    if(ok==true && name.text.trim().isNotEmpty){
      final id=DateTime.now().microsecondsSinceEpoch.toString();
      final student=<String,dynamic>{'id':id,'name':name.text.trim(),'father':father.text.trim(),'roll':roll.text.trim(),'phone':phone.text.trim(),'guardian':guardian.text.trim(),'dob':dob.text.trim(),'address':address.text.trim(),'gender':gender,'class':cls,'totalFee':fee.text.trim(),'registrationFee':regFee.text.trim(),'photoPath':photo,'admissionDate':DateTime.now().toString().substring(0,10)};
      onSave([...students,student]);
    }
    for(final t in [name,father,roll,phone,fee,regFee,dob,address,guardian]){t.dispose();}
  }

  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xff123b70),Color(0xff2873b9)]),borderRadius:BorderRadius.circular(18)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('STUDENT REGISTRATION',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.bold)),SizedBox(height:5),Text('Create complete student profile with photo and admission details',style:TextStyle(color:Colors.white70))]),
    const SizedBox(height:12),FilledButton.icon(onPressed:()=>addStudent(context),icon:const Icon(Icons.person_add_alt_1),label:const Text('New Student Registration')),
    ...students.map((s)=>Card(elevation:1,child:ListTile(contentPadding:const EdgeInsets.all(10),leading:CircleAvatar(radius:27,backgroundImage:(s['photoPath']??'').toString().isNotEmpty && File(s['photoPath']).existsSync()?FileImage(File(s['photoPath'])):null,child:(s['photoPath']??'').toString().isEmpty?const Icon(Icons.person):null),title:Text('${s['name']}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Class ${s['class']} • Roll ${s['roll']}\nFather: ${s['father']}'),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v){if(v=='delete')onSave(students.where((x)=>x['id']!=s['id']).toList()); if(v=='id')Navigator.push(context,MaterialPageRoute(builder:(_)=>StudentIDCard(school:'New Iqra Children Academy',student:s)));},itemBuilder:(_)=>const [PopupMenuItem(value:'id',child:Text('View / Print ID Card')),PopupMenuItem(value:'delete',child:Text('Delete Student'))])))),
    if(students.isEmpty)const Padding(padding:EdgeInsets.all(28),child:Center(child:Text('No students registered yet'))),
  ]);
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

    final today = DateTime.now().toString().substring(0, 10);
    final statusById = <String, bool>{};
    for (final student in students) {
      statusById[student['id'].toString()] = true;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Attendance $today'),
              content: SizedBox(
                width: 350,
                height: 400,
                child: ListView(
                  children: students.map((student) {
                    final id = student['id'].toString();
                    return CheckboxListTile(
                      value: statusById[id] ?? true,
                      title: Text('${student['name']}'),
                      subtitle: Text(
                        '${student['class']} • ${student['roll']}',
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          statusById[id] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final todayRecords = students.map((student) {
        final id = student['id'].toString();
        return <String, dynamic>{
          'studentId': student['id'],
          'studentName': student['name'],
          'class': student['class'],
          'date': today,
          'status': (statusById[id] ?? true) ? 'Present' : 'Absent',
        };
      }).toList();

      onSave([
        ...records.where((record) => record['date'] != today),
        ...todayRecords,
      ]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved')),
        );
      }
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
        ...records.reversed.map((record) => Card(
              child: ListTile(
                leading: Icon(
                  record['status'] == 'Present'
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: record['status'] == 'Present'
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text('${record['studentName']}'),
                subtitle: Text(
                  '${record['class']} • ${record['date']}',
                ),
                trailing: Text('${record['status']}'),
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

class ReportsModule extends StatelessWidget {
 final String school; final List<Map<String,dynamic>> students,fees,marks;
 const ReportsModule({super.key,required this.school,required this.students,required this.fees,required this.marks});
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
  Text(school,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:blue)),const SizedBox(height:6),const Text('Professional print-ready school documents and PDF reports.'),const SizedBox(height:14),
  _reportTile(context,'Individual Student Result PDF','Select a student and print their DMC',Icons.person_search,() async {if(students.isEmpty)return; final id=await showDialog<String>(context:context,builder:(c)=>SimpleDialog(title:const Text('Select Student'),children:students.map((s)=>SimpleDialogOption(onPressed:()=>Navigator.pop(c,'${s['id']}'),child:Text('${s['name']} • ${s['class']}'))).toList())); if(id==null)return; final st=students.firstWhere((s)=>'${s['id']}'==id); final rec=marks.where((m)=>'${m['studentId']}'==id).toList(); await printDmcPdf(school,st,rec);}),
  _reportTile(context,'Class Combined Result PDF','One PDF containing the selected class results',Icons.groups,() async {final cls=await showDialog<String>(context:context,builder:(c)=>SimpleDialog(title:const Text('Select Class'),children:schoolClasses.map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(c,x),child:Text(x))).toList())); if(cls!=null)await printClassResultPdf(school,cls,students,marks);}),
  _reportTile(context,'Student ID Card PDF','Print one student card separately',Icons.badge,() async {if(students.isEmpty)return;final st=await _pickStudent(context,students);if(st!=null)await printIdPdf(school,st);}),
  _reportTile(context,'Student Fee Card PDF','Print student fee history and balance',Icons.receipt_long,() async {if(students.isEmpty)return;final st=await _pickStudent(context,students);if(st!=null)await printFeePdf(school,st,fees.where((f)=>'${f['studentId']}'=='${st['id']}').toList());}),
  _reportTile(context,'School Certificate PDF','Print an individual leaving / character certificate',Icons.workspace_premium,() async {if(students.isEmpty)return;final st=await _pickStudent(context,students);if(st!=null)await printCertificatePdf(school,st,'School Leaving Certificate');}),
  _reportTile(context,'Student Registration Record','Review registered student details',Icons.assignment_ind,() {showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Registered Students'),content:Text('Total registered students: ${students.length}'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close'))]));}),
  _reportTile(context,'Student Registration Form PDF','Print the admission form for an individual student',Icons.app_registration,() async {if(students.isEmpty)return;final st=await _pickStudent(context,students);if(st!=null)await printRegistrationPdf(school,st);}),
 ]);
 Widget _reportTile(BuildContext c,String title,String sub,IconData icon,VoidCallback tap)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:const Color(0xffe7effa),child:Icon(icon,color:blue)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(sub),trailing:const Icon(Icons.picture_as_pdf,color:Colors.red),onTap:tap));
}
Future<Map<String,dynamic>?> _pickStudent(BuildContext context,List<Map<String,dynamic>> students)=>showDialog<Map<String,dynamic>>(context:context,builder:(c)=>SimpleDialog(title:const Text('Select Student'),children:students.map((s)=>SimpleDialogOption(onPressed:()=>Navigator.pop(c,s),child:Text('${s['name']} • ${s['class']}'))).toList()));

// ================= STUDENT ID CARD =================

class StudentIDCard extends StatelessWidget {
 final String school; final Map<String,dynamic> student;
 const StudentIDCard({super.key,required this.school,required this.student});
 @override Widget build(BuildContext context){final path='${student['photoPath']??''}';return Scaffold(appBar:AppBar(title:const Text('Student ID Card'),actions:[IconButton(tooltip:'Print / Save PDF',icon:const Icon(Icons.picture_as_pdf),onPressed:()=>printIdPdf(school,student))]),body:Center(child:SingleChildScrollView(child:Container(width:350,margin:const EdgeInsets.all(18),padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xff0c2d55),Color(0xff1766a7)]),borderRadius:BorderRadius.circular(20),boxShadow:[BoxShadow(color:Colors.black26,blurRadius:12,offset:Offset(0,6))]),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.school,color:Colors.white,size:38),Text(school,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.bold)),const Text('STUDENT IDENTITY CARD',style:TextStyle(color:Colors.white70,letterSpacing:1)),const Divider(color:Colors.white54,height:25),CircleAvatar(radius:43,backgroundImage:path.isNotEmpty&&File(path).existsSync()?FileImage(File(path)):null,child:path.isEmpty?const Icon(Icons.person,size:42):null),const SizedBox(height:10),Text('${student['name']}',style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),_whiteLine('Father','${student['father']}'),_whiteLine('Roll No','${student['roll']}'),_whiteLine('Class','${student['class']}'),_whiteLine('Phone','${student['phone']}'),_whiteLine('Admission','${student['admissionDate']}'),const SizedBox(height:18),const Text('Authorized School Card',style:TextStyle(color:Colors.white70))])))));}
}
Widget _whiteLine(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[SizedBox(width:95,child:Text('$a:',style:const TextStyle(color:Colors.white70))),Expanded(child:Text(b,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)))]));

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
      appBar: AppBar(title: const Text('Student Fee Card'), actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Print / Save PDF', onPressed: () => printFeePdf(school, student, records))]),
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
      appBar: AppBar(title: const Text('Detailed Marks Certificate'), actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Print / Save PDF', onPressed: () => printDmcPdf(school, student, records))]),
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
      appBar: AppBar(title: Text(certificateType), actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Print / Save PDF', onPressed: () => printCertificatePdf(school, student, certificateType))]),
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

// ================= PROFESSIONAL PDF DOCUMENTS =================
pw.Widget _pdfHeader(String school,String heading)=>pw.Column(children:[pw.Text(school,style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold,color:PdfColor.fromInt(0xff123b70))),pw.SizedBox(height:4),pw.Text(heading,style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.Divider(color:PdfColor.fromInt(0xff123b70)),pw.SizedBox(height:10)]);
Future<void> _printPdf(pw.Document doc)=>Printing.layoutPdf(onLayout:(format)async=>doc.save());
Future<void> printIdPdf(String school,Map<String,dynamic> s)async{final d=pw.Document();d.addPage(pw.Page(pageFormat:PdfPageFormat.a4,build:(c)=>pw.Center(child:pw.Container(width:300,padding:const pw.EdgeInsets.all(22),decoration:pw.BoxDecoration(border:pw.Border.all(color:PdfColor.fromInt(0xff123b70),width:2),borderRadius:pw.BorderRadius.circular(12)),child:pw.Column(mainAxisSize:pw.MainAxisSize.min,children:[_pdfHeader(school,'STUDENT ID CARD'),pw.Text('${s['name']}',style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:10),...['Father: ${s['father']}','Roll No: ${s['roll']}','Class: ${s['class']}','Phone: ${s['phone']}','Admission: ${s['admissionDate']}'].map((x)=>pw.Padding(padding:const pw.EdgeInsets.all(5),child:pw.Align(alignment:pw.Alignment.centerLeft,child:pw.Text(x)))),pw.SizedBox(height:20),pw.Text('Principal Signature: __________________')]))));await _printPdf(d);}
Future<void> printDmcPdf(String school,Map<String,dynamic> s,List<Map<String,dynamic>> records)async{final d=pw.Document();final total=records.fold<double>(0,(a,m)=>a+(double.tryParse('${m['total']}')??0));final got=records.fold<double>(0,(a,m)=>a+(double.tryParse('${m['obtained']}')??0));final pct=total==0?0:got/total*100;d.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(c)=>[_pdfHeader(school,'DETAILED MARKS CERTIFICATE'),pw.Text('Student: ${s['name']}     Father: ${s['father']}'),pw.Text('Class: ${s['class']}     Roll No: ${s['roll']}'),pw.SizedBox(height:16),pw.Table.fromTextArray(headers:['Subject','Total','Obtained'],data:records.map((m)=>['${m['subject']??m['exam']??''}','${m['total']??0}','${m['obtained']??0}']).toList(),headerDecoration:pw.BoxDecoration(color:PdfColor.fromInt(0xffdce8f5))),pw.SizedBox(height:18),pw.Text('Total Marks: ${total.toStringAsFixed(0)}'),pw.Text('Obtained Marks: ${got.toStringAsFixed(0)}'),pw.Text('Percentage: ${pct.toStringAsFixed(2)}%'),pw.Text('Result: ${pct>=40?'PASS':'FAIL'}'),pw.SizedBox(height:45),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('Class Teacher: ______________'),pw.Text('Principal: ______________')]) ]));await _printPdf(d);}
Future<void> printClassResultPdf(String school,String cls,List<Map<String,dynamic>> students,List<Map<String,dynamic>> marks)async{final rows=<List<String>>[];for(final s in students.where((x)=>'${x['class']}'==cls)){final rec=marks.where((m)=>'${m['studentId']}'=='${s['id']}').toList();final total=rec.fold<double>(0,(a,m)=>a+(double.tryParse('${m['total']}')??0));final got=rec.fold<double>(0,(a,m)=>a+(double.tryParse('${m['obtained']}')??0));final pct=total==0?0:got/total*100;rows.add(['${s['roll']}','${s['name']}','${got.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}','${pct.toStringAsFixed(1)}%','${pct>=40?'PASS':'FAIL'}']);}final d=pw.Document();d.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(c)=>[_pdfHeader(school,'CLASS $cls — COMBINED RESULT'),pw.Table.fromTextArray(headers:['Roll','Student Name','Obtained / Total','%','Result'],data:rows,headerDecoration:pw.BoxDecoration(color:PdfColor.fromInt(0xffdce8f5))),pw.SizedBox(height:30),pw.Text('Prepared on: ${DateTime.now().toString().substring(0,10)}')]));await _printPdf(d);}
Future<void> printFeePdf(String school,Map<String,dynamic> s,List<Map<String,dynamic>> fees)async{final received=fees.fold<double>(0,(a,f)=>a+(double.tryParse('${f['amount']}')??0));final monthly=double.tryParse('${s['totalFee']}')??0;final d=pw.Document();d.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(c)=>[_pdfHeader(school,'STUDENT FEE CARD'),pw.Text('Student: ${s['name']}     Father: ${s['father']}'),pw.Text('Class: ${s['class']}     Roll: ${s['roll']}'),pw.Text('Monthly Fee: Rs ${monthly.toStringAsFixed(0)}'),pw.SizedBox(height:15),pw.Table.fromTextArray(headers:['Date','Month','Received (Rs.)'],data:fees.map((f)=>['${f['date']}','${f['month']}','${f['amount']}']).toList()),pw.SizedBox(height:15),pw.Text('Total Received: Rs ${received.toStringAsFixed(0)}',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),pw.Text('Registration Fee: Rs ${s['registrationFee']??0}')]));await _printPdf(d);}
Future<void> printCertificatePdf(String school,Map<String,dynamic> s,String type)async{final d=pw.Document();d.addPage(pw.Page(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(45),build:(c)=>pw.Container(padding:const pw.EdgeInsets.all(28),decoration:pw.BoxDecoration(border:pw.Border.all(color:PdfColor.fromInt(0xffb68b28),width:3)),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.center,children:[_pdfHeader(school,type.toUpperCase()),pw.SizedBox(height:35),pw.Text('This is to certify that',style:const pw.TextStyle(fontSize:15)),pw.SizedBox(height:12),pw.Text('${s['name']}',style:pw.TextStyle(fontSize:24,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:12),pw.Text('Son/Daughter of ${s['father']}'),pw.SizedBox(height:14),pw.Text('Roll No: ${s['roll']}     Class: ${s['class']}'),pw.SizedBox(height:20),pw.Text('has been a student of $school.',textAlign:pw.TextAlign.center),pw.Spacer(),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('Date: ${DateTime.now().toString().substring(0,10)}'),pw.Text('Principal Signature: __________')])]))));await _printPdf(d);}

Future<void> printRegistrationPdf(String school,Map<String,dynamic> s)async{final d=pw.Document();d.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(c)=>[_pdfHeader(school,'STUDENT ADMISSION / REGISTRATION FORM'),pw.Text('Admission No: ${s['roll']??''}'),pw.Text('Admission Date: ${s['admissionDate']??''}'),pw.SizedBox(height:12),pw.Table.fromTextArray(headers:['Particular','Student Information'],data:[['Student Name','${s['name']??''}'],['Father Name','${s['father']??''}'],['Guardian Contact','${s['guardian']??''}'],['Phone','${s['phone']??''}'],['Date of Birth','${s['dob']??''}'],['Gender','${s['gender']??''}'],['Class','${s['class']??''}'],['Address','${s['address']??''}'],['Monthly Tuition Fee','Rs ${s['totalFee']??0}'],['Registration Fee','Rs ${s['registrationFee']??0}']]),pw.SizedBox(height:35),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('Parent Signature: ______________'),pw.Text('Admission Officer: ______________')]) ]));await _printPdf(d);}

// ================= ORGANIZATION WORKFLOW =================
// This is an organization chart only. Employee logins are intentionally disabled.
class OrganizationChartPage extends StatelessWidget {
  final String school;
  const OrganizationChartPage({super.key, required this.school});

  Widget _role(String title, String subtitle, {Color color = blue, IconData icon = Icons.person}) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector() => Container(width: 2, height: 22, color: Colors.blueGrey.shade300);

  Widget _department(String title, String description, IconData icon, Color color, List<String> roles) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.13), child: Icon(icon, color: color)),
              const SizedBox(width: 9),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ]),
            const SizedBox(height: 5),
            Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const Divider(height: 18),
            ...roles.map((role) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Icon(Icons.subdirectory_arrow_right, size: 16, color: color),
                const SizedBox(width: 5),
                Expanded(child: Text(role, style: const TextStyle(fontSize: 13))),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(school, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: blue)),
        const SizedBox(height: 5),
        const Text('ORGANIZATION & STAFF WORKFLOW', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 18),
        Center(child: _role('Owner / Director', 'Overall control • Final approval', color: const Color(0xFF102E56), icon: Icons.workspace_premium)),
        Center(child: _connector()),
        Center(child: _role('Principal / Headmaster', 'Daily school operations • Academic supervision', color: const Color(0xFF174A80), icon: Icons.school)),
        Center(child: _connector()),
        const Text('DEPARTMENTS', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: blue, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        _department('Academic Department', 'Teaching, classes and student progress', Icons.menu_book, Colors.blue, [
          'Academic Coordinator', 'Class Incharges', 'Subject Teachers', 'Examination Coordinator',
        ]),
        _department('Administration Department', 'Admissions, records and office management', Icons.admin_panel_settings, Colors.indigo, [
          'Admin Officer', 'Admission / Record Clerk', 'Receptionist', 'Office Assistant',
        ]),
        _department('Accounts Department', 'Fee collection, payroll and financial records', Icons.account_balance_wallet, Colors.green, [
          'Accountant', 'Fee Clerk / Cashier', 'Salary & Expense Record Keeper',
        ]),
        _department('Human Resources', 'Staff records, attendance and salary details', Icons.groups, Colors.deepPurple, [
          'HR / Staff Incharge', 'Staff Attendance Clerk', 'Staff Salary Coordinator',
        ]),
        _department('Transport Department', 'Routes, vehicles and student transport', Icons.directions_bus, Colors.orange, [
          'Transport Incharge', 'Drivers', 'Conductors / Helpers',
        ]),
        _department('Facilities & Support', 'Campus cleanliness, safety and maintenance', Icons.handyman, Colors.teal, [
          'Maintenance Staff', 'Security Guards', 'Cleaners / Support Staff',
        ]),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFEAF1FA),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: blue),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Employee login is disabled as requested. This chart shows reporting lines and responsibilities only. The Owner/Admin continues to manage all records from the main login.',
                  style: TextStyle(color: Color(0xFF173B65), height: 1.4),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

