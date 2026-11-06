import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademyApp());
}

const adminUsername = 'Muhammad Ilyas';
// Admin password is checked locally. Change it before distributing the app.
const adminPassword = '03135353153';
const supportNumber = '03161847676';

const classes = [
  'First', 'Second', 'Third', 'Fourth', 'Fifth',
  'Sixth', 'Seventh', 'Eighth', 'Ninth', 'Tenth'
];

List<String> subjectsFor(String className) {
  final junior = [
    'English', 'Urdu', 'Mathematics', 'General Knowledge', 'Islamiat'
  ];
  final middle = [
    'English', 'Urdu', 'Mathematics', 'Science',
    'Islamiat', 'Computer', 'Social Studies'
  ];
  final matric = [
    'English', 'Urdu', 'Mathematics', 'Physics',
    'Chemistry', 'Biology', 'Computer', 'Islamiat',
    'Pakistan Studies'
  ];

  if (['First', 'Second', 'Third', 'Fourth', 'Fifth']
      .contains(className)) return junior;
  if (['Sixth', 'Seventh', 'Eighth'].contains(className)) return middle;
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff123c70)),
        useMaterial3: true,
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
  bool loading = true;
  bool activated = false;
  bool loggedIn = false;
  String schoolName = 'New Iqra Children Academy';

  @override
  void initState() {
    super.initState();
    checkApp();
  }

  Future<void> checkApp() async {
    final p = await SharedPreferences.getInstance();
    schoolName = p.getString('academy_name') ?? schoolName;
    activated = p.getBool('academy_activated') ?? false;
    loggedIn = p.getBool('academy_logged_in') ?? false;
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!activated) {
      return ActivationPage(onActivated: (name) async {
        final p = await SharedPreferences.getInstance();
        await p.setBool('academy_activated', true);
        await p.setString('academy_name', name);
        setState(() {
          schoolName = name;
          activated = true;
        });
      });
    }

    if (!loggedIn) {
      return CustomerLoginPage(onLogin: () {
        setState(() => loggedIn = true);
      });
    }

    return AcademyHome(schoolName: schoolName);
  }
}

class ActivationPage extends StatefulWidget {
  final ValueChanged<String> onActivated;
  const ActivationPage({super.key, required this.onActivated});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final keyController = TextEditingController();
  String message = '';

  // Basic offline activation for a prototype.
  // This is not tamper-proof: a generator inside the same APK cannot
  // securely protect its signing secret from a determined attacker.
  String makeKey(String name, String duration) {
    final raw = '$name|$duration|IQRA2026';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  Future<void> activate() async {
    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(keyController.text.trim())),
      );
      final parts = decoded.split('|');
      if (parts.length != 3 || parts[2] != 'IQRA2026') {
        setState(() => message = 'Invalid License Key');
        return;
      }

      final name = parts[0].trim();
      if (name.isEmpty) {
        setState(() => message = 'Invalid School Name');
        return;
      }

      final p = await SharedPreferences.getInstance();
      await p.setString('academy_name', name);
      await p.setString('academy_license_duration', parts[1]);
      widget.onActivated(name);
    } catch (_) {
      setState(() => message = 'Invalid License Key');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Activation')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.school, size: 75, color: Colors.blue),
              const SizedBox(height: 18),
              const Text('New Iqra Children Academy',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
                child: FilledButton(
                  onPressed: activate,
                  child: const Text('Activate License'),
                ),
              ),
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              Text('License Support: $supportNumber'),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerLoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const CustomerLoginPage({super.key, required this.onLogin});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String error = '';
  int logoTaps = 0;

  Future<void> login() async {
    final p = await SharedPreferences.getInstance();
    final savedUser = p.getString('academy_customer_user') ?? 'admin';
    final savedPass = p.getString('academy_customer_pass') ?? '1234';

    if (user.text.trim() == savedUser && pass.text == savedPass) {
      await p.setBool('academy_logged_in', true);
      widget.onLogin();
    } else {
      setState(() => error = 'Username or password is incorrect');
    }
  }

  void openAdmin() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  logoTaps++;
                  if (logoTaps >= 5) {
                    logoTaps = 0;
                    openAdmin();
                  }
                },
                child: const CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.school, size: 55),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Customer Login',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: user,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: login,
                  child: const Text('Login'),
                ),
              ),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
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
  final user = TextEditingController();
  final pass = TextEditingController();
  String error = '';

  void login() {
    if (user.text.trim() == adminUsername && pass.text == adminPassword) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const AdminPanel()));
    } else {
      setState(() => error = 'Admin login incorrect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            TextField(controller: user,
              decoration: const InputDecoration(labelText: 'Admin Username')),
            TextField(controller: pass, obscureText: true,
              decoration: const InputDecoration(labelText: 'Admin Password')),
            const SizedBox(height: 15),
            FilledButton(onPressed: login, child: const Text('Login')),
            Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final school = TextEditingController();
  final customerUser = TextEditingController();
  final customerPass = TextEditingController();
  String duration = '1 Month';
  String generatedKey = '';

  String generateKey() {
    final name = school.text.trim();
    if (name.isEmpty) return '';
    final raw = '$name|$duration|IQRA2026';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  Future<void> saveCustomerLogin() async {
    final p = await SharedPreferences.getInstance();
    if (customerUser.text.trim().isEmpty || customerPass.text.isEmpty) return;
    await p.setString('academy_customer_user', customerUser.text.trim());
    await p.setString('academy_customer_pass', customerPass.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer login saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('License Generator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          TextField(controller: school,
            decoration: const InputDecoration(labelText: 'School Name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: duration,
            decoration: const InputDecoration(labelText: 'License Duration'),
            items: ['1 Month', '3 Months', '1 Year', 'Lifetime']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => duration = v ?? '1 Month'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() => generatedKey = generateKey()),
            child: const Text('Generate License Key'),
          ),
          if (generatedKey.isNotEmpty) ...[
            SelectableText(generatedKey),
            OutlinedButton(
              onPressed: () {
                // Long-press the key to copy it from the selectable text.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select and copy the key above')),
                );
              },
              child: const Text('Copy key: select text above'),
            ),
          ],
          const Divider(height: 35),
          const Text('Customer Login Setup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: customerUser,
            decoration: const InputDecoration(labelText: 'Customer Username')),
          TextField(controller: customerPass, obscureText: true,
            decoration: const InputDecoration(labelText: 'Customer Password')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saveCustomerLogin,
            child: const Text('Save Customer Login'),
          ),
        ],
      ),
    );
  }
}
class AcademyHome extends StatefulWidget {
  final String schoolName;
  const AcademyHome({super.key, required this.schoolName});

  @override
  State<AcademyHome> createState() => _AcademyHomeState();
}

class _AcademyHomeState extends State<AcademyHome> {
  int page = 0;
  int logoTaps = 0;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];

  String selectedClass = 'First';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final p = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> readList(String key) {
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

    setState(() {
      students = readList('academy_students');
      fees = readList('academy_fees');
      attendance = readList('academy_attendance');
      marks = readList('academy_marks');
    });
  }

  Future<void> saveData() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('academy_students', jsonEncode(students));
    await p.setString('academy_fees', jsonEncode(fees));
    await p.setString('academy_attendance', jsonEncode(attendance));
    await p.setString('academy_marks', jsonEncode(marks));
  }

  List<Map<String, dynamic>> get classStudents {
    return students.where((s) => s['class'] == selectedClass).toList();
  }

  double get totalFees {
    return fees.fold(0.0, (sum, f) =>
      sum + (double.tryParse('${f['amount']}') ?? 0));
  }

  void openStudentForm({Map<String, dynamic>? oldStudent}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormPage(
          oldStudent: oldStudent,
          onSave: (student) async {
            setState(() {
              if (oldStudent == null) {
                students.add(student);
              } else {
                final index = students.indexWhere(
                  (s) => s['id'] == oldStudent['id'],
                );
                if (index >= 0) students[index] = student;
              }
            });
            await saveData();
          },
        ),
      ),
    );
  }

  void deleteStudent(Map<String, dynamic> student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Delete ${student['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        students.removeWhere((s) => s['id'] == student['id']);
        fees.removeWhere((f) => f['studentId'] == student['id']);
        attendance.removeWhere((a) => a['studentId'] == student['id']);
        marks.removeWhere((m) => m['studentId'] == student['id']);
      });
      await saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Students', 'Fees', 'Attendance', 'Exams'];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            logoTaps++;
            if (logoTaps >= 5) {
              logoTaps = 0;
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()));
            }
          },
          child: Text(widget.schoolName),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('academy_logged_in', false);
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const StartPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: page,
        children: [
          dashboardPage(),
          studentsPage(),
          feesPage(),
          attendancePage(),
          examsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (v) => setState(() => page = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Fees'),
          NavigationDestination(icon: Icon(Icons.fact_check), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Exams'),
        ],
      ),
    );
  }

  Widget dashboardPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Welcome to ${widget.schoolName}',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            dashboardCard('Total Students', '${students.length}', Icons.people),
            dashboardCard('Total Fees Received', 'Rs. ${totalFees.toStringAsFixed(0)}', Icons.payments),
            dashboardCard('Classes', '10', Icons.class_),
            dashboardCard('Today Attendance', '${attendance.length}', Icons.fact_check),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Quick Actions',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => openStudentForm(),
          icon: const Icon(Icons.person_add),
          label: const Text('Add New Student'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => page = 1),
          icon: const Icon(Icons.people),
          label: const Text('View Students'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => page = 2),
          icon: const Icon(Icons.payments),
          label: const Text('Collect Fee'),
        ),
      ],
    );
  }

  Widget dashboardCard(String title, String value, IconData icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(height: 8),
              Text(title),
              const SizedBox(height: 5),
              Text(value,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget studentsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Select Class',
                    border: OutlineInputBorder(),
                  ),
                  items: classes.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedClass = v ?? 'First'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => openStudentForm(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '$selectedClass Class — ${classStudents.length} Students',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: classStudents.isEmpty
              ? const Center(child: Text('No students in this class'))
              : ListView.builder(
                  itemCount: classStudents.length,
                  itemBuilder: (context, index) {
                    final s = classStudents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${s['roll'] ?? ''}'),
                        ),
                        title: Text('${s['name'] ?? ''}'),
                        subtitle: Text(
                          'Father: ${s['father'] ?? ''}\n'
                          'Roll: ${s['roll'] ?? ''} | Class: ${s['class'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') openStudentForm(oldStudent: s);
                            if (v == 'delete') deleteStudent(s);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget feesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Total Received: Rs. ${totalFees.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => showFeeForm(),
          icon: const Icon(Icons.add),
          label: const Text('Collect Student Fee'),
        ),
        ...fees.map((f) => Card(
          child: ListTile(
            title: Text('${f['studentName'] ?? ''}'),
            subtitle: Text(
              'Class: ${f['class'] ?? ''} | Month: ${f['month'] ?? ''}'),
            trailing: Text('Rs. ${f['amount'] ?? 0}'),
          ),
        )),
      ],
    );
  }

  void showFeeForm() {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a student first')),
      );
      return;
    }

    Map<String, dynamic> selected = students.first;
    final amount = TextEditingController();
    final month = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Collect Fee'),
        content: StatefulBuilder(
          builder: (ctx, setDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: students.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('${s['name']} (${s['class']})'),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setDialog(() => selected = v);
                  },
                ),
                TextField(
                  controller: month,
                  decoration: const InputDecoration(labelText: 'Month'),
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount Rs.'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text);
              if (value == null || value <= 0) return;

              setState(() {
                fees.add({
                  'studentId': selected['id'],
                  'studentName': selected['name'],
                  'roll': selected['roll'],
                  'class': selected['class'],
                  'amount': value,
                  'month': month.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                });
              });

              await saveData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Fee'),
          ),
        ],
      ),
    );
  }

  Widget attendancePage() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Class-wise Attendance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(labelText: 'Select Class'),
          items: classes.map((c) =>
            DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => selectedClass = v ?? 'First'),
        ),
        ...classStudents.map((s) => Card(
          child: ListTile(
            title: Text('${s['name']}'),
            subtitle: Text('Roll: ${s['roll']}'),
            trailing: FilledButton(
              onPressed: () async {
                final today = DateTime.now().toIso8601String().substring(0, 10);
                setState(() {
                  attendance.removeWhere((a) =>
                    a['studentId'] == s['id'] && a['date'] == today);
                  attendance.add({
                    'studentId': s['id'],
                    'studentName': s['name'],
                    'class': s['class'],
                    'date': today,
                    'status': 'Present',
                  });
                });
                await saveData();
              },
              child: const Text('Present'),
            ),
          ),
        )),
      ],
    );
  }

  Widget examsPage() {
    return MarksPage(
      students: students,
      marks: marks,
      onSave: (record) async {
        setState(() => marks.add(record));
        await saveData();
      },
    );
  }
}

class StudentFormPage extends StatefulWidget {
  final Map<String, dynamic>? oldStudent;
  final ValueChanged<Map<String, dynamic>> onSave;

  const StudentFormPage({
    super.key,
    this.oldStudent,
    required this.onSave,
  });

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final name = TextEditingController();
  final father = TextEditingController();
  final roll = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final totalFee = TextEditingController();

  String studentClass = 'First';

  @override
  void initState() {
    super.initState();
    final s = widget.oldStudent;
    if (s != null) {
      name.text = '${s['name'] ?? ''}';
      father.text = '${s['father'] ?? ''}';
      roll.text = '${s['roll'] ?? ''}';
      phone.text = '${s['phone'] ?? ''}';
      address.text = '${s['address'] ?? ''}';
      totalFee.text = '${s['totalFee'] ?? ''}';
      studentClass = classes.contains(s['class']) ? s['class'] : 'First';
    }
  }

  Widget field(String label, TextEditingController c,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void save() {
    if (name.text.trim().isEmpty || roll.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter student name and roll number')),
      );
      return;
    }

    final old = widget.oldStudent;
    widget.onSave({
      'id': old?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name.text.trim(),
      'father': father.text.trim(),
      'roll': roll.text.trim(),
      'class': studentClass,
      'phone': phone.text.trim(),
      'address': address.text.trim(),
      'totalFee': double.tryParse(totalFee.text) ?? 0,
      'photo': old?['photo'] ?? '',
      'admissionDate': old?['admissionDate'] ??
          DateTime.now().toIso8601String(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(
        widget.oldStudent == null ? 'Add Student' : 'Edit Student')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field('Student Name', name),
          field('Father Name', father),
          field('Roll Number', roll, type: TextInputType.number),
          DropdownButtonFormField<String>(
            value: studentClass,
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
            ),
            items: classes.map((c) =>
              DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => studentClass = v ?? 'First'),
          ),
          const SizedBox(height: 12),
          field('Phone Number', phone, type: TextInputType.phone),
          field('Address', address),
          field('Total Fee Rs.', totalFee, type: TextInputType.number),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: const Text('Save Student'),
          ),
        ],
      ),
    );
  }
}
class MarksPage extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> marks;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const MarksPage({
    super.key,
    required this.students,
    required this.marks,
    required this.onSave,
  });

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  String selectedClass = 'First';
  String selectedSubject = 'English';

  Map<String, dynamic>? selectedStudent;

  final examController = TextEditingController();
  final totalController = TextEditingController(text: '100');
  final obtainedController = TextEditingController();

  List<Map<String, dynamic>> get classStudents {
    return widget.students
        .where((s) => s['class'] == selectedClass)
        .toList();
  }

  double get percentage {
    final total = double.tryParse(totalController.text) ?? 0;
    final obtained = double.tryParse(obtainedController.text) ?? 0;

    if (total <= 0) return 0;
    return (obtained / total) * 100;
  }

  String get result {
    final total = double.tryParse(totalController.text) ?? 0;
    final obtained = double.tryParse(obtainedController.text) ?? 0;

    if (total <= 0 || obtained < 0 || obtained > total) {
      return 'Invalid Marks';
    }

    return percentage >= 33 ? 'Pass' : 'Fail';
  }

  Future<void> saveMarks() async {
    if (selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select student')),
      );
      return;
    }

    final total = double.tryParse(totalController.text);
    final obtained = double.tryParse(obtainedController.text);

    if (examController.text.trim().isEmpty ||
        total == null ||
        obtained == null ||
        total <= 0 ||
        obtained < 0 ||
        obtained > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid exam marks')),
      );
      return;
    }

    await widget.onSave({
      'studentId': selectedStudent!['id'],
      'studentName': selectedStudent!['name'],
      'roll': selectedStudent!['roll'],
      'class': selectedClass,
      'exam': examController.text.trim(),
      'subject': selectedSubject,
      'total': total,
      'obtained': obtained,
      'percentage': percentage,
      'result': result,
      'date': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    obtainedController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marks saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = subjectsFor(selectedClass);

    if (!subjects.contains(selectedSubject)) {
      selectedSubject = subjects.first;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Examination & DMC',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: const InputDecoration(
            labelText: 'Select Class',
            border: OutlineInputBorder(),
          ),
          items: classes.map((c) =>
            DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) {
            setState(() {
              selectedClass = v ?? 'First';
              selectedStudent = null;
              selectedSubject = subjectsFor(selectedClass).first;
            });
          },
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<Map<String, dynamic>>(
          value: selectedStudent,
          decoration: const InputDecoration(
            labelText: 'Select Student',
            border: OutlineInputBorder(),
          ),
          items: classStudents.map((s) =>
            DropdownMenuItem(
              value: s,
              child: Text('${s['name']} - ${s['roll']}'),
            )).toList(),
          onChanged: (v) => setState(() => selectedStudent = v),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: examController,
          decoration: const InputDecoration(
            labelText: 'Exam Name (Monthly / Annual)',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedSubject,
          decoration: const InputDecoration(
            labelText: 'Select Subject',
            border: OutlineInputBorder(),
          ),
          items: subjects.map((s) =>
            DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() => selectedSubject = v ?? subjects.first);
          },
        ),

        const SizedBox(height: 12),

        TextField(
          controller: totalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Marks',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: obtainedController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Obtained Marks',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 15),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Percentage: ${percentage.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Result: $result',
                  style: TextStyle(
                    fontSize: 18,
                    color: result == 'Pass' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        FilledButton.icon(
          onPressed: saveMarks,
          icon: const Icon(Icons.save),
          label: const Text('Save Marks'),
        ),

        const Divider(height: 30),

        const Text(
          'Saved Marks Records',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        ...widget.marks
            .where((m) => m['class'] == selectedClass)
            .map((m) => Card(
              child: ListTile(
                title: Text('${m['studentName']}'),
                subtitle: Text(
                  '${m['exam']} | ${m['subject']}\n'
                  'Obtained: ${m['obtained']} / ${m['total']}',
                ),
                isThreeLine: true,
                trailing: Text('${m['percentage']}%'),
              ),
            )),
      ],
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
