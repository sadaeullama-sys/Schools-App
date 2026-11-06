import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'New Iqra Children Academy',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0756B5),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F6FC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF073B70),
        foregroundColor: Colors.white,
      ),
    ),
    home: const AcademyHome(),
  );
}

class AcademyHome extends StatefulWidget {
  const AcademyHome({super.key});

  @override
  State<AcademyHome> createState() => _AcademyHomeState();
}

class _AcademyHomeState extends State<AcademyHome> {
  static const navy = Color(0xFF073B70);
  static const blue = Color(0xFF0756B5);

  final picker = ImagePicker();

  int tab = 0;
  bool loading = true;

  String schoolName = 'New Iqra Children Academy';
  String schoolAddress = 'Charsadda Road, Peshawar';
  String principal = 'Principal';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> marks = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String val(Map<String, dynamic> m, String k) =>
      '${m[k] ?? ''}';

  double amount(dynamic v) =>
      double.tryParse('$v') ?? 0;

  String money(double n) =>
      'Rs. ${n.toStringAsFixed(0)}';

  String dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String today() => dateText(DateTime.now());

  List<Map<String, dynamic>> readList(
    SharedPreferences p,
    String key,
  ) {
    try {
      final raw = p.getString(key);
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

  Future<void> loadData() async {
    final p = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      students = readList(p, 'academy_students');
      fees = readList(p, 'academy_fees');
      attendance = readList(p, 'academy_attendance');
      marks = readList(p, 'academy_marks');

      schoolName =
          p.getString('academy_name') ?? schoolName;
      schoolAddress =
          p.getString('academy_address') ?? schoolAddress;
      principal =
          p.getString('academy_principal') ?? principal;

      loading = false;
    });
  }

  Future<void> saveData() async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      'academy_students',
      jsonEncode(students),
    );

    await p.setString(
      'academy_fees',
      jsonEncode(fees),
    );

    await p.setString(
      'academy_attendance',
      jsonEncode(attendance),
    );

    await p.setString(
      'academy_marks',
      jsonEncode(marks),
    );

    await p.setString('academy_name', schoolName);
    await p.setString('academy_address', schoolAddress);
    await p.setString('academy_principal', principal);
  }

  void toast(String s) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s)),
    );
  }

  Future<String?> pickDate(String initial) async {
    final start =
        DateTime.tryParse(initial) ?? DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    return d == null ? null : dateText(d);
  }

  Future<String?> choosePhoto() async {
    final source =
        await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo / Camera'),
              onTap: () =>
                  Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () =>
                  Navigator.pop(c, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 900,
        maxHeight: 900,
      );

      if (file == null) return null;

      return base64Encode(await file.readAsBytes());
    } catch (e) {
      toast('Photo selection failed: $e');
      return null;
    }
  }

  Widget studentPhoto(
    String encoded, {
    double size = 58,
  }) {
    Uint8List? bytes;

    try {
      if (encoded.isNotEmpty) {
        bytes = base64Decode(encoded);
      }
    } catch (_) {}

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE2EAF5),
      backgroundImage:
          bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Icon(
              Icons.person,
              size: size * .55,
              color: blue,
            )
          : null,
    );
  }

  double paid(Map<String, dynamic> s) =>
      fees
          .where(
            (f) => val(f, 'studentId') == val(s, 'id'),
          )
          .fold<double>(
            0,
            (a, f) => a + amount(f['amount']),
          );

  double due(Map<String, dynamic> s) =>
      (amount(s['totalFee']) - paid(s))
          .clamp(0, double.infinity)
          .toDouble();

  double get received =>
      fees.fold<double>(
        0,
        (a, f) => a + amount(f['amount']),
      );

  double get outstanding =>
      students.fold<double>(
        0,
        (a, s) => a + due(s),
      );

  int get present => attendance
      .where(
        (a) =>
            val(a, 'date') == today() &&
            val(a, 'status') == 'Present',
      )
      .length;

  int get absent => attendance
      .where(
        (a) =>
            val(a, 'date') == today() &&
            val(a, 'status') == 'Absent',
      )
      .length;

  Future<void> settings() async {
    final n = TextEditingController(text: schoolName);
    final a = TextEditingController(text: schoolAddress);
    final pr = TextEditingController(text: principal);

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('School Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(n, 'School Name'),
              field(a, 'Address'),
              field(pr, 'Principal Name'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (n.text.trim().isEmpty) return;

              setState(() {
                schoolName = n.text.trim();
                schoolAddress = a.text.trim();
                principal = pr.text.trim();
              });

              await saveData();

              if (c.mounted) Navigator.pop(c);
              toast('Settings saved');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    n.dispose();
    a.dispose();
    pr.dispose();
  }

  Widget field(
    TextEditingController c,
    String label, {
    TextInputType type = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget dateField(
    TextEditingController c,
    String label,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          readOnly: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_month),
          ).copyWith(labelText: label),
          onTap: () async {
            final d = await pickDate(c.text);
            if (d != null) c.text = d;
          },
        ),
      );
    Future<void> studentForm({
    Map<String, dynamic>? old,
  }) async {
    final s = old ?? <String, dynamic>{};

    final name = TextEditingController(text: val(s, 'name'));
    final father = TextEditingController(text: val(s, 'father'));
    final roll = TextEditingController(text: val(s, 'roll'));
    final cls = TextEditingController(text: val(s, 'class'));
    final phone = TextEditingController(text: val(s, 'phone'));
    final address = TextEditingController(text: val(s, 'address'));
    final dob = TextEditingController(text: val(s, 'dob'));
    final admission = TextEditingController(
      text: val(s, 'admissionDate').isEmpty
          ? today()
          : val(s, 'admissionDate'),
    );
    final fee = TextEditingController(
      text: val(s, 'totalFee').isEmpty
          ? '0'
          : val(s, 'totalFee'),
    );

    String image = val(s, 'photo');

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, refresh) => AlertDialog(
          title: Text(
            old == null ? 'Student Registration' : 'Edit Student',
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  studentPhoto(image, size: 100),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final p = await choosePhoto();
                      if (p != null) refresh(() => image = p);
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Camera / Gallery Photo'),
                  ),
                  if (image.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => refresh(() => image = ''),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Photo'),
                    ),
                  const SizedBox(height: 12),
                  field(name, 'Student Name *'),
                  field(father, 'Father Name'),
                  field(roll, 'Roll Number'),
                  field(cls, 'Class'),
                  field(
                    phone,
                    'Phone Number',
                    type: TextInputType.phone,
                  ),
                  field(address, 'Address'),
                  dateField(dob, 'Date of Birth'),
                  dateField(admission, 'Admission Date'),
                  field(
                    fee,
                    'Annual Fee (Rs.)',
                    type: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  toast('Student name required');
                  return;
                }

                final item = <String, dynamic>{
                  'id': old == null
                      ? DateTime.now()
                          .microsecondsSinceEpoch
                          .toString()
                      : val(s, 'id'),
                  'name': name.text.trim(),
                  'father': father.text.trim(),
                  'roll': roll.text.trim(),
                  'class': cls.text.trim(),
                  'phone': phone.text.trim(),
                  'address': address.text.trim(),
                  'dob': dob.text,
                  'admissionDate': admission.text,
                  'totalFee': amount(fee.text),
                  'photo': image,
                };

                setState(() {
                  if (old == null) {
                    students.add(item);
                  } else {
                    final i = students.indexWhere(
                      (x) => val(x, 'id') == val(s, 'id'),
                    );
                    if (i >= 0) students[i] = item;
                  }
                });

                await saveData();

                if (c.mounted) Navigator.pop(c);
                toast('Student saved');
              },
              child: const Text('Save Student'),
            ),
          ],
        ),
      ),
    );

    for (final x in [
      name, father, roll, cls, phone,
      address, dob, admission, fee,
    ]) {
      x.dispose();
    }
  }

  Future<void> deleteStudent(
    Map<String, dynamic> s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text(val(s, 'name')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        students.removeWhere(
          (x) => val(x, 'id') == val(s, 'id'),
        );
      });

      await saveData();
      toast('Deleted');
    }
  }

  Future<void> collectFee(
    Map<String, dynamic> s,
  ) async {
    final a = TextEditingController();
    final desc = TextEditingController(text: 'Monthly Fee');
    final date = TextEditingController(text: today());
    final note = TextEditingController();

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Collect Fee - ${val(s, 'name')}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total ${money(amount(s['totalFee']))} '
                '| Paid ${money(paid(s))} '
                '| Due ${money(due(s))}',
              ),
              field(
                a,
                'Received Amount',
                type: TextInputType.number,
              ),
              field(desc, 'Fee Description'),
              dateField(date, 'Payment Date'),
              field(note, 'Remarks'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (amount(a.text) <= 0) {
                toast('Enter valid amount');
                return;
              }

              final f = <String, dynamic>{
                'id': DateTime.now()
                    .microsecondsSinceEpoch
                    .toString(),
                'studentId': val(s, 'id'),
                'studentName': val(s, 'name'),
                'roll': val(s, 'roll'),
                'class': val(s, 'class'),
                'amount': amount(a.text),
                'month': desc.text,
                'date': date.text,
                'note': note.text,
              };

              setState(() => fees.add(f));
              await saveData();

              if (c.mounted) Navigator.pop(c);
              await receipt(f);
            },
            child: const Text('Save & Print Receipt'),
          ),
        ],
      ),
    );

    a.dispose();
    desc.dispose();
    date.dispose();
    note.dispose();
  }

  Future<void> markAttendance(
    Map<String, dynamic> s,
    String status,
    String date,
  ) async {
    final i = attendance.indexWhere(
      (a) =>
          val(a, 'studentId') == val(s, 'id') &&
          val(a, 'date') == date,
    );

    final r = <String, dynamic>{
      'studentId': val(s, 'id'),
      'studentName': val(s, 'name'),
      'roll': val(s, 'roll'),
      'class': val(s, 'class'),
      'date': date,
      'status': status,
    };

    setState(() {
      if (i < 0) {
        attendance.add(r);
      } else {
        attendance[i] = r;
      }
    });

    await saveData();
    toast('$status saved');
  }

  Future<void> marksForm(
    Map<String, dynamic> s,
  ) async {
    final exam = TextEditingController(
      text: 'Annual Examination',
    );
    final subject = TextEditingController();
    final total = TextEditingController(text: '100');
    final obtained = TextEditingController();
    final date = TextEditingController(text: today());

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Marks - ${val(s, 'name')}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(exam, 'Exam Name'),
              field(subject, 'Subject'),
              field(
                total,
                'Total Marks',
                type: TextInputType.number,
              ),
              field(
                obtained,
                'Obtained Marks',
                type: TextInputType.number,
              ),
              dateField(date, 'Exam Date'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final t = amount(total.text);
              final o = amount(obtained.text);

              if (subject.text.trim().isEmpty ||
                  t <= 0 || o < 0 || o > t) {
                toast('Check marks');
                return;
              }

              setState(() {
                marks.add({
                  'studentId': val(s, 'id'),
                  'studentName': val(s, 'name'),
                  'roll': val(s, 'roll'),
                  'class': val(s, 'class'),
                  'exam': exam.text,
                  'subject': subject.text,
                  'total': t,
                  'obtained': o,
                  'date': date.text,
                });
              });

              await saveData();

              if (c.mounted) Navigator.pop(c);
              toast('Marks saved');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    exam.dispose();
    subject.dispose();
    total.dispose();
    obtained.dispose();
    date.dispose();
  }

  Future<void> designedPdf(
    Map<String, dynamic> s,
    String kind,
  ) async {
    final doc = pw.Document();

    pw.MemoryImage? image;

    try {
      final raw = val(s, 'photo');
      if (raw.isNotEmpty) {
        image = pw.MemoryImage(base64Decode(raw));
      }
    } catch (_) {}

    final sm = marks
        .where(
          (m) => val(m, 'studentId') == val(s, 'id'),
        )
        .toList();

    final tm = sm.fold<double>(
      0,
      (a, m) => a + amount(m['total']),
    );

    final om = sm.fold<double>(
      0,
      (a, m) => a + amount(m['obtained']),
    );

    final pct = tm == 0 ? 0.0 : om / tm * 100;

    final isId = kind == 'id';
    final isDmc = kind == 'dmc';

    final title = {
      'id': 'STUDENT ID CARD',
      'dmc': 'DETAILED MARKS CERTIFICATE',
      'character': 'CHARACTER CERTIFICATE',
      'leaving': 'SCHOOL LEAVING CERTIFICATE',
      'fee': 'STUDENT FEE CARD',
    }[kind] ?? 'STUDENT DOCUMENT';

    doc.addPage(
      pw.Page(
        pageFormat: isId
            ? const PdfPageFormat(350, 230)
            : PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(isId ? 10 : 35),
        build: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.blue900,
              width: isId ? 2 : 4,
            ),
          ),
          padding: pw.EdgeInsets.all(isId ? 9 : 22),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                color: PdfColors.blue900,
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  children: [
                    pw.Text(
                      schoolName,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: isId ? 14 : 23,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      schoolAddress,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                      ),
                    ),
                    if (!isId)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 8),
                        child: pw.Text(
                          title,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              if (isId)
                pw.Row(
                  children: [
                    if (image != null)
                      pw.Container(
                        width: 78,
                        height: 90,
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            val(s, 'name'),
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text('Father: ${val(s, 'father')}'),
                          pw.Text('Roll: ${val(s, 'roll')}'),
                          pw.Text('Class: ${val(s, 'class')}'),
                          pw.Text('Phone: ${val(s, 'phone')}'),
                        ],
                      ),
                    ),
                  ],
                )
              else if (isDmc) ...[
                pw.Row(
                  children: [
                    if (image != null)
                      pw.Container(
                        width: 65,
                        height: 75,
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Student: ${val(s, 'name')}'),
                          pw.Text('Father: ${val(s, 'father')}'),
                          pw.Text(
                            'Roll: ${val(s, 'roll')}    '
                            'Class: ${val(s, 'class')}',
                          ),
                          pw.Text(
                            'Exam: ${sm.isEmpty ? '-' : val(sm.first, 'exam')}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.TableHelper.fromTextArray(
                  headers: ['Subject', 'Total', 'Obtained'],
                  data: sm.map((m) => [
                    val(m, 'subject'),
                    '${m['total']}',
                    '${m['obtained']}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Total: ${tm.toStringAsFixed(0)}    '
                  'Obtained: ${om.toStringAsFixed(0)}    '
                  'Percentage: ${pct.toStringAsFixed(2)}%',
                ),
                pw.Text(
                  'Result: ${pct >= 40 ? 'PASS' : 'NEEDS IMPROVEMENT'}',
                ),
              ] else if (kind == 'fee') ...[
                pw.Text('Student: ${val(s, 'name')}'),
                pw.Text('Father: ${val(s, 'father')}'),
                pw.Text(
                  'Roll: ${val(s, 'roll')}    '
                  'Class: ${val(s, 'class')}',
                ),
                pw.Text(
                  'Annual Fee: ${money(amount(s['totalFee']))}',
                ),
                pw.Text('Received: ${money(paid(s))}'),
                pw.Text('Outstanding: ${money(due(s))}'),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Description', 'Amount'],
                  data: fees
                      .where(
                        (f) =>
                            val(f, 'studentId') == val(s, 'id'),
                      )
                      .map((f) => [
                        val(f, 'date'),
                        val(f, 'month'),
                        money(amount(f['amount'])),
                      ])
                      .toList(),
                ),
              ] else ...[
                pw.SizedBox(height: 28),
                pw.Text(
                  'This is to certify that',
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  val(s, 'name'),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 23,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Son/Daughter of ${val(s, 'father')}',
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  kind == 'character'
                      ? 'has been a student of this institution. '
                        'To the best of our knowledge, their character '
                        'and conduct during the period of study has '
                        'been satisfactory.'
                      : 'was admitted to this institution on '
                        '${val(s, 'admissionDate')} and studied in '
                        'class ${val(s, 'class')}. This certificate '
                        'is issued on request.',
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Issue Date: $today()',
                  textAlign: pw.TextAlign.center,
                ),
              ],

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 120,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.Text('Class Teacher'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 120,
               Future<void> receipt(Map<String, dynamic> f) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (c) => pw.Container(
          padding: const pw.EdgeInsets.all(25),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.blue,
              width: 3,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                schoolName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                schoolAddress,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 22),
              pw.Text(
                'FEE PAYMENT RECEIPT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.Text('Date: ${val(f, 'date')}'),
              pw.Text('Student: ${val(f, 'studentName')}'),
              pw.Text(
                'Roll: ${val(f, 'roll')}   '
                'Class: ${val(f, 'class')}',
              ),
              pw.Text('Description: ${val(f, 'month')}'),
              pw.SizedBox(height: 15),
              pw.Text(
                'Received: ${money(amount(f['amount']))}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Cashier Signature'),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  Future<void> reportPdf(
    String title,
    List<List<String>> rows,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (c) => [
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
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: rows.skip(1).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Generated: ${today()}'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  Future<void> selectStudent(
    String title,
    Future<void> Function(Map<String, dynamic>) action,
  ) async {
    if (students.isEmpty) {
      toast('Add students first');
      return;
    }

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          height: 350,
          child: ListView(
            children: students.map((s) {
              return ListTile(
                leading: studentPhoto(
                  val(s, 'photo'),
                  size: 42,
                ),
                title: Text(val(s, 'name')),
                subtitle: Text(
                  'Roll ${val(s, 'roll')} • ${val(s, 'class')}',
                ),
                onTap: () {
                  Navigator.pop(c);
                  action(s);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget stat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget actionChip(
    String text,
    IconData icon,
    VoidCallback onTap,
  ) =>
      ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(text),
        onPressed: onTap,
      );

  Widget dashboard() => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      Text(
        'Welcome to $schoolName',
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
      Text(schoolAddress),
      const SizedBox(height: 12),

      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        children: [
          stat(
            'Total Students',
            '${students.length}',
            Icons.people,
            Colors.blue,
          ),
          stat(
            'Present Today',
            '$present',
            Icons.check_circle,
            Colors.green,
          ),
          stat(
            'Fee Received',
            money(received),
            Icons.payments,
            Colors.purple,
          ),
          stat(
            'Outstanding',
            money(outstanding),
            Icons.money_off,
            Colors.red,
          ),
        ],
      ),

      const SizedBox(height: 12),
      const Text(
        'Quick Actions',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          actionChip(
            'Add Student',
            Icons.person_add,
            () => studentForm(),
          ),
          actionChip(
            'Students',
            Icons.people,
            () => setState(() => tab = 1),
          ),
          actionChip(
            'Attendance',
            Icons.fact_check,
            () => setState(() => tab = 2),
          ),
          actionChip(
            'Fees',
            Icons.payments,
            () => setState(() => tab = 3),
          ),
          actionChip(
            'Reports & Cards',
            Icons.picture_as_pdf,
            () => setState(() => tab = 4),
          ),
          actionChip(
            'Settings',
            Icons.settings,
            settings,
          ),
        ],
      ),

      const SizedBox(height: 12),
      const Text(
        'Recent Fee Payments',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),

      ...fees.reversed.take(5).map(
        (f) => Card(
          child: ListTile(
            leading: const Icon(Icons.receipt),
            title: Text(val(f, 'studentName')),
            subtitle: Text(
              '${val(f, 'date')} • ${val(f, 'month')}',
            ),
            trailing: Text(
              money(amount(f['amount'])),
            ),
          ),
        ),
      ),
    ],
  );

  Widget studentsPage() => Column(
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
              label: const Text('Add Student'),
            ),
          ],
        ),
      ),

      Expanded(
        child: students.isEmpty
            ? const Center(
                child: Text('No students registered'),
              )
            : ListView.builder(
                itemCount: students.length,
                itemBuilder: (c, i) {
                  final s = students[i];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: studentPhoto(
                        val(s, 'photo'),
                      ),
                      title: Text(val(s, 'name')),
                      subtitle: Text(
                        'Roll ${val(s, 'roll')} • '
                        'Class ${val(s, 'class')}',
                      ),
                      onTap: () => studentDetails(s),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') {
                            studentForm(old: s);
                          }
                          if (v == 'delete') {
                            deleteStudent(s);
                          }
                          if (v == 'fee') {
                            collectFee(s);
                          }
                          if (v == 'marks') {
                            marksForm(s);
                          }
                          if (v == 'id') {
                            designedPdf(s, 'id');
                          }
                          if (v == 'dmc') {
                            designedPdf(s, 'dmc');
                          }
                          if (v == 'character') {
                            designedPdf(s, 'character');
                          }
                          if (v == 'leaving') {
                            designedPdf(s, 'leaving');
                          }
                          if (v == 'feecard') {
                            designedPdf(s, 'fee');
                          }
                        },
                        itemBuilder: (c) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Student'),
                          ),
                          PopupMenuItem(
                            value: 'fee',
                            child: Text('Collect Fee'),
                          ),
                          PopupMenuItem(
                            value: 'marks',
                            child: Text('Add Exam Marks'),
                          ),
                          PopupMenuItem(
                            value: 'id',
                            child: Text('Student ID Card'),
                          ),
                          PopupMenuItem(
                            value: 'dmc',
                            child: Text('DMC / Result Card'),
                          ),
                          PopupMenuItem(
                            value: 'character',
                            child: Text('Character Certificate'),
                          ),
                          PopupMenuItem(
                            value: 'leaving',
                            child: Text('Leaving Certificate'),
                          ),
                          PopupMenuItem(
                            value: 'feecard',
                            child: Text('Fee Card'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
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

  Future<void> studentDetails(
    Map<String, dynamic> s,
  ) async {
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Student Profile'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              children: [
                studentPhoto(
                  val(s, 'photo'),
                  size: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  val(s, 'name'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                info('Father', val(s, 'father')),
                info('Roll', val(s, 'roll')),
                info('Class', val(s, 'class')),
                info('Phone', val(s, 'phone')),
                info('DOB', val(s, 'dob')),
                info('Admission', val(s, 'admissionDate')),
                info(
                  'Annual Fee',
                  money(amount(s['totalFee'])),
                ),
                info('Paid', money(paid(s))),
                info('Due', money(due(s))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              studentForm(old: s);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget info(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );

  Widget attendancePage() {
    final date = TextEditingController(text: today());

    return StatefulBuilder(
      builder: (context, refresh) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final d = await pickDate(date.text);
                    if (d != null) {
                      refresh(() => date.text = d);
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(date.text),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (c, i) {
                final s = students[i];

                final rec = attendance.where(
                  (a) =>
                      val(a, 'studentId') == val(s, 'id') &&
                      val(a, 'date') == date.text,
                );

                final status = rec.isEmpty
                    ? 'Not Marked'
                    : val(rec.first, 'status');

                return Card(
                  child: ListTile(
                    leading: studentPhoto(
                      val(s, 'photo'),
                      size: 44,
                    ),
                    title: Text(val(s, 'name')),
                    subtitle: Text(
                      '${val(s, 'roll')} • $status',
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await markAttendance(
                              s,
                              'Present',
                              date.text,
                            );
                            refresh(() {});
                          },
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await markAttendance(
                              s,
                              'Absent',
                              date.text,
                            );
                            refresh(() {});
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget feesPage() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: stat(
                'Received',
                money(received),
                Icons.payments,
                Colors.green,
              ),
            ),
            Expanded(
              child: stat(
                'Due',
                money(outstanding),
                Icons.money_off,
                Colors.red,
              ),
            ),
          ],
        ),
      ),

      Expanded(
        child: ListView.builder(
          itemCount: students.length,
          itemBuilder: (c, i) {
            final s = students[i];

            return Card(
              child: ListTile(
                leading: studentPhoto(
                  val(s, 'photo'),
                  size: 44,
                ),
                title: Text(val(s, 'name')),
                subtitle: Text(
                  'Paid ${money(paid(s))} • '
                  'Due ${money(due(s))}',
                ),
                trailing: IconButton(
                  onPressed: () => collectFee(s),
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget reportTile(
    String title,
    IconData icon,
    VoidCallback fn,
  ) =>
      Card(
        child: ListTile(
          leading: Icon(icon, color: blue),
          title: Text(title),
          trailing: const Icon(Icons.picture_as_pdf),
          onTap: fn,
        ),
      );

  Widget reportsPage() => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      const Text(
        'Reports, Cards & Certificates',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      reportTile(
        'Student List Report',
        Icons.groups,
        () => reportPdf('STUDENT LIST', [
          ['Name', 'Father', 'Roll', 'Class', 'Phone'],
          ...students.map(
            (s) => [
              val(s, 'name'),
              val(s, 'father'),
              val(s, 'roll'),
              val(s, 'class'),
              val(s, 'phone'),
            ],
          )
