import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademyApp());
}

const String adminUsername = 'Muhammad Ilyas';
// Admin password is checked internally; do not display it in the app.

const List<String> academyClasses = [
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

List<String> subjectsForClass(String className) {
  final junior = [
    'English',
    'Urdu',
    'Mathematics',
    'General Knowledge',
    'Islamiat',
  ];

  final middle = [
    'English',
    'Urdu',
    'Mathematics',
    'Science',
    'Islamiat',
    'Computer',
    'Social Studies',
  ];

  final matric = [
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

  if (['First', 'Second', 'Third', 'Fourth', 'Fifth']
      .contains(className)) {
    return junior;
  }

  if (['Sixth', 'Seventh', 'Eighth'].contains(className)) {
    return middle;
  }

  return matric;
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New Iqra Children Academy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123B70),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F6FA),
      ),
      home: const StartupPage(),
    );
  }
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool loading = true;
  bool activated = false;
  bool customerLoginExists = false;

  @override
  void initState() {
    super.initState();
    checkApp();
  }

  Future<void> checkApp() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      activated = prefs.getBool('academy_license_active') ?? false;
      customerLoginExists =
          (prefs.getString('academy_customer_username') ?? '').isNotEmpty;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!activated) return const LicensePage();

    if (customerLoginExists) return const CustomerLoginPage();

    return const CustomerLoginSetupPage();
  }
}
class LicensePage extends StatefulWidget {
  const LicensePage({super.key});

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final keyController = TextEditingController();
  bool busy = false;
  String message = '';

  Future<void> activate() async {
    final key = keyController.text.trim();

    if (key.isEmpty) {
      setState(() => message = 'Please enter License Key');
      return;
    }

    setState(() => busy = true);

    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('academy_generated_license') ?? '';

    if (key == savedKey && key.isNotEmpty) {
      final school = prefs.getString('academy_license_school') ?? '';

      await prefs.setBool('academy_license_active', true);
      await prefs.setString('academy_name', school);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerLoginSetupPage(),
        ),
      );
    } else {
      setState(() {
        message = 'Invalid License Key';
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Activation')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 65, color: Colors.blue),
                  const SizedBox(height: 15),
                  const Text(
                    'New Iqra Children Academy',
                    style: TextStyle(
                      fontSize: 21,
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
                      onPressed: busy ? null : activate,
                      child: Text(busy ? 'Checking...' : 'Activate License'),
                    ),
                  ),
                  if (message.isNotEmpty)
                    Text(message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
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

class CustomerLoginSetupPage extends StatefulWidget {
  const CustomerLoginSetupPage({super.key});

  @override
  State<CustomerLoginSetupPage> createState() =>
      _CustomerLoginSetupPageState();
}

class _CustomerLoginSetupPageState extends State<CustomerLoginSetupPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  Future<void> saveLogin() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'academy_customer_username',
      username.text.trim(),
    );
    await prefs.setString('academy_customer_password', password.text);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
    );
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              onPressed: saveLogin,
              child: const Text('Save Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  String error = '';

  Future<void> login() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUser = prefs.getString('academy_customer_username') ?? '';
    final savedPass = prefs.getString('academy_customer_password') ?? '';

    if (username.text.trim() == savedUser &&
        password.text == savedPass) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => error = 'Incorrect username or password');
    }
  }

  void openAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Five taps open the hidden Admin Login.
                  _tapCount++;
                  if (_tapCount >= 5) {
                    _tapCount = 0;
                    openAdmin();
                  }
                },
                child: const CircleAvatar(
                  radius: 45,
                  child: Icon(Icons.school, size: 48),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New Iqra Children Academy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              ElevatedButton(
                onPressed: login,
                child: const Text('Login'),
              ),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  static int _tapCount = 0;
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
        password.text == '03135353153') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong Admin Username or Password')),
      );
    }
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
            const Icon(Icons.admin_panel_settings, size: 65),
            const SizedBox(height: 20),
            TextField(
              controller: username,
              decoration: const InputDecoration(
                labelText: 'Admin Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: login,
                child: const Text('Admin Login'),
              ),
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
  final schoolController = TextEditingController();
  String duration = '1 Month';
  String generatedKey = '';

  Future<void> generateLicense() async {
    final school = schoolController.text.trim();

    if (school.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter School Name')),
      );
      return;
    }

    final random = Random.secure();
    final code = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16).toUpperCase(),
    ).join();

    final key = 'IQRA-$code';

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('academy_generated_license', key);
    await prefs.setString('academy_license_school', school);
    await prefs.setString('academy_license_duration', duration);
    await prefs.setString('academy_license_device', 'LOCAL');

    setState(() {
      generatedKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin License Generator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified_user, size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          TextField(
            controller: schoolController,
            decoration: const InputDecoration(
              labelText: 'School Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: duration,
            decoration: const InputDecoration(
              labelText: 'License Duration',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1 Month', child: Text('1 Month')),
              DropdownMenuItem(value: '3 Months', child: Text('3 Months')),
              DropdownMenuItem(value: '1 Year', child: Text('1 Year')),
              DropdownMenuItem(value: 'Lifetime', child: Text('Lifetime')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => duration = value);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: generateLicense,
            icon: const Icon(Icons.key),
            label: const Text('Generate License Key'),
          ),
          if (generatedKey.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Generated License Key',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(
              generatedKey,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Copy is added in a later part.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Select and copy the key above'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Key'),
            ),
          ],
        ],
      ),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;
  String selectedClass = 'First';
  String academyName = 'New Iqra Children Academy';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> readList(String key) {
      final raw = prefs.getString(key);
      if (raw == null) return [];
      try {
        return List<Map<String, dynamic>>.from(
          jsonDecode(raw).map((e) => Map<String, dynamic>.from(e)),
        );
      } catch (_) {
        return [];
      }
    }

    setState(() {
      academyName =
          prefs.getString('academy_name') ?? 'New Iqra Children Academy';
      students = readList('academy_students');
      fees = readList('academy_fees');
      attendance = readList('academy_attendance');
      marks = readList('academy_marks');
    });
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  int get classStudents =>
      students.where((s) => s['class'] == selectedClass).length;

  double get totalFees => fees.fold(
        0,
        (sum, f) => sum + (double.tryParse('${f['amount']}') ?? 0),
      );

  Widget dashboard() {
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            academyName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              dashboardCard('Total Students', '${students.length}',
                  Icons.people, Colors.blue),
              dashboardCard('Fee Received', 'Rs. ${totalFees.toStringAsFixed(0)}',
                  Icons.payments, Colors.green),
              dashboardCard('Attendance Records', '${attendance.length}',
                  Icons.fact_check, Colors.orange),
              dashboardCard('Exam Records', '${marks.length}',
                  Icons.menu_book, Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              quickButton('Add Student', Icons.person_add, 1),
              quickButton('Students', Icons.people, 1),
              quickButton('Fees', Icons.payments, 2),
              quickButton('Attendance', Icons.fact_check, 3),
              quickButton('Exams & Marks', Icons.school, 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget dashboardCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget quickButton(String label, IconData icon, int page) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => setState(() => selectedPage = page),
    );
  }

  Widget studentsPage() {
    final filtered = students
        .where((s) => s['class'] == selectedClass)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Class Wise Students',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(
            labelText: 'Select Class',
            border: OutlineInputBorder(),
          ),
          items: academyClasses
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => selectedClass = value);
          },
        ),
        const SizedBox(height: 12),
        Text('Total Students: $classStudents'),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: addStudent,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Student'),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const Center(child: Text('No students in this class yet')),
        ...filtered.map((student) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${student['name'] ?? ''}'),
              subtitle: Text(
                'Father: ${student['father'] ?? ''}\n'
                'Roll No: ${student['roll'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteStudent(student),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> addStudent() async {
    final name = TextEditingController();
    final father = TextEditingController();
    final roll = TextEditingController();
    final phone = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Student - $selectedClass'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: father,
                decoration: const InputDecoration(labelText: 'Father Name'),
              ),
              TextField(
                controller: roll,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;

              final student = <String, dynamic>{
                'id': DateTime.now().microsecondsSinceEpoch.toString(),
                'name': name.text.trim(),
                'father': father.text.trim(),
                'roll': roll.text.trim(),
                'class': selectedClass,
                'phone': phone.text.trim(),
                'address': '',
                'dob': '',
                'admissionDate': DateTime.now().toString(),
                'totalFee': '0',
                'photo': '',
              };

              setState(() => students.add(student));
              await saveList('academy_students', students);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save Student'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteStudent(Map<String, dynamic> student) async {
    setState(() => students.remove(student));
    await saveList('academy_students', students);
  }
  Widget feesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Fee Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Total Received: Rs. ${totalFees.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: addFee,
          icon: const Icon(Icons.add),
          label: const Text('Collect Fee'),
        ),
        ...fees.map((f) => Card(
              child: ListTile(
                title: Text('${f['studentName'] ?? ''}'),
                subtitle: Text(
                  '${f['class'] ?? ''} | ${f['month'] ?? ''}',
                ),
                trailing: Text('Rs. ${f['amount'] ?? 0}'),
              ),
            )),
      ],
    );
  }

  Future<void> addFee() async {
    final amount = TextEditingController();
    final month = TextEditingController();
    String? studentId;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a student first')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateDialog) => AlertDialog(
          title: const Text('Collect Fee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: studentId,
                decoration: const InputDecoration(labelText: 'Student'),
                items: students.map((s) {
                  return DropdownMenuItem<String>(
                    value: '${s['id']}',
                    child: Text('${s['name']}'),
                  );
                }).toList(),
                onChanged: (v) => updateDialog(() => studentId = v),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Rs.'),
              ),
              TextField(
                controller: month,
                decoration: const InputDecoration(labelText: 'Month'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final student = students.firstWhere(
                  (s) => '${s['id']}' == studentId,
                  orElse: () => {},
                );
                final value = double.tryParse(amount.text);

                if (student.isEmpty || value == null || value <= 0) return;

                final record = <String, dynamic>{
                  'studentId': student['id'],
                  'studentName': student['name'],
                  'roll': student['roll'],
                  'class': student['class'],
                  'amount': value,
                  'month': month.text.trim(),
                  'date': DateTime.now().toString(),
                  'note': '',
                };

                setState(() => fees.add(record));
                await saveList('academy_fees', fees);

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Fee'),
            ),
          ],
        ),
      ),
    );
  }

  Widget attendancePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(labelText: 'Select Class'),
          items: academyClasses
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedClass = v);
          },
        ),
        const SizedBox(height: 12),
        ...students.where((s) => s['class'] == selectedClass).map((s) {
          return Card(
            child: ListTile(
              title: Text('${s['name']}'),
              subtitle: Text('Roll: ${s['roll'] ?? ''}'),
              trailing: ElevatedButton(
                onPressed: () async {
                  attendance.add({
                    'studentId': s['id'],
                    'studentName': s['name'],
                    'class': s['class'],
                    'date': DateTime.now().toString(),
                    'status': 'Present',
                  });
                  await saveList('academy_attendance', attendance);
                  if (mounted) setState(() {});
                },
                child: const Text('Present'),
              ),
            ),
          );
        }),
        Text('Attendance Records: ${attendance.length}'),
      ],
    );
  }

  Widget marksPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Exams & Marks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(labelText: 'Select Class'),
          items: academyClasses
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedClass = v);
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: addMarks,
          icon: const Icon(Icons.add),
          label: const Text('Add Exam Marks'),
        ),
        ...marks.where((m) => m['class'] == selectedClass).map((m) {
          final total = double.tryParse('${m['total']}') ?? 0;
          final obtained = double.tryParse('${m['obtained']}') ?? 0;
          final percent = total > 0 ? obtained / total * 100 : 0;

          return Card(
            child: ListTile(
              title: Text('${m['studentName']} - ${m['subject']}'),
              subtitle: Text(
                'Marks: ${m['obtained']} / ${m['total']}'
                '\nPercentage: ${percent.toStringAsFixed(1)}%',
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> addMarks() async {
    final total = TextEditingController();
    final obtained = TextEditingController();
    final exam = TextEditingController();

    final classList =
        students.where((s) => s['class'] == selectedClass).toList();

    if (classList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students in selected class')),
      );
      return;
    }

    String? studentId;
    String? subject = subjectsForClass(selectedClass).first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateDialog) => AlertDialog(
          title: const Text('Add Subject Marks'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: studentId,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: classList.map((s) {
                    return DropdownMenuItem(
                      value: '${s['id']}',
                      child: Text('${s['name']}'),
                    );
                  }).toList(),
                  onChanged: (v) => updateDialog(() => studentId = v),
                ),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: subjectsForClass(selectedClass).map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (v) => updateDialog(() => subject = v),
                ),
                TextField(
                  controller: exam,
                  decoration: const InputDecoration(labelText: 'Exam Name'),
                ),
                TextField(
                  controller: total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Marks'),
                ),
                TextField(
                  controller: obtained,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Obtained Marks'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final student = classList.firstWhere(
                  (s) => '${s['id']}' == studentId,
                  orElse: () => {},
                );
                final t = double.tryParse(total.text);
                final o = double.tryParse(obtained.text);

                if (student.isEmpty ||
                    t == null ||
                    o == null ||
                    t <= 0 ||
                    o < 0 ||
                    o > t) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Check the marks entered')),
                  );
                  return;
                }

                marks.add({
                  'studentId': student['id'],
                  'studentName': student['name'],
                  'roll': student['roll'],
                  'class': selectedClass,
                  'exam': exam.text.trim(),
                  'subject': subject,
                  'total': t,
                  'obtained': o,
                  'date': DateTime.now().toString(),
                });

                await saveList('academy_marks', marks);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Save Marks'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      studentsPage(),
      feesPage(),
      attendancePage(),
      marksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(academyName),
        backgroundColor: const Color(0xFF123B70),
        foregroundColor: Colors.white,
      ),
      body: pages[selectedPage],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() => selectedPage = index);
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
            label: 'Marks',
          ),
        ],
      ),
    );
  }
}
