import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const navy = Color(0xFF123B78);
const blue = Color(0xFF1769D2);

void main() => runApp(const SchoolApp());

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Iqra Children Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xfff3f6fb),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String school = 'New Iqra Children Academy';
  String? logo;
  int tab = 0;
  String search = '';

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> attendance = [];

  final picker = ImagePicker();
  final searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();

    setState(() {
      school = p.getString('school') ?? school;
      logo = p.getString('logo');
      students = read(p, 'students');
      teachers = read(p, 'teachers');
      fees = read(p, 'fees');
      marks = read(p, 'marks');
      attendance = read(p, 'attendance');
    });
  }

  List<Map<String, dynamic>> read(
    SharedPreferences p,
    String key,
  ) {
    final data = jsonDecode(p.getString(key) ?? '[]') as List;

    return data
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();

    await p.setString('school', school);

    if (logo != null) {
      await p.setString('logo', logo!);
    }

    final data = {
      'students': students,
      'teachers': teachers,
      'fees': fees,
      'marks': marks,
      'attendance': attendance,
    };

    for (final item in data.entries) {
      await p.setString(item.key, jsonEncode(item.value));
    }
  }

  String val(Map m, String key) => '${m[key] ?? ''}';

  Map<String, dynamic>? studentByRoll(String roll) {
    for (final student in students) {
      if (val(student, 'roll').toLowerCase() ==
          roll.toLowerCase()) {
        return student;
      }
    }
    return null;
  }

  Future<String?> imagePick() async {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'School Name',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final image = await imagePick();

                if (image != null) {
                  setState(() => logo = image);
                }
              },
              icon: const Icon(Icons.image),
              label: const Text('Select School Logo'),
            ),
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
                school = controller.text.trim().isEmpty
                    ? 'School Management'
                    : controller.text.trim();
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
