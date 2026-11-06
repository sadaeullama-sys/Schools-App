  import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Iqra Children Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1769AA)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12345A),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SchoolHome(),
    );
  }
}

class SchoolHome extends StatefulWidget {
  const SchoolHome({super.key});

  @override
  State<SchoolHome> createState() => _SchoolHomeState();
}

class _SchoolHomeState extends State<SchoolHome> {
  static const Color navy = Color(0xFF12345A);
  static const Color blue = Color(0xFF1769AA);

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> marks = [];

  int tab = 0;
  String search = '';
  String school = 'New Iqra Children Academy';

  @override
  void initState() {
    super.initState();
    load();
  }

  String val(Map<String, dynamic> data, String key) {
    return '${data[key] ?? ''}';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final studentData = prefs.getString('students') ?? '[]';
    final marksData = prefs.getString('marks') ?? '[]';

    final loadedStudents =
        (jsonDecode(studentData) as List).map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();

    final loadedMarks =
        (jsonDecode(marksData) as List).map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();

    if (!mounted) return;

    setState(() {
      students = loadedStudents;
      marks = loadedMarks;
      school = prefs.getString('schoolName') ??
          'New Iqra Children Academy';
    });
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('students', jsonEncode(students));
    await prefs.setString('marks', jsonEncode(marks));
    await prefs.setString('schoolName', school);
  }

  Future<String?> imagePick() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    return image?.path;
  }

  Future<void> settings() async {
    final controller = TextEditingController(text: school);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('School Settings'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'School Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              setState(() {
                school = controller.text.trim();
              });

              await save();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------- STUDENT REGISTRATION ----------
  Future<void> studentForm({
    Map<String, dynamic>? oldStudent,
  }) async {
    final nameC =
        TextEditingController(text: val(oldStudent ?? {}, 'name'));
    final fatherC =
        TextEditingController(text: val(oldStudent ?? {}, 'father'));
    final rollC =
        TextEditingController(text: val(oldStudent ?? {}, 'roll'));
    final classC =
        TextEditingController(text: val(oldStudent ?? {}, 'class'));
    final phoneC =
        TextEditingController(text: val(oldStudent ?? {}, 'phone'));
    final dobC =
        TextEditingController(text: val(oldStudent ?? {}, 'dob'));
    final addressC =
        TextEditingController(text: val(oldStudent ?? {}, 'address'));

    String? photo = val(oldStudent ?? {}, 'photo').isEmpty
        ? null
        : val(oldStudent ?? {}, 'photo');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(
            oldStudent == null
                ? 'Student Registration'
                : 'Edit Student',
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await imagePick();
                      if (picked != null) {
                        setDialog(() => photo = picked);
                      }
                    },
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          photo != null && File(photo!).existsSync()
                              ? FileImage(File(photo!))
                              : null,
                      child: photo == null
                          ? const Icon(Icons.add_a_photo, size: 30)
                          : null,
                    ),
                  ),
                  const Text('Tap to upload student photo'),
                  const SizedBox(height: 12),
                  field(nameC, 'Student Name *'),
                  field(fatherC, 'Father Name'),
                  field(rollC, 'Roll Number *'),
                  field(classC, 'Class'),
                  field(phoneC, 'Phone Number'),
                  field(dobC, 'Date of Birth'),
                  field(addressC, 'Address'),
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
                if (nameC.text.trim().isEmpty ||
                    rollC.text.trim().isEmpty) {
                  return;
                }

                final record = <String, dynamic>{
                  'id': val(oldStudent ?? {}, 'id').isEmpty
                      ? DateTime.now()
                          .millisecondsSinceEpoch
                          .toString()
                      : val(oldStudent ?? {}, 'id'),
                  'name': nameC.text.trim(),
                  'father': fatherC.text.trim(),
                  'roll': rollC.text.trim(),
                  'class': classC.text.trim(),
                  'phone': phoneC.text.trim(),
                  'dob': dobC.text.trim(),
                  'address': addressC.text.trim(),
                  'photo': photo ?? '',
                };

                setState(() {
                  if (oldStudent == null) {
                    students.add(record);
                  } else {
                    final index = students.indexWhere(
                      (s) =>
                          val(s, 'id') == val(oldStudent, 'id'),
                    );
                    if (index >= 0) students[index] = record;
                  }
                });

                await save();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save Student'),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ---------- DMC PAPERS ----------
  List<Map<String, dynamic>> papersFor(
    Map<String, dynamic> student,
  ) {
    return marks
        .where(
          (m) => val(m, 'studentId') == val(student, 'id'),
        )
        .toList();
  }

  Future<void> addPaper(
    Map<String, dynamic> student,
  ) async {
    final subjectC = TextEditingController();
    final totalC = TextEditingController(text: '100');
    final obtainedC = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add DMC Paper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(subjectC, 'Subject / Paper Name'),
            field(totalC, 'Total Marks'),
            field(obtainedC, 'Obtained Marks'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (subjectC.text.trim().isEmpty) return;

              setState(() {
                marks.add({
                  'studentId': val(student, 'id'),
                  'subject': subjectC.text.trim(),
                  'total': double.tryParse(totalC.text) ?? 100,
                  'obtained':
                      double.tryParse(obtainedC.text) ?? 0,
                });
              });

              await save();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add Paper'),
          ),
        ],
      ),
    );
  }

  Future<void> editPaper(
    Map<String, dynamic> paper,
  ) async {
    final totalC =
        TextEditingController(text: '${paper['total']}');
    final obtainedC =
        TextEditingController(text: '${paper['obtained']}');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${val(paper, 'subject')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(totalC, 'Total Marks'),
            field(obtainedC, 'Obtained Marks'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              setState(() {
                paper['total'] =
                    double.tryParse(totalC.text) ?? 100;
                paper['obtained'] =
                    double.tryParse(obtainedC.text) ?? 0;
              });

              await save();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> removePaper(
    Map<String, dynamic> paper,
  ) async {
    setState(() => marks.remove(paper));
    await save();
  }

  // ---------- STUDENT PHOTO ----------
  Widget studentPhoto(
    Map<String, dynamic> student,
  ) {
    final path = val(student, 'photo');

    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.shade100,
      backgroundImage:
          path.isNotEmpty && File(path).existsSync()
              ? FileImage(File(path))
              : null,
      child: path.isEmpty
          ? const Icon(Icons.person)
          : null,
    );
  }

  // ---------- STUDENT LIST ----------
  Widget studentsPage() {
    final list = students.where((s) {
      final query = search.toLowerCase();

      return val(s, 'name').toLowerCase().contains(query) ||
          val(s, 'roll').toLowerCase().contains(query) ||
          val(s, 'father').toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) =>
                setState(() => search = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search student / roll / father name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final student = list[index];

              return Card(
                child: ListTile(
                  leading: studentPhoto(student),
                  title: Text(val(student, 'name')),
                  subtitle: Text(
                    'Roll: ${val(student, 'roll')}'
                    '  Class: ${val(student, 'class')}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await studentForm(
                          oldStudent: student,
                        );
                      } else if (value == 'delete') {
                        setState(() {
                          students.remove(student);
                          marks.removeWhere(
                            (m) =>
                                val(m, 'studentId') ==
                                val(student, 'id'),
                          );
                        });
                        await save();
                      } else if (value == 'id') {
                        await makePdf(
                          'STUDENT ID CARD',
                          student,
                        );
                      } else if (value == 'dmc') {
                        await makePdf(
                          'DETAILED MARKS CERTIFICATE',
                          student,
                          dmc: true,
                        );
                      } else if (value == 'fee') {
                        await makePdf(
                          'STUDENT FEE CARD',
                          student,
                        );
                      } else if (value == 'papers') {
                        await showPapers(student);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Student'),
                      ),
                      PopupMenuItem(
                        value: 'papers',
                        child: Text('Manage DMC Papers'),
                      ),
                      PopupMenuItem(
                        value: 'id',
                        child: Text('ID Card / PDF'),
                      ),
                      PopupMenuItem(
                        value: 'dmc',
                        child: Text('DMC / Result PDF'),
                      ),
                      PopupMenuItem(
                        value: 'fee',
                        child: Text('Fee Card / PDF'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Student'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => studentForm(),
            icon: const Icon(Icons.person_add),
            label: const Text('Register Student'),
          ),
        ),
      ],
    );
  }

  Future<void> showPapers(
    Map<String, dynamic> student,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) {
          final papers = papersFor(student);

          return AlertDialog(
            title: Text(
              'DMC Papers - ${val(student, 'name')}',
            ),
            content: SizedBox(
              width: 450,
              child: papers.isEmpty
                  ? const Text('No papers added yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: papers.length,
                      itemBuilder: (context, index) {
                        final paper = papers[index];

                        return ListTile(
                          title: Text(
                            val(paper, 'subject'),
                          ),
                          subtitle: Text(
                            'Total: ${paper['total']}  '
                            'Obtained: ${paper['obtained']}',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  await editPaper(paper);
                                  setDialog(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await removePaper(paper);
                                  setDialog(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  await addPaper(student);
                  setDialog(() {});
                },
                child: const Text('Add Paper'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- PDF / PRINT ----------
  Future<void> makePdf(
    String title,
    Map<String, dynamic> student, {
    bool dmc = false,
  }) async {
    final doc = pw.Document();
    final papers = papersFor(student);

    final total = papers.fold<double>(
      0,
      (sum, p) =>
          sum + (double.tryParse('${p['total']}') ?? 0),
    );

    final obtained = papers.fold<double>(
      0,
      (sum, p) =>
          sum + (double.tryParse('${p['obtained']}') ?? 0),
    );

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              school,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 18),
            ),
            pw.Divider(),
            pw.Text('Student: ${val(student, 'name')}'),
            pw.Text('Father: ${val(student, 'father')}'),
            pw.Text('Roll No: ${val(student, 'roll')}'),
            pw.Text('Class: ${val(student, 'class')}'),
