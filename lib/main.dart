import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const IqraApp());

const navy = Color(0xFF073B78);
const blue = Color(0xFF0878E8);
const pale = Color(0xFFF2F6FC);

class IqraApp extends StatelessWidget {
  const IqraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New Iqra Children Academy',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: pale,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  void login() {
    if (user.text.trim() == 'admin' && pass.text == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username or password is incorrect')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: navy,
                      child: Icon(Icons.school, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'New Iqra Children Academy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const Text('School Management System'),
                    const SizedBox(height: 24),
                    TextField(
                      controller: user,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => login(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: login,
                        child: const Text('Login'),
                      ),
                    ),
                    const Text(
                      'Starter access: admin / 1234',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Student {
  String name;
  String father;
  String roll;
  String klass;
  String phone;

  Student(this.name, this.father, this.roll, this.klass, this.phone);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String klass = 'All';
  String searchText = '';
  final students = <Student>[
    Student('Ahmed Raza', 'Muhammad Asif', 'A5', '5', '0315-9649864'),
  ];

  void addStudent() {
    final n = TextEditingController();
    final f = TextEditingController();
    final r = TextEditingController();
    final p = TextEditingController();
    String c = '5';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Register Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: 'Student Name'),
                ),
                TextField(
                  controller: f,
                  decoration: const InputDecoration(labelText: 'Father Name'),
                ),
                TextField(
                  controller: r,
                  decoration: const InputDecoration(labelText: 'Roll Number'),
                ),
                DropdownButtonFormField<String>(
                  value: c,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                      .map((x) => DropdownMenuItem(
                            value: x,
                            child: Text('Class $x'),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => c = v ?? '5'),
                ),
                TextField(
                  controller: p,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (n.text.trim().isEmpty || r.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student name and roll number are required'),
                    ),
                  );
                  return;
                }
                setState(() {
                  students.add(Student(
                    n.text.trim(),
                    f.text.trim(),
                    r.text.trim(),
                    c,
                    p.text.trim(),
                  ));
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
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
      studentList(),
      simplePage('Teachers', Icons.people),
      simplePage('Attendance', Icons.fact_check),
      simplePage('Reports', Icons.bar_chart),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Iqra Children Academy',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Education Today | Bright Future Tomorrow',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const SchoolSettings(),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Teachers'),
          NavigationDestination(
            icon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.school, color: navy),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'New Iqra Children Academy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            stat('Total Students', '${students.length}', Icons.groups, blue),
            stat('Today Attendance', '0', Icons.calendar_month, Colors.green),
            stat('Fee Collected', 'Rs. 0', Icons.payments, Colors.deepPurple),
            stat(
              'Outstanding Fee',
              'Rs. 0',
              Icons.account_balance_wallet,
              Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search student by name or roll number',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => searchText = v),
        ),
        const SizedBox(height: 12),
        ...[
          'Register Student',
          'Register Teacher',
          'Fee Entry',
          'Marks Entry / DMC',
          'Attendance',
          'Student ID Card',
          'Leaving Certificate',
          'Reports',
        ].map(
          (title) => Card(
            child: ListTile(
              leading: const Icon(Icons.chevron_right, color: blue),
              title: Text(title),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => title == 'Register Student'
                  ? addStudent()
                  : showFeature(title),
            ),
          ),
        ),
      ],
    );
  }

  Widget stat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white),
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget studentList() {
    final rows = students.where((s) {
      final matchesClass = klass == 'All' || s.klass == klass;
      final query = searchText.toLowerCase();
      final matchesSearch = s.name.toLowerCase().contains(query) ||
          s.roll.toLowerCase().contains(query) ||
          s.father.toLowerCase().contains(query);
      return matchesClass && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text(
                'Students',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: klass,
                items: ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                    .map((x) => DropdownMenuItem(
                          value: x,
                          child: Text(x == 'All' ? x : 'Class $x'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => klass = v ?? 'All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: rows
                .map(
                  (s) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(s.name),
                      subtitle: Text('Roll No: ${s.roll}  •  Class: ${s.klass}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentProfile(student: s),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: addStudent,
            icon: const Icon(Icons.add),
            label: const Text('Add Student'),
          ),
        ),
      ],
    );
  }

  Widget simplePage(String name, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: navy),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('Module starter screen'),
          ],
        ),
      );

  void showFeature(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FeaturePage(title: title)),
    );
  }
}

class StudentProfile extends StatelessWidget {
  final Student student;
  const StudentProfile({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    child: Icon(Icons.person, size: 45),
                  ),
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Roll No: ${student.roll}  •  Class: ${student.klass}'),
                  const Divider(),
                  detail('Father Name', student.father),
                  detail('Contact No.', student.phone),
                  detail('Status', 'Active'),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Student ID Card',
              'Fee Card',
              'DMC / Result Card',
              'Leaving Certificate',
            ].map((x) => FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeaturePage(title: x, student: student),
                ),
              ),
              child: Text(x),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

Widget detail(String label, String value) => ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

class FeaturePage extends StatelessWidget {
  final String title;
  final Student? student;
  const FeaturePage({super.key, required this.title, this.student});

  @override
  Widget build(BuildContext context) {
    final s = student ??
        Student('Ahmed Raza', 'Muhammad Asif', 'A5', '5', '0315-9649864');
    final isId = title.contains('ID Card');
    final isDmc = title.contains('DMC') || title.contains('Result');
    final isFee = title.contains('Fee');
    final isLeaving = title.contains('Leaving');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: pale,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD5E1F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.school, color: navy, size: 30),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEW IQRA CHILDREN ACADEMY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Charsadda Road, Peshawar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isId
                              ? 'STUDENT ID CARD'
                              : isDmc
                                  ? 'DETAILED MARKS CERTIFICATE (DMC)'
                                  : isFee
                                      ? 'STUDENT FEE CARD'
                                      : isLeaving
                                          ? 'SCHOOL LEAVING CERTIFICATE'
                                          : title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isId || isFee)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 82,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F1FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 64,
                                color: blue,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: navy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _line('Roll No.', s.roll),
                                  _line('Class', s.klass),
                                  _line('Father Name', s.father),
                                  if (isFee) _line('Phone', s.phone),
                                ],
                              ),
                            ),
                          ],
                        )
                      else if (isLeaving)
                        Column(
                          children: [
                            const SizedBox(height: 14),
                            const Text(
                              'School Leaving Certificate',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This is to certify that ${s.name}, son/daughter of ${s.father}, Roll No. ${s.roll}, Class ${s.klass}, has studied at this school.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, height: 1.6),
                            ),
                            const SizedBox(height: 28),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Date: __________'),
                                Text('Principal Signature'),
                              ],
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _line('Student', s.name)),
                                Expanded(child: _line('Roll No.', s.roll)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: _line('Class', s.klass)),
                                Expanded(child: _line('Session', '2025-26')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Table(
                              border: TableBorder.all(
                                color: const Color(0xFFD5E1F0),
                              ),
                              children: const [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEAF2FC),
                                  ),
                                  children: [
                                    _cell('Subject', true),
                                    _cell('Total', true),
                                    _cell('Obtained', true),
                                    _cell('%', true),
                                    _cell('Grade', true),
                                  ],
                                ),
                                TableRow(children: [
                                  _cell('Urdu'), _cell('100'), _cell('85'),
                                  _cell('85%'), _cell('A'),
                                ]),
                                TableRow(children: [
                                  _cell('English'), _cell('100'), _cell('78'),
                                  _cell('78%'), _cell('B+'),
                                ]),
                                TableRow(children: [
                                  _cell('Mathematics'), _cell('100'), _cell('92'),
                                  _cell('92%'), _cell('A+'),
                                ]),
                                TableRow(children: [
                                  _cell('Islamiat'), _cell('100'), _cell('88'),
                                  _cell('88%'), _cell('A'),
                                ]),
                                TableRow(children: [
                                  _cell('Science'), _cell('100'), _cell('80'),
                                  _cell('80%'), _cell('A'),
                                ]),
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEAF2FC),
                                  ),
                                  children: [
                                    _cell('TOTAL', true), _cell('500', true),
                                    _cell('423', true), _cell('84.6%', true),
                                    _cell('A', true),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Result: PASS',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Principal',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (isId) ...[
                        const SizedBox(height: 20),
                        Container(
                          height: 34,
                          width: double.infinity,
                          decoration: const BoxDecoration(color: Colors.white),
                          child: const Text(
                            '▌▌▌ ▌▌ ▌▌▌▌ ▌▌ ▌▌▌ ▌▌▌',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, letterSpacing: 2),
                          ),
                        ),
                        const Text(
                          'Issue Date: Auto',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Print feature can be connected in the next build.'),
                    ),
                  ),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE52D55),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF export can be connected in the next build.'),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 82,
              child: Text(
                '$label:',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: navy,
                ),
              ),
            ),
          ],
        ),
      );

  static Widget _cell(String value, [bool bold = false]) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
}

class SchoolSettings extends StatefulWidget {
  const SchoolSettings({super.key});

  @override
  State<SchoolSettings> createState() => _SchoolSettingsState();
}

class _SchoolSettingsState extends State<SchoolSettings> {
  final c = TextEditingController(text: 'New Iqra Children Academy');

  @override
  void initState() {
    super.initState();
    loadName();
  }

  Future<void> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    c.text = prefs.getString('schoolName') ?? 'New Iqra Children Academy';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('School Settings'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'School Name'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('schoolName', c.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
}
