import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AcademyApp());

const adminUsername = 'Muhammad Ilyas';
const adminPassword = '03135353153';

const classes = [
  'First','Second','Third','Fourth','Fifth',
  'Sixth','Seventh','Eighth','Ninth','Tenth'
];

List<String> subjects(String c) {
  if (['First','Second','Third','Fourth','Fifth'].contains(c)) {
    return ['English','Urdu','Mathematics','General Knowledge','Islamiat'];
  }
  if (['Sixth','Seventh','Eighth'].contains(c)) {
    return ['English','Urdu','Mathematics','Science','Islamiat',
      'Computer','Social Studies'];
  }
  return ['English','Urdu','Mathematics','Physics','Chemistry',
    'Biology','Computer','Islamiat','Pakistan Studies'];
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'New Iqra Children Academy',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF123B70),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F6FA),
    ),
    home: const StartupPage(),
  );
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool loading = true;
  bool activated = false;
  bool hasLogin = false;

  @override
  void initState() {
    super.initState();
    checkApp();
  }

  Future<void> checkApp() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      activated = p.getBool('academy_license_active') ?? false;
      hasLogin =
          (p.getString('academy_customer_username') ?? '').isNotEmpty;
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
    return hasLogin
        ? const CustomerLoginPage()
        : const CustomerLoginSetupPage();
  }
}

class LicensePage extends StatefulWidget {
  const LicensePage({super.key});

  @override
  State<LicensePage> createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  static int adminTaps = 0;

  final keyCtrl = TextEditingController();
  String error = '';
  bool busy = false;

  Future<void> activate() async {
    if (keyCtrl.text.trim().isEmpty) {
      setState(() => error = 'Please enter License Key');
      return;
    }

    setState(() => busy = true);
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('academy_generated_license') ?? '';

    if (keyCtrl.text.trim() == saved && saved.isNotEmpty) {
      final school = p.getString('academy_license_school') ?? '';
      await p.setBool('academy_license_active', true);
      await p.setString('academy_name', school);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerLoginSetupPage(),
        ),
      );
    } else {
      setState(() {
        error = 'Invalid License Key';
        busy = false;
      });
    }
  }

  @override
  void dispose() {
    keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('License Activation')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    adminTaps++;
                    if (adminTaps >= 5) {
                      adminTaps = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLoginPage(),
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.school,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
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
                  controller: keyCtrl,
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
                    child: Text(
                      busy ? 'Checking...' : 'Activate License',
                    ),
                  ),
                ),
                if (error.isNotEmpty)
                  Text(error,
                    style: const TextStyle(color: Colors.red)),
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

class CustomerLoginSetupPage extends StatefulWidget {
  const CustomerLoginSetupPage({super.key});

  @override
  State<CustomerLoginSetupPage> createState() =>
      _CustomerLoginSetupPageState();
}

class _CustomerLoginSetupPageState
    extends State<CustomerLoginSetupPage> {
  final user = TextEditingController();
  final pass = TextEditingController();

  Future<void> saveLogin() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter username and password'),
        ),
      );
      return;
    }

    final p = await SharedPreferences.getInstance();
    await p.setString(
      'academy_customer_username',
      user.text.trim(),
    );
    await p.setString(
      'academy_customer_password',
      pass.text,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerLoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() =>
      _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String error = '';
  static int taps = 0;

  Future<void> login() async {
    final p = await SharedPreferences.getInstance();

    if (user.text.trim() ==
            (p.getString('academy_customer_username') ?? '') &&
        pass.text ==
            (p.getString('academy_customer_password') ?? '')) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => error = 'Incorrect username or password');
    }
  }

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
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
              'New Iqra Children Academy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
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

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();

  void login() {
    if (user.text.trim() == adminUsername &&
        pass.text == adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminPanelPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong Admin Username or Password'),
        ),
      );
    }
  }

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Login')),
    body: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, size: 65),
          const SizedBox(height: 20),
          TextField(
            controller: user,
            decoration: const InputDecoration(
              labelText: 'Admin Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass,
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

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final school = TextEditingController();
  String duration = '1 Month';
  String generatedKey = '';

  Future<void> generate() async {
    if (school.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter School Name')),
      );
      return;
    }

    final r = Random.secure();
    final code = List.generate(
      16,
      (_) => r.nextInt(16).toRadixString(16).toUpperCase(),
    ).join();

    final key = 'IQRA-$code';
    final p = await SharedPreferences.getInstance();

    await p.setString('academy_generated_license', key);
    await p.setString('academy_license_school', school.text.trim());
    await p.setString('academy_license_duration', duration);

    setState(() => generatedKey = key);
  }

  @override
  void dispose() {
    school.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin License Generator')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.verified_user,
          size: 60, color: Colors.blue),
        const SizedBox(height: 20),
        TextField(
          controller: school,
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
            DropdownMenuItem(
              value: '1 Month', child: Text('1 Month')),
            DropdownMenuItem(
              value: '3 Months', child: Text('3 Months')),
            DropdownMenuItem(
              value: '1 Year', child: Text('1 Year')),
            DropdownMenuItem(
              value: 'Lifetime', child: Text('Lifetime')),
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
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: generatedKey),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('License key copied')),
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
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String selectedClass = 'First';
  String school = 'New Iqra Children Academy';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  List<Map<String, dynamic>> readList(String? raw) {
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      school = p.getString('academy_name') ??
          'New Iqra Children Academy';
      students = readList(p.getString('academy_students'));
      fees = readList(p.getString('academy_fees'));
      attendance = readList(p.getString('academy_attendance'));
      marks = readList(p.getString('academy_marks'));
    });
  }

  Future<void> save(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(value));
  }

  double get totalFees => fees.fold(
        0.0,
        (a, e) =>
            a + (double.tryParse('${e['amount']}') ?? 0),
      );

  Widget card(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboard() {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            school,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            children: [
              card(
                'Total Students',
                '${students.length}',
                Icons.people,
                Colors.blue,
              ),
              card(
                'Fee Received',
                'Rs ${totalFees.toStringAsFixed(0)}',
                Icons.payments,
                Colors.green,
              ),
              card(
                'Attendance Records',
                '${attendance.length}',
                Icons.fact_check,
                Colors.orange,
              ),
              card(
                'Exam Records',
                '${marks.length}',
                Icons.school,
                Colors.purple,
              ),
            ],
          ),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Add Student'),
                onPressed: () => formStudent(),
              ),
              ActionChip(
                label: const Text('Collect Fee'),
                onPressed: () => feeEntry(),
              ),
              ActionChip(
                label: const Text('Attendance'),
                onPressed: () => setState(() => tab = 3),
              ),
              ActionChip(
                label: const Text('Exam Marks'),
                onPressed: () => setState(() => tab = 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget classPicker() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      decoration: const InputDecoration(
        labelText: 'Select Class',
        border: OutlineInputBorder(),
      ),
      items: classes.map((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(e),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => selectedClass = v);
      },
    );
  }

  Widget studentsPage() {
    final list = students
        .where((s) => s['class'] == selectedClass)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Class Wise Students',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        classPicker(),
        Text('Total Students: ${list.length}'),
        ElevatedButton.icon(
          onPressed: formStudent,
          icon: const Icon(Icons.add),
          label: const Text('Add Student'),
        ),
        ...list.map(
          (s) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('${s['name'] ?? ''}'),
              subtitle: Text(
                'Father: ${s['father'] ?? ''}\n'
                'Roll: ${s['roll'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () async {
                  setState(() => students.remove(s));
                  await save('academy_students', students);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> formStudent() async {
    final name = TextEditingController();
    final father = TextEditingController();
    final roll = TextEditingController();
    final phone = TextEditingController();

    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Add Student - $selectedClass'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                ),
              ),
              TextField(
                controller: father,
                decoration: const InputDecoration(
                  labelText: 'Father Name',
                ),
              ),
              TextField(
                controller: roll,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                ),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;

              students.add({
                'id': DateTime.now()
                    .microsecondsSinceEpoch
                    .toString(),
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
              });

              await save('academy_students', students);

              if (d.mounted) Navigator.pop(d);
              if (mounted) setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget feesPage() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Fee Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('Total Received: Rs ${totalFees.toStringAsFixed(0)}'),
        ElevatedButton.icon(
          onPressed: feeEntry,
          icon: const Icon(Icons.add),
          label: const Text('Collect Fee'),
        ),
        ...fees.map(
          (f) => Card(
            child: ListTile(
              title: Text('${f['studentName']}'),
              subtitle: Text(
                '${f['class']} • ${f['month']}',
              ),
              trailing: Text('Rs ${f['amount']}'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> feeEntry() async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a student first'),
        ),
      );
      return;
    }

    final amount = TextEditingController();
    final month = TextEditingController();
    String? id;

    await showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, upd) => AlertDialog(
          title: const Text('Collect Fee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: id,
                decoration: const InputDecoration(
                  labelText: 'Student',
                ),
                items: students.map((s) {
                  return DropdownMenuItem(
                    value: '${s['id']}',
                    child: Text('${s['name']}'),
                  );
                }).toList(),
                onChanged: (v) => upd(() => id = v),
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Rs',
                ),
              ),
              TextField(
                controller: month,
                decoration: const InputDecoration(
                  labelText: 'Month',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final s = students.firstWhere(
                  (x) => '${x['id']}' == id,
                  orElse: () => {},
                );
                final a = double.tryParse(amount.text);

                if (s.isEmpty || a == null || a <= 0) return;

                fees.add({
                  'studentId': s['id'],
                  'studentName': s['name'],
                  'roll': s['roll'],
                  'class': s['class'],
                  'amount': a,
                  'month': month.text.trim(),
                  'date': DateTime.now().toString(),
                  'note': '',
                });

                await save('academy_fees', fees);

                if (d.mounted) Navigator.pop(d);
                if (mounted) setState(() {});
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
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        classPicker(),
        ...students
            .where((s) => s['class'] == selectedClass)
            .map(
          (s) => Card(
            child: ListTile(
              title: Text('${s['name']}'),
              subtitle: Text('Roll ${s['roll']}'),
              trailing: ElevatedButton(
                onPressed: () async {
                  attendance.add({
                    'studentId': s['id'],
                    'studentName': s['name'],
                    'class': s['class'],
                    'date': DateTime.now().toString(),
                    'status': 'Present',
                  });

                  await save('academy_attendance', attendance);
                  if (mounted) setState(() {});
                },
                child: const Text('Present'),
              ),
            ),
          ),
        ),
        Text('Attendance records: ${attendance.length}'),
      ],
    );
  }

  Widget marksPage() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Exams & Marks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        classPicker(),
        ElevatedButton.icon(
          onPressed: marksEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add Exam Marks'),
        ),
        ...marks
            .where((m) => m['class'] == selectedClass)
            .map((m) {
          final t = double.tryParse('${m['total']}') ?? 0;
          final o = double.tryParse('${m['obtained']}') ?? 0;
          final p = t > 0 ? o / t * 100 : 0;

          return Card(
            child: ListTile(
              title: Text(
                '${m['studentName']} • ${m['subject']}',
              ),
              subtitle: Text(
                '${m['exam']} | ${m['obtained']}/${m['total']}'
                ' | ${p.toStringAsFixed(1)}%',
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> marksEntry() async {
    final list = students
        .where((s) => s['class'] == selectedClass)
        .toList();

    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students in this class'),
        ),
      );
      return;
    }

    final exam = TextEditingController();
    final total = TextEditingController();
    final obtained = TextEditingController();

    String? id;
    String subject = subjects(selectedClass).first;

    await showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, upd) => AlertDialog(
          title: const Text('Add Marks'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: id,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                  ),
                  items: list.map((s) {
                    return DropdownMenuItem(
                      value: '${s['id']}',
                      child: Text('${s['name']}'),
                    );
                  }).toList(),
                  onChanged: (v) => upd(() => id = v),
                ),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                  ),
                  items: subjects(selectedClass).map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) upd(() => subject = v);
                  },
                ),
                TextField(
                  controller: exam,
                  decoration: const InputDecoration(
                    labelText: 'Exam Name',
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
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final s = list.firstWhere(
                  (x) => '${x['id']}' == id,
                  orElse: () => {},
                );

                final t = double.tryParse(total.text);
                final o = double.tryParse(obtained.text);

                if (s.isEmpty ||
                    t == null ||
                    o == null ||
                    t <= 0 ||
                    o < 0 ||
                    o > t) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Check marks entered'),
                    ),
                  );
                  return;
                }

                marks.add({
                  'studentId': s['id'],
                  'studentName': s['name'],
                  'roll': s['roll'],
                  'class': selectedClass,
                  'exam': exam.text.trim(),
                  'subject': subject,
                  'total': t,
                  'obtained': o,
                  'date': DateTime.now().toString(),
                });

                await save('academy_marks', marks);

                if (d.mounted) Navigator.pop(d);
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
  Widget build(BuildContext c) {
    final pages = [
      dashboard(),
      studentsPage(),
      feesPage(),
      attendancePage(),
      marksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(school),
        backgroundColor: const Color(0xFF123B70),
        foregroundColor: Colors.white,
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() => tab = i);
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
