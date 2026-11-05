  // ---------- STUDENT REGISTRATION ----------
  Future<void> studentForm({Map<String, dynamic>? oldStudent}) async {
    final nameC = TextEditingController(text: val(oldStudent ?? {}, 'name'));
    final fatherC = TextEditingController(text: val(oldStudent ?? {}, 'father'));
    final rollC = TextEditingController(text: val(oldStudent ?? {}, 'roll'));
    final classC = TextEditingController(text: val(oldStudent ?? {}, 'class'));
    final phoneC = TextEditingController(text: val(oldStudent ?? {}, 'phone'));
    final dobC = TextEditingController(text: val(oldStudent ?? {}, 'dob'));
    final addressC = TextEditingController(text: val(oldStudent ?? {}, 'address'));

    String? photo = val(oldStudent ?? {}, 'photo').isEmpty
        ? null
        : val(oldStudent ?? {}, 'photo');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(oldStudent == null ? 'Student Registration' : 'Edit Student'),
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
                      backgroundImage: photo != null && File(photo!).existsSync()
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
                      ? DateTime.now().millisecondsSinceEpoch.toString()
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
                      (s) => val(s, 'id') == val(oldStudent, 'id'),
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

  Widget field(TextEditingController controller, String label) {
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
  List<Map<String, dynamic>> papersFor(Map<String, dynamic> student) {
    return marks
        .where((m) => val(m, 'studentId') == val(student, 'id'))
        .toList();
  }

  Future<void> addPaper(Map<String, dynamic> student) async {
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
                  'obtained': double.tryParse(obtainedC.text) ?? 0,
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

  Future<void> editPaper(Map<String, dynamic> paper) async {
    final totalC = TextEditingController(text: '${paper['total']}');
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
                paper['total'] = double.tryParse(totalC.text) ?? 100;
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

  Future<void> removePaper(Map<String, dynamic> paper) async {
    setState(() => marks.remove(paper));
    await save();
  }

  // ---------- STUDENT PHOTO ----------
  Widget studentPhoto(Map<String, dynamic> student) {
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
            onChanged: (value) => setState(() => search = value),
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
                        await studentForm(oldStudent: student);
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
                        await makePdf('STUDENT ID CARD', student);
                      } else if (value == 'dmc') {
                        await makePdf(
                          'DETAILED MARKS CERTIFICATE',
                          student,
                          dmc: true,
                        );
                      } else if (value == 'fee') {
                        await makePdf('STUDENT FEE CARD', student);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Student')),
                      PopupMenuItem(value: 'id', child: Text('ID Card / PDF')),
                      PopupMenuItem(value: 'dmc', child: Text('DMC / Result PDF')),
                      PopupMenuItem(value: 'fee', child: Text('Fee Card / PDF')),
                      PopupMenuItem(value: 'delete', child: Text('Delete Student')),
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
      (sum, p) => sum + (double.tryParse('${p['total']}') ?? 0),
    );

    final obtained = papers.fold<double>(
      0,
      (sum, p) => sum + (double.tryParse('${p['obtained']}') ?? 0),
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
            pw.Text(title, style: const pw.TextStyle(fontSize: 18)),
            pw.Divider(),
            pw.Text('Student: ${val(student, 'name')}'),
            pw.Text('Father: ${val(student, 'father')}'),
            pw.Text('Roll No: ${val(student, 'roll')}'),
            pw.Text('Class: ${val(student, 'class')}'),
            if (dmc) ...[
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                headers: ['Paper', 'Total', 'Obtained', '%'],
                data: [
                  ...papers.map((p) {
                    final t = double.tryParse('${p['total']}') ?? 0;
                    final o = double.tryParse('${p['obtained']}') ?? 0;

                    return [
                      val(p, 'subject'),
                      '$t',
                      '$o',
                      t == 0 ? '0%' : '${(o / t * 100).toStringAsFixed(1)}%',
                    ];
                  }),
                  [
                    'TOTAL',
                    '$total',
                    '$obtained',
                    total == 0
                        ? '0%'
                        : '${(obtained / total * 100).toStringAsFixed(1)}%',
                  ],
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Result: ${total > 0 && obtained / total >= 0.40 ? 'PASS' : 'NEEDS REVIEW'}',
              ),
            ],
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  // ---------- DASHBOARD ----------
  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  school,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.people, color: blue),
            title: const Text('Total Students'),
            trailing: Text(
              '${students.length}',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => studentForm(),
          icon: const Icon(Icons.person_add),
          label: const Text('Register Student'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageTitles = [
      'Dashboard',
      'Students',
      'Fees',
      'Attendance',
      'Reports',
    ];

    final pages = [
      dashboard(),
      studentsPage(),
      const Center(child: Text('Fees section')),
      const Center(child: Text('Attendance section')),
      const Center(child: Text('Reports section')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[tab]),
        actions: [
          IconButton(
            onPressed: settings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() => tab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
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
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
