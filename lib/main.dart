import 'package:flutter/material.dart';

void main() => runApp(const IqraApp());

const navy = Color(0xFF073B78);
const blue = Color(0xFF0878E8);
const pale = Color(0xFFF1F6FD);

class Student {
  Student(this.name,this.father,this.roll,this.clazz,this.phone,this.dob);
  String name, father, roll, clazz, phone, dob;
  int paid = 9000;
  int due = 2500;
  final Map<String,int> marks = {'Urdu':85,'English':78,'Mathematics':92,'Islamiat':88,'Science':80};
}
final students = <Student>[
  Student('Ahmed Raza','Muhammad Asif','A5','5','0315-9649864','12-03-2014'),
  Student('Ali Khan','Muhammad Khan','A1','5','0300-1112233','05-08-2014'),
  Student('Bilal Ahmad','Saeed Ahmad','A2','5','0301-2223344','18-09-2014'),
  Student('Hamza Gul','Gul Rahman','A3','5','0302-3334455','21-01-2014'),
  Student('Imran Khan','Naseer Khan','A4','5','0303-4445566','09-11-2014'),
  Student('Usman Ali','Shah Ali','A6','5','0304-5556677','17-07-2014'),
];

class IqraApp extends StatelessWidget {
  const IqraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'New Iqra Children Academy',
    theme: ThemeData(useMaterial3:true, colorScheme:ColorScheme.fromSeed(seedColor:blue), scaffoldBackgroundColor:pale, appBarTheme:const AppBarTheme(backgroundColor:navy,foregroundColor:Colors.white)),
    home: const LoginPage(),
  );
}
class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
 final u=TextEditingController(text:'admin'), p=TextEditingController(text:'1234');
 @override Widget build(BuildContext context)=>Scaffold(body:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF052C60),Color(0xFF0878E8)],begin:Alignment.topCenter,end:Alignment.bottomCenter)),child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[
 Container(width:96,height:96,decoration:const BoxDecoration(color:Colors.white,shape:BoxShape.circle),child:const Icon(Icons.school,size:58,color:navy)),
 const SizedBox(height:18),const Text('New Iqra\\nChildren Academy',textAlign:TextAlign.center,style:TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.bold)),
 const Text('School Management System',style:TextStyle(color:Colors.white70)),const SizedBox(height:32),
 _field(u,'Username',Icons.person),const SizedBox(height:12),_field(p,'Password',Icons.lock,secret:true),const SizedBox(height:18),
 SizedBox(width:double.infinity,height:52,child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF0085FF),foregroundColor:Colors.white),onPressed:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomePage())),child:const Text('LOGIN',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)))),
 const SizedBox(height:18),const Text('Demo login: admin / 1234',style:TextStyle(color:Colors.white70))
 ])))));
 Widget _field(TextEditingController c,String label,IconData icon,{bool secret=false})=>TextField(controller:c,obscureText:secret,decoration:InputDecoration(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),prefixIcon:Icon(icon,color:navy),hintText:label));
}
class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage> createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{
 int index=0;
 final pages=<Widget>[];
 @override Widget build(BuildContext context){
 final body=[_dashboard(),_students(),_fees(),_attendance(),_reports()][index];
 return Scaffold(appBar:AppBar(title:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('New Iqra Children Academy',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),Text('Charsadda Road, Peshawar',style:TextStyle(fontSize:11,color:Colors.white70))]),actions:[IconButton(onPressed:()=>_settings(),icon:const Icon(Icons.settings))]),body:body,bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const[
 NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
 NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'Students'),
 NavigationDestination(icon:Icon(Icons.payments_outlined),selectedIcon:Icon(Icons.payments),label:'Fees'),
 NavigationDestination(icon:Icon(Icons.fact_check_outlined),selectedIcon:Icon(Icons.fact_check),label:'Attendance'),
 NavigationDestination(icon:Icon(Icons.description_outlined),selectedIcon:Icon(Icons.description),label:'Reports'),
 ]));
 }
 Widget _dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[
 Row(children:[Expanded(child:_stat('Total Students','425',Icons.groups,blue)),const SizedBox(width:10),Expanded(child:_stat('Today Attendance','398 (94%)',Icons.calendar_month,Colors.green))]),
 const SizedBox(height:10),Row(children:[Expanded(child:_stat('Fee Collected','Rs. 125,000',Icons.account_balance_wallet,Colors.deepPurple)),const SizedBox(width:10),Expanded(child:_stat('Outstanding Fee','Rs. 48,500',Icons.money_off,Colors.redAccent))]),
 const SizedBox(height:10),Row(children:[Expanded(child:_stat('Total Teachers','24',Icons.person,Colors.orange)),const SizedBox(width:10),Expanded(child:_stat('Total Classes','10',Icons.menu_book,Colors.teal))]),
 const SizedBox(height:20),const Text('Quick Actions',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:navy)),const SizedBox(height:10),
 Wrap(spacing:10,runSpacing:10,children:[_quick('Add Student',Icons.person_add,Colors.teal,()=>_addStudent()),_quick('Collect Fee',Icons.payments,Colors.deepPurple,()=>setState(()=>index=2)),_quick('Attendance',Icons.fact_check,Colors.green,()=>setState(()=>index=3)),_quick('DMC / Result',Icons.school,blue,()=>_dmc(students.first)),_quick('ID Card',Icons.badge,Colors.pink,()=>_idCard(students.first))]),
 const SizedBox(height:20),const Text('Recent Students',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:navy)),...students.take(4).map((s)=>Card(child:ListTile(leading:_avatar(s),title:Text(s.name,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Roll ${s.roll} • Class ${s.clazz}'),trailing:const Icon(Icons.chevron_right),onTap:()=>_profile(s))))
 ]);
 Widget _stat(String title,String value,IconData icon,Color color)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(16),boxShadow:[BoxShadow(color:color.withOpacity(.18),blurRadius:8,offset:const Offset(0,3))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Colors.white,size:25),const SizedBox(height:8),Text(title,style:const TextStyle(color:Colors.white,fontSize:12)),Text(value,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))]));
 Widget _quick(String t,IconData i,Color c,VoidCallback f)=>SizedBox(width:104,height:90,child:Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:f,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,color:c,size:28),const SizedBox(height:7),Text(t,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))]))));
 Widget _students()=>ListView(padding:const EdgeInsets.all(14),children:[TextField(decoration:InputDecoration(hintText:'Search by name or roll no...',prefixIcon:const Icon(Icons.search),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)),onChanged:(v)=>setState((){})),const SizedBox(height:10),...students.map((s)=>Card(child:ListTile(leading:_avatar(s),title:Text(s.name,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('Roll No. ${s.roll} • Class ${s.clazz}'),trailing:const Icon(Icons.chevron_right),onTap:()=>_profile(s)))),ElevatedButton.icon(onPressed:_addStudent,icon:const Icon(Icons.add),label:const Text('Add Student'))]);
 Widget _fees()=>ListView(padding:const EdgeInsets.all(14),children:[const Text('Student Fee Ledger',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:navy)),...students.map((s)=>Card(child:ListTile(leading:_avatar(s),title:Text(s.name),subtitle:Text('Paid Rs. ${s.paid} • Due Rs. ${s.due}'),trailing:IconButton(icon:const Icon(Icons.edit,color:blue),onPressed:()=>_editFee(s))))]);
 Widget _attendance()=>ListView(padding:const EdgeInsets.all(14),children:[const Text('Class 5 • Attendance',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:navy)),const SizedBox(height:10),...students.map((s)=>Card(child:StatefulBuilder(builder:(context,setLocal)=>CheckboxListTile(value:true,onChanged:(v)=>setLocal((){}),title:Text(s.name),subtitle:Text(s.roll),secondary:_avatar(s)))),ElevatedButton(onPressed:()=>_message('Attendance saved successfully'),child:const Text('Save Attendance'))]);
 Widget _reports()=>ListView(padding:const EdgeInsets.all(14),children:[_report('Student List (PDF/Excel)',Icons.people),_report('Fee Report (PDF/Excel)',Icons.payments),_report('Attendance Report',Icons.fact_check),_report('DMC / Result Report',Icons.school),_report('Leaving Students Report',Icons.exit_to_app),_report('ID Cards (Bulk)',Icons.badge)]);
 Widget _report(String s,IconData i)=>Card(child:ListTile(leading:Icon(i,color:blue),title:Text(s),trailing:const Icon(Icons.chevron_right),onTap:()=>_message('Report export will be configured in next step.')));
 Widget _avatar(Student s)=>CircleAvatar(backgroundColor:const Color(0xFFDCEBFC),child:Text(s.name.split(' ').map((e)=>e[0]).take(2).join(),style:const TextStyle(color:navy,fontWeight:FontWeight.bold)));
 void _profile(Student s)=>showModalBottomSheet(context:context,isScrollControlled:true,builder:(c)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[_avatar(s),const SizedBox(width:12),Expanded(child:Text(s.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:navy))),IconButton(onPressed:()=>_editStudent(s),icon:const Icon(Icons.edit))]),Text('Roll No: ${s.roll} • Class: ${s.clazz}'),Text('Father: ${s.father}'),Text('DOB: ${s.dob}'),Text('Phone: ${s.phone}'),const SizedBox(height:12),Wrap(spacing:8,children:[OutlinedButton(onPressed:()=>_idCard(s),child:const Text('ID Card')),OutlinedButton(onPressed:()=>_dmc(s),child:const Text('DMC')),OutlinedButton(onPressed:()=>_editFee(s),child:const Text('Fee Card'))]) ])));
 void _addStudent(){final s=Student('New Student','Father Name','A${students.length+1}','5','03xx-xxxxxxx','01-01-2015');_editStudent(s,adding:true);}
 void _editStudent(Student s,{bool adding=false}){final name=TextEditingController(text:s.name),father=TextEditingController(text:s.father),roll=TextEditingController(text:s.roll),phone=TextEditingController(text:s.phone);showDialog(context:context,builder:(c)=>AlertDialog(title:Text(adding?'Register Student':'Edit Student'),content:SingleChildScrollView(child:Column(children:[_dialogField(name,'Student Name'),_dialogField(father,'Father Name'),_dialogField(roll,'Roll Number'),_dialogField(phone,'Phone Number')])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),ElevatedButton(onPressed:(){s.name=name.text;s.father=father.text;s.roll=roll.text;s.phone=phone.text;if(adding)students.add(s);setState((){});Navigator.pop(c);},child:const Text('Save'))]));}
 Widget _dialogField(TextEditingController c,String label)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
 void _editFee(Student s){final paid=TextEditingController(text:'${s.paid}'),due=TextEditingController(text:'${s.due}');showDialog(context:context,builder:(c)=>AlertDialog(title:Text('Fee Card • ${s.name}'),content:Column(mainAxisSize:MainAxisSize.min,children:[_dialogField(paid,'Paid Rs.'),_dialogField(due,'Due Rs.')]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),ElevatedButton(onPressed:(){s.paid=int.tryParse(paid.text)??s.paid;s.due=int.tryParse(due.text)??s.due;setState((){});Navigator.pop(c);},child:const Text('Save'))]));}
 void _dmc(Student s){showDialog(context:context,builder:(c)=>StatefulBuilder(builder:(c,setLocal)=>AlertDialog(title:Text('DMC • ${s.name}'),content:SizedBox(width:330,child:SingleChildScrollView(child:Column(children:s.marks.entries.map((e)=>Row(children:[Expanded(child:Text(e.key)),SizedBox(width:75,child:TextFormField(initialValue:'${e.value}',keyboardType:TextInputType.number,onChanged:(v){s.marks[e.key]=int.tryParse(v)??0;setLocal((){});},decoration:const InputDecoration(isDense:true,border:OutlineInputBorder())))] )).toList()))),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Done'))])));}
 void _idCard(Student s){showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Student ID Card'),content:Container(width:300,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:blue),borderRadius:BorderRadius.circular(14)),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.school,color:navy,size:36),const Text('NEW IQRA CHILDREN ACADEMY',textAlign:TextAlign.center,style:TextStyle(color:navy,fontWeight:FontWeight.bold)),const Divider(),_avatar(s),Text(s.name,style:const TextStyle(fontWeight:FontWeight.bold)),Text('Roll: ${s.roll}   Class: ${s.clazz}'),Text('Father: ${s.father}'),Text('DOB: ${s.dob}') ])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close'))]));}
 void _settings(){final user=TextEditingController(text:'admin'),pass=TextEditingController(text:'1234');showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Login Settings'),content:Column(mainAxisSize:MainAxisSize.min,children:[_dialogField(user,'New Username'),_dialogField(pass,'New Password')]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close')),ElevatedButton(onPressed:()=>Navigator.pop(c),child:const Text('Save'))]));}
 void _message(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
}
