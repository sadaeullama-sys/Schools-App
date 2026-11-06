import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Iqra Children Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F6FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0756B5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF073B70),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const AcademyHome(),
    );
  }
}

class AcademyHome extends StatefulWidget {
  const AcademyHome({super.key});

  @override
  State<AcademyHome> createState() => _AcademyHomeState();
}

class _AcademyHomeState extends State<AcademyHome> {
  static const Color navy = Color(0xFF073B70);
  static const Color blue = Color(0xFF0756B5);

  int selectedTab = 0;
  bool loading = true;

  String schoolName = 'New Iqra Children Academy';
  String schoolAddress = 'Charsadda Road, Peshawar';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];

  final List<String> tabs = [
    'Dashboard',
    'Students',
    'Attendance',
    'Fees',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String getValue(Map<String, dynamic> data, String key) {
    return '${data[key] ?? ''}';
  }

  double number(dynamic value) {
    return double.tryParse('$value') ?? 0;
  }

  String money(double value) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }

  String today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> readList(String key) {
      try {
        final raw = prefs.getString(key);
        if (raw == null) return [];
        return List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      } catch (_) {
        return [];
      }
    }

    if (!mounted) return;

    setState(() {
      students = readList('academy_students');
      fees = readList('academy_fees');
      attendance = readList('academy_attendance');
      marks = readList('academy_marks');
      schoolName = prefs.getString('academy_name') ?? schoolName;
      schoolAddress =
          prefs.getString('academy_address') ?? schoolAddress;
      loading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('academy_students', jsonEncode(students));
    await prefs.setString('academy_fees', jsonEncode(fees));
    await prefs.setString(
        'academy_attendance', jsonEncode(attendance));
    await prefs.setString('academy_marks', jsonEncode(marks));
    await prefs.setString('academy_name', schoolName);
    await prefs.setString('academy_address', schoolAddress);
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  double get totalReceived {
    return fees.fold(
      0,
      (sum, item) => sum + number(item['amount']),
    );
  }

  double get totalOutstanding {
    return students.fold(0, (sum, student) {
      final total = number(student['totalFee']);
      final paid = fees
          .where((f) =>
              getValue(f, 'studentId') == getValue(student, 'id'))
          .fold<double>(
            0,
            (s, f) => s + number(f['amount']),
          );
      return sum + (total - paid).clamp(0, double.infinity);
    });
  }

  int get todayPresent {
    return attendance
        .where((a) =>
            getValue(a, 'date') == today() &&
            getValue(a, 'status') == 'Present')
        .length;
  }

  int get todayAbsent {
    return attendance
        .where((a) =>
            getValue(a, 'date') == today() &&
            getValue(a, 'status') == 'Absent')
        .length;
  }

  double studentPaidFee(Map<String, dynamic> student) {
    return fees
        .where((f) =>
            getValue(f, 'studentId') == getValue(student, 'id'))
        .fold<double>(0, (sum, f) => sum + number(f['amount']));
  }

  double studentDueFee(Map<String, dynamic> student) {
    return (number(student['totalFee']) -
            studentPaidFee(student))
        .clamp(0, double.infinity);
  }

  Future<void> schoolSettings() async {
    final nameController = TextEditingController(text: schoolName);
    final addressController =
        TextEditingController(text: schoolAddress);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('School Settings / اسکول کی معلومات'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'School Address',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              setState(() {
                schoolName = nameController.text.trim();
                schoolAddress = addressController.text.trim();
              });
              await saveData();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              message('School information saved');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    addressController.dispose();
  }

  Future<void> studentForm({Map<String, dynamic>? oldStudent}) async {
    final data = oldStudent ?? {};

    final nameC = TextEditingController(text: getValue(data, 'name'));
    final fatherC =
        TextEditingController(text: getValue(data, 'father'));
    final rollC = TextEditingController(text: getValue(data, 'roll'));
    final classC = TextEditingController(text: getValue(data, 'class'));
    final phoneC = TextEditingController(text: getValue(data, 'phone'));
    final addressC =
        TextEditingController(text: getValue(data, 'address'));
    final dobC = TextEditingController(text: getValue(data, 'dob'));
    final feeC = TextEditingController(
      text: getValue(data, 'totalFee').isEmpty
          ? '0'
          : getValue(data, 'totalFee'),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(oldStudent == null ? 'Add Student' : 'Edit Student'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field(nameC, 'Student Name *'),
                _field(fatherC, 'Father Name'),
                _field(rollC, 'Roll Number'),
                _field(classC, 'Class'),
                _field(phoneC, 'Phone Number',
                    keyboard: TextInputType.phone),
                _field(addressC, 'Address'),
                _field(dobC, 'Date of Birth'),
                _field(feeC, 'Annual Fee (Rs.)',
                    keyboard: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameC.text.trim().isEmpty) {
                message('Student name is required');
                return;
              }

              final student = <String, dynamic>{
                'id': oldStudent == null
                    ? DateTime.now().microsecondsSinceEpoch.toString()
                    : getValue(oldStudent, 'id'),
                'name': nameC.text.trim(),
                'father': fatherC.text.trim(),
                'roll': rollC.text.trim(),
                'class': classC.text.trim(),
                'phone': phoneC.text.trim(),
                'address': addressC.text.trim(),
                'dob': dobC.text.trim(),
                'totalFee': number(feeC.text),
                'admissionDate': oldStudent == null
                    ? today()
                    : getValue(oldStudent, 'admissionDate'),
              };

              setState(() {
                if (oldStudent == null) {
                  students.add(student);
                } else {
                  final index = students.indexWhere(
                    (s) => getValue(s, 'id') == getValue(oldStudent, 'id'),
                  );
                  if (index >= 0) students[index] = student;
                }
              });

              await saveData();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              message('Student saved successfully');
            },
            child: const Text('Save Student'),
          ),
        ],
      ),
    );

    nameC.dispose();
    fatherC.dispose();
    rollC.dispose();
    classC.dispose();
    phoneC.dispose();
    addressC.dispose();
    dobC.dispose();
    feeC.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> deleteStudent(Map<String, dynamic> student) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Delete ${getValue(student, 'name')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes == true) {
      setState(() {
        students.removeWhere(
          (s) => getValue(s, 'id') == getValue(student, 'id'),
        );
      });
      await saveData();
      message('Student deleted');
    }
  }

  Future<void> collectFee(Map<String, dynamic> student) async {
    final amountC = TextEditingController();
    final monthC = TextEditingController(text: 'Current Month');
    final noteC = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collect Fee / فیس وصول کریں'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getValue(student, 'name'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Total Fee: ${money(number(student['totalFee']))}'),
              Text('Already Paid: ${money(studentPaidFee(student))}'),
              Text('Remaining: ${money(studentDueFee(student))}'),
              const SizedBox(height: 12),
              _field(amountC, 'Received Amount (Rs.)',
                  keyboard: TextInputType.number),
              _field(monthC, 'Month / Description'),
              _field(noteC, 'Remarks'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = number(amountC.text);
              if (amount <= 0) {
                message('Enter a valid amount');
                return;
              }

              final record = <String, dynamic>{
                'id': DateTime.now().microsecondsSinceEpoch.toString(),
                'studentId': getValue(student, 'id'),
                'studentName': getValue(student, 'name'),
                'roll': getValue(student, 'roll'),
                'class': getValue(student, 'class'),
                'amount': amount,
                'month': monthC.text.trim(),
                'note': noteC.text.trim(),
                'date': today(),
              };

              setState(() => fees.add(record));
              await saveData();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              message('Fee payment saved');
              await printFeeReceipt(record);
            },
            child: const Text('Save & Receipt'),
          ),
        ],
      ),
    );

    amountC.dispose();
    monthC.dispose();
    noteC.dispose();
  }

  Future<void> markStudentAttendance(
      Map<String, dynamic> student, String status) async {
    final id = getValue(student, 'id');
    final index = attendance.indexWhere((a) =>
        getValue(a, 'studentId') == id &&
        getValue(a, 'date') == today());

    final record = <String, dynamic>{
      'studentId': id,
      'studentName': getValue(student, 'name'),
      'roll': getValue(student, 'roll'),
      'class': getValue(student, 'class'),
      'date': today(),
      'status': status,
    };

    setState(() {
      if (index >= 0) {
        attendance[index] = record;
      } else {
        attendance.add(record);
      }
    });

    await saveData();
    message('${getValue(student, 'name')}: $status');
  }

  String attendanceStatus(Map<String, dynamic> student) {
    final record = attendance.where((a) =>
        getValue(a, 'studentId') == getValue(student, 'id') &&
        getValue(a, 'date') == today());

    return record.isEmpty ? 'Not Marked' : getValue(record.first, 'status');
  }

  Future<void> addMarks(Map<String, dynamic> student) async {
    final subjectC = TextEditingController();
    final totalC = TextEditingController(text: '100');
    final obtainedC = TextEditingController();
    final examC = TextEditingController(text: 'Monthly Exam');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Marks: ${getValue(student, 'name')}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(examC, 'Exam Name'),
              _field(subjectC, 'Subject'),
              _field(totalC, 'Total Marks',
                  keyboard: TextInputType.number),
              _field(obtainedC, 'Obtained Marks',
                  keyboard: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final total = number(totalC.text);
              final obtained = number(obtainedC.text);

              if (subjectC.text.trim().isEmpty ||
                  total <= 0 ||
                  obtained < 0 ||
                  obtained > total) {
                message('Please enter valid marks');
                return;
              }

              setState(() {
                marks.add({
                  'studentId': getValue(student, 'id'),
                  'studentName': getValue(student, 'name'),
                  'roll': getValue(student, 'roll'),
                  'class': getValue(student, 'class'),
                  'exam': examC.text.trim(),
                  'subject': subjectC.text.trim(),
                  'total': total,
                  'obtained': obtained,
                  'date': today(),
                });
              });

              await saveData();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              message('Marks saved');
            },
            child: const Text('Save Marks'),
          ),
        ],
      ),
    );

    subjectC.dispose();
    totalC.dispose();
    obtainedC.dispose();
    examC.dispose();
  }

  Future<void> showStudentDetails(Map<String, dynamic> student) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Student Profile'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: blue,
                    child: Text(
                      getValue(student, 'name').isEmpty
                          ? '?'
                          : getValue(student, 'name')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    getValue(student, 'name'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 25),
                profileRow('Father Name', getValue(student, 'father')),
                profileRow('Roll Number', getValue(student, 'roll')),
                profileRow('Class', getValue(student, 'class')),
                profileRow('Phone', getValue(student, 'phone')),
                profileRow('Date of Birth', getValue(student, 'dob')),
                profileRow('Address', getValue(student, 'address')),
                profileRow('Admission Date',
                    getValue(student, 'admissionDate')),
                profileRow('Annual Fee',
                    money(number(student['totalFee']))),
                profileRow('Paid Fee', money(studentPaidFee(student))),
                profileRow('Remaining Fee',
                    money(studentDueFee(student))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              studentForm(oldStudent: student);
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget profileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> makePdf(String title, List<List<String>> rows) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text(
              schoolName,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Center(child: pw.Text(schoolAddress)),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          if (rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.length > 1 ? rows.skip(1).toList() : [],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(),
            ),
          pw.SizedBox(height: 20),
          pw.Text('Generated: ${today()}'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => document.save(),
    );
  }

  Future<void> printFeeReceipt(Map<String, dynamic> fee) async {
    final rows = <List<String>>[
      ['Description', 'Details'],
      ['Receipt Date', getValue(fee, 'date')],
      ['Student', getValue(fee, 'studentName')],
      ['Roll Number', getValue(fee, 'roll')],
      ['Class', getValue(fee, 'class')],
      ['Month', getValue(fee, 'month')],
      ['Received Amount', money(number(fee['amount']))],
      ['Remarks', getValue(fee, 'note')],
    ];
    await makePdf('FEE PAYMENT RECEIPT', rows);
  }

  Future<void> printStudentList() async {
    final rows = <List<String>>[
      ['Name', 'Father', 'Roll', 'Class', 'Phone', 'Annual Fee'],
      ...students.map((s) => [
            getValue(s, 'name'),
            getValue(s, 'father'),
            getValue(s, 'roll'),
            getValue(s, 'class'),
            getValue(s, 'phone'),
            money(number(s['totalFee'])),
          ]),
    ];
    await makePdf('STUDENT LIST REPORT', rows);
  }

  Future<void> printFeeReport() async {
    final rows = <List<String>>[
      ['Date', 'Student', 'Class', 'Month', 'Amount'],
      ...fees.map((f) => [
            getValue(f, 'date'),
            getValue(f, 'studentName'),
            getValue(f, 'class'),
            getValue(f, 'month'),
            money(number(f['amount'])),
          ]),
    ];
    await makePdf('FEE COLLECTION REPORT', rows);
  }

  Future<void> printAttendanceReport() async {
    final rows = <List<String>>[
      ['Date', 'Student', 'Roll', 'Class', 'Status'],
      ...attendance.map((a) => [
            getValue(a, 'date'),
            getValue(a, 'studentName'),
            getValue(a, 'roll'),
            getValue(a, 'class'),
            getValue(a, 'status'),
          ]),
    ];
    await makePdf('ATTENDANCE REPORT', rows);
  }

  Future<void> printDmc(Map<String, dynamic> student) async {
    final studentMarks = marks
        .where((m) =>
            getValue(m, 'studentId') == getValue(student, 'id'))
        .toList();

    final total = studentMarks.fold<double>(
        0, (sum, m) => sum + number(m['total']));
    final obtained = studentMarks.fold<double>(
        0, (sum, m) => sum + number(m['obtained']));
    final percentage = total == 0 ? 0 : obtained / total * 100;

    final rows = <List<String>>[
      ['Subject', 'Total Marks', 'Obtained Marks'],
      ...studentMarks.map((m) => [
            getValue(m, 'subject'),
            '${m['total']}',
            '${m['obtained']}',
          ]),
      ['TOTAL', '$total', '$obtained'],
      ['PERCENTAGE', '', '${percentage.toStringAsFixed(2)}%'],
    ];

    await makePdf(
      'DETAILED MARKS CERTIFICATE (DMC) - ${getValue(student, 'name')}',
      rows,
    );
  }

  Future<void> printIdCard(Map<String, dynamic> student) async {
    final rows = <List<String>>[
      ['Student ID Card', 'Details'],
      ['Name', getValue(student, 'name')],
      ['Father Name', getValue(student, 'father')],
      ['Roll Number', getValue(student, 'roll')],
      ['Class', getValue(student, 'class')],
      ['Phone', getValue(student, 'phone')],
      ['School', schoolName],
    ];
    await makePdf('STUDENT ID CARD', rows);
  }

  Future<void> printLeavingCertificate(
      Map<String, dynamic> student) async {
    final rows = <List<String>>[
      ['Certificate Detail', 'Information'],
      ['Student Name', getValue(student, 'name')],
      ['Father Name', getValue(student, 'father')],
      ['Roll Number', getValue(student, 'roll')],
      ['Class', getValue(student, 'class')],
      ['Admission Date', getValue(student, 'admissionDate')],
      ['Issue Date', today()],
      ['School', schoolName],
    ];
    await makePdf('SCHOOL LEAVING CERTIFICATE', rows);
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget quickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback action,
  ) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Welcome to $schoolName',
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 5),
        Text(schoolAddress),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            statCard('Total Students', '${students.length}',
                Icons.people, Colors.blue),
            statCard('Today Present', '$todayPresent',
                Icons.check_circle, Colors.green),
            statCard('Fee Collected', money(totalReceived),
                Icons.account_balance_wallet, Colors.purple),
            statCard('Outstanding Fee', money(totalOutstanding),
                Icons.money_off, Colors.red),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
          children: [
            quickAction('Add Student', Icons.person_add,
                Colors.blue, () => studentForm()),
            quickAction('Collect Fee', Icons.payments,
                Colors.purple, () => setState(() => selectedTab = 3)),
            quickAction('Attendance', Icons.fact_check,
                Colors.green, () => setState(() => selectedTab = 2)),
            quickAction('Student List', Icons.groups,
                Colors.teal, () => setState(() => selectedTab = 1)),
            quickAction('Reports', Icons.bar_chart,
                Colors.orange, () => setState(() => selectedTab = 4)),
            quickAction('Settings', Icons.settings,
                Colors.blueGrey, schoolSettings),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Recent Fee Payments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (fees.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No fee payments recorded yet.'),
            ),
          )
        else
          ...fees.reversed.take(5).map(
                (fee) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),
                    title: Text(getValue(fee, 'studentName')),
                    subtitle: Text(
                        '${getValue(fee, 'date')} • ${getValue(fee, 'month')}'),
                    trailing: Text(
                      money(number(fee['amount'])),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
      ],
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
                child: Text(
                  'Students (${students.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => studentForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('No students added yet'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: blue,
                          child: Text(
                            getValue(student, 'name').isEmpty
                                ? '?'
                                : getValue(student, 'name')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(getValue(student, 'name')),
                        subtitle: Text(
                          'Roll: ${getValue(student, 'roll')} • Class: ${getValue(student, 'class')}',
                        ),
                        onTap: () => showStudentDetails(student),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'profile') {
                              showStudentDetails(student);
                            } else if (value == 'edit') {
                              studentForm(oldStudent: student);
                            } else if (value == 'fee') {
                              collectFee(student);
                            } else if (value == 'marks') {
                              addMarks(student);
                            } else if (value == 'id') {
                              printIdCard(student);
                            } else if (value == 'dmc') {
                              printDmc(student);
                            } else if (value == 'leaving') {
                              printLeavingCertificate(student);
                            } else if (value == 'delete') {
                              deleteStudent(student);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'profile', child: Text('Profile')),
                            PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'fee', child: Text('Collect Fee')),
                            PopupMenuItem(
                                value: 'marks', child: Text('Add Marks')),
                            PopupMenuItem(
                                value: 'id', child: Text('Print ID Card')),
                            PopupMenuItem(
                                value: 'dmc', child: Text('Print DMC')),
                            PopupMenuItem(
                                value: 'leaving',
                                child: Text('Leaving Certificate')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
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

  Widget attendancePage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Attendance / حاضری',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Text(today()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: statCard('Present', '$todayPresent',
                    Icons.check_circle, Colors.green),
              ),
              Expanded(
                child: statCard('Absent', '$todayAbsent',
                    Icons.cancel, Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('Add students first'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final status = attendanceStatus(student);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(getValue(student, 'name')),
                        subtitle: Text(
                            'Roll: ${getValue(student, 'roll')} • $status'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Present',
                              onPressed: () =>
                                  markStudentAttendance(student, 'Present'),
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                            ),
                            IconButton(
                              tooltip: 'Absent',
                              onPressed: () =>
                                  markStudentAttendance(student, 'Absent'),
                              icon: const Icon(Icons.cancel,
                                  color: Colors.red),
                            ),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              statCard('Received', money(totalReceived),
                  Icons.payments, Colors.green),
              statCard('Remaining', money(totalOutstanding),
                  Icons.money_off, Colors.red),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Student Fee Records',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('Add students first'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      child: ListTile(
                        title: Text(getValue(student, 'name')),
                        subtitle: Text(
                          'Paid: ${money(studentPaidFee(student))}\nDue: ${money(studentDueFee(student))}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          onPressed: () => collectFee(student),
                          icon: const Icon(Icons.add_circle,
                              color: Colors.green, size: 30),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget reportsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Reports & Certificates / رپورٹس',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _reportTile(
          'Student List Report',
          'All student details in PDF',
          Icons.groups,
          printStudentList,
        ),
        _reportTile(
          'Fee Collection Report',
          'All received fee records',
          Icons.payments,
          printFeeReport,
        ),
        _reportTile(
          'Attendance Report',
          'Present and absent records',
          Icons.fact_check,
          printAttendanceReport,
        ),
        _reportTile(
          'Student DMC / Result Card',
          'Select a student to print DMC',
          Icons.school,
          () => selectStudentAction('DMC', printDmc),
        ),
        _reportTile(
          'Student ID Card',
          'Create printable student ID',
          Icons.badge,
          () => selectStudentAction('ID Card', printIdCard),
        ),
        _reportTile(
          'School Leaving Certificate',
          'Prepare leaving certificate',
          Icons.description,
          () => selectStudentAction(
              'Leaving Certificate', printLeavingCertificate),
        ),
        _reportTile(
          'Exam Marks Entry',
          'Add subject-wise marks',
          Icons.edit_note,
          () => selectStudentAction('Add Marks', addMarks),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                profileRow('Total Students', '${students.length}'),
                profileRow('Fee Payments', '${fees.length}'),
                profileRow('Fee Received', money(totalReceived)),
                profileRow('Outstanding Fee', money(totalOutstanding)),
                profileRow('Attendance Records', '${attendance.length}'),
                profileRow('Exam Records', '${marks.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reportTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5EFFB),
          child: Icon(icon, color: blue),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.picture_as_pdf),
        onTap: action,
      ),
    );
  }

  Future<void> selectStudentAction(
    String title,
    Future<void> Function(Map<String, dynamic>) action,
  ) async {
    if (students.isEmpty) {
      message('Please add a student first');
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select Student - $title'),
        content: SizedBox(
          width: 400,
          height: 350,
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text(getValue(student, 'name')),
                subtitle: Text(
                    'Roll: ${getValue(student, 'roll')} • ${getValue(student, 'class')}'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  action(student);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings / ترتیبات',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.school, color: blue),
            title: Text(schoolName),
            subtitle: Text(schoolAddress),
            trailing: const Icon(Icons.edit),
            onTap: schoolSettings,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup, color: blue),
            title: const Text('Backup Data'),
            subtitle: const Text('Export school records as JSON'),
            onTap: exportBackup,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: blue),
            title: const Text('About'),
            subtitle: const Text('New Iqra Children Academy'),
          ),
        ),
      ],
    );
  }

  Future<void> exportBackup() async {
    final backup = {
      'schoolName': schoolName,
      'schoolAddress': schoolAddress,
      'students': students,
      'fees': fees,
      'attendance': attendance,
      'marks': marks,
      'backupDate': today(),
    };

    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text(
            'Backup JSON:\n${const JsonEncoder.withIndent('  ').convert(backup)}',
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => document.save(),
    );
    message('Backup print/export opened');
  }

  Widget currentPage() {
    switch (selectedTab) {
      case 0:
        return dashboard();
      case 1:
        return studentsPage();
      case 2:
        return attendancePage();
      case 3:
        return feesPage();
      case 4:
        return reportsPage();
      default:
        return dashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schoolName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              tabs[selectedTab],
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: schoolSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: currentPage(),
      floatingActionButton: selectedTab == 1
          ? FloatingActionButton(
              onPressed: () => studentForm(),
              backgroundColor: blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Fees',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
