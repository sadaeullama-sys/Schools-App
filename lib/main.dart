import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SchoolApp());

const navy = Color(0xFF073B78);
const blue = Color(0xFF0878E8);
const pale = Color(0xFFF1F6FC);

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'New Iqra Children Academy',
    theme: ThemeData(useMaterial3:true, colorScheme: ColorScheme.fromSeed(seedColor:navy),
      scaffoldBackgroundColor:pale, appBarTheme:const AppBarTheme(backgroundColor:navy,foregroundColor:Colors.white)),
    home: const LoginPage());
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
 final u=TextEditingController(); final p=TextEditingController();
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:navy,body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Card(
  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
  const Icon(Icons.school,size:72,color:blue),const Text('New Iqra Children Academy',textAlign:TextAlign.center,style:TextStyle(fontSize:24,fontWeight:FontWeight.bold,color:navy)),
  const SizedBox(height:8),const Text('School Management System'),const SizedBox(height:22),
  TextField(controller:u,decoration:const InputDecoration(labelText:'Username',prefixIcon:Icon(Icons.person),border:OutlineInputBorder())),
  const SizedBox(height:12),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock),border:OutlineInputBorder())),
  const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){if(u.text=='admin'&&p.text=='1234'){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomePage()));}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Demo login: admin / 1234')));}},child:const Text('Login'))),
  const Text('Demo login: admin / 1234',style:TextStyle(color:Colors.grey))
 ]))))));}
}

class Student {String name,father,roll,klass,phone; Student(this.name,this.father,this.roll,this.klass,this.phone);
 Map<String,dynamic> toJson()=>{'name':name,'father':father,'roll':roll,'klass':klass,'phone':phone};
 factory Student.fromJson(Map<String,dynamic> j)=>Student(j['name']??'',j['father']??'',j['roll']??'',j['klass']??'',j['phone']??'');
}

class HomePage extends StatefulWidget {const HomePage({super.key});@override State<HomePage> createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{
 List<Student> students=[]; int tab=0; String school='New Iqra Children Academy'; final search=TextEditingController();
 @override void initState(){super.initState();load();}
 Future<void> load() async {final sp=await SharedPreferences.getInstance();final raw=sp.getString('students')??'[]';setState(()=>students=(jsonDecode(raw) as List).map((e)=>Student.fromJson(e)).toList());school=sp.getString('school')??school;}
 Future<void> save() async {final sp=await SharedPreferences.getInstance();await sp.setString('students',jsonEncode(students.map((s)=>s.toJson()).toList()));}
 void addStudent(){final n=TextEditingController(),f=TextEditingController(),r=TextEditingController(),c=TextEditingController(text:'5'),ph=TextEditingController();showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Register Student'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[field(n,'Student Name'),field(f,'Father Name'),field(r,'Roll No. e.g. A5'),field(c,'Class'),field(ph,'Phone Number')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){if(n.text.trim().isNotEmpty){setState(()=>students.add(Student(n.text,f.text,r.text,c.text,ph.text)));save();Navigator.pop(context);}},child:const Text('Save'))]));}
 Widget field(TextEditingController c,String label)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
 @override Widget build(BuildContext context){final shown=students.where((s)=>('${s.name} ${s.roll} ${s.klass}').toLowerCase().contains(search.text.toLowerCase())).toList();return Scaffold(
 appBar:AppBar(title:Text(school,style:const TextStyle(fontSize:18)),actions:[IconButton(icon:const Icon(Icons.settings),onPressed:editSchool)]),
 body:tab==0?dashboard():tab==1?studentList(shown):tab==2?simple('Teachers',Icons.people):tab==3?simple('Attendance',Icons.fact_check):simple('Reports',Icons.bar_chart),
 floatingActionButton:tab==1?FloatingActionButton.extended(onPressed:addStudent,icon:const Icon(Icons.add),label:const Text('Add Student')):null,
 bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.home),label:'Home'),NavigationDestination(icon:Icon(Icons.groups),label:'Students'),NavigationDestination(icon:Icon(Icons.person),label:'Teachers'),NavigationDestination(icon:Icon(Icons.fact_check),label:'Attendance'),NavigationDestination(icon:Icon(Icons.analytics),label:'Reports')]));
 }
 Widget dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:navy,borderRadius:BorderRadius.circular(20)),child:Row(children:[const CircleAvatar(backgroundColor:Colors.white,child:Icon(Icons.school,color:blue)),const SizedBox(width:14),Expanded(child:Text(school,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))),const Icon(Icons.settings,color:Colors.white)])),
 const SizedBox(height:16),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.45,crossAxisSpacing:12,mainAxisSpacing:12,children:[stat('Students','${students.length}',Icons.groups,blue),stat('Teachers','0',Icons.person,Colors.green),stat('Fee collected','Rs. 0',Icons.payments,Colors.deepPurple),stat('Fee balance','Rs. 0',Icons.account_balance_wallet,Colors.red)]),
 const SizedBox(height:14),TextField(controller:search,onChanged:(_)=>setState(()=>{}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search student by name or roll number',border:OutlineInputBorder())),
 const SizedBox(height:12),...['Register Student','Fee Entry','Marks Entry / DMC','Attendance','Student ID Card','Leaving Certificate','Reports'].map((x)=>Card(child:ListTile(leading:const Icon(Icons.chevron_right,color:blue),title:Text(x),trailing:const Icon(Icons.arrow_forward_ios,size:16),onTap:()=>setState(()=>tab=1))))
 ]);
 Widget stat(String label,String value,IconData icon,Color color)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color),const Spacer(),Text(label),Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold))]));
 Widget studentList(List<Student> rows) {
   return ListView(
     padding: const EdgeInsets.all(12),
     children: [
       DropdownButtonFormField<String>(
         value: 'All',
         decoration: const InputDecoration(
           labelText: 'Select Class',
           border: OutlineInputBorder(),
         ),
         items: ['All', '5', '6', '7', '8', '9', '10']
             .map((e) => DropdownMenuItem<String>(
                   value: e,
                   child: Text(e == 'All' ? 'All Classes' : 'Class $e'),
                 ))
             .toList(),
         onChanged: (v) {
           setState(() {
             search.text = '';
           });
         },
       ),
       const SizedBox(height: 10),
       ...rows.map((s) => Card(
             child: ListTile(
               leading: CircleAvatar(
                 backgroundColor: blue,
                 child: Text(s.roll.isEmpty ? '?' : s.roll),
               ),
               title: Text(s.name),
               subtitle: Text('Roll No: ${s.roll}  •  Class: ${s.klass}'),
               trailing: const Icon(Icons.chevron_right),
               onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => StudentDetail(student: s, school: school),
                   ),
                 );
               },
             ),
           )),
     ],
   );
 }
 Widget simple(String name,IconData icon)=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:64,color:blue),Text(name,style:const TextStyle(fontSize:24)),const Text('Module screen starter — add records from Students.')])); 
 Future<void> editSchool()async{final c=TextEditingController(text:school);await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('School Name'),content:TextField(controller:c),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()async{setState(()=>school=c.text);final sp=await SharedPreferences.getInstance();await sp.setString('school',school);if(context.mounted)Navigator.pop(context);},child:const Text('Save'))]));}
}

class StudentDetail extends StatelessWidget {final Student student;final String school;const StudentDetail({super.key,required this.student,required this.school});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Student Details')),body:ListView(padding:const EdgeInsets.all(16),children:[
 Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const CircleAvatar(radius:42,child:Icon(Icons.person,size:48)),Text(student.name,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),Text('Roll No: ${student.roll}  |  Class: ${student.klass}'),Text('Father: ${student.father}'),Text('Phone: ${student.phone}')]))),
 documentCard(context,'Student ID Card',Icons.badge),documentCard(context,'Fee Card',Icons.receipt_long),documentCard(context,'DMC / Result Card',Icons.school),documentCard(context,'Leaving Certificate',Icons.workspace_premium)
 ]));
 Widget documentCard(BuildContext context,String title,IconData icon)=>Card(child:ListTile(leading:Icon(icon,color:blue),title:Text(title),trailing:const Icon(Icons.picture_as_pdf),onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:Text(title),content:Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(border:Border.all(color:blue),borderRadius:BorderRadius.circular(12)),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(school,style:const TextStyle(color:navy,fontWeight:FontWeight.bold,fontSize:18),textAlign:TextAlign.center),const Divider(),Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(student.name),Text('Roll: ${student.roll} • Class: ${student.klass}'),const SizedBox(height:20),const Text('This preview is ready for PDF/print module integration.')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close'))]))));
}
