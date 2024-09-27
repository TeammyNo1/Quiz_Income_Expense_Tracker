import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome
import 'package:todolist_firebase/screen/signin_screen.dart';
import 'package:todolist_firebase/screen/signup_screen.dart';
import 'package:todolist_firebase/screen/details_screen.dart'; // Import DetailsScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Initialize Firebase for Web
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBE4jZLlALvllv3jStOfOQ-MAzg_kiqVJw",
        authDomain: "todos-70426.firebaseapp.com",
        projectId: "todos-70426",
        storageBucket: "todos-70426.appspot.com",
        messagingSenderId: "648287142144",
        appId: "1:648287142144:web:978e84bc1f2ffb8902b3e5",
        measurementId: "YOUR_MEASUREMENT_ID", // Optional
      ),
    );
  } else {
    // Initialize Firebase for Android or iOS
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default theme

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Income & Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
      ),
      themeMode: _themeMode, // Switch between themes
      home: SigninScreen(), // Start with SigninScreen
      routes: {
        '/signin': (context) => SigninScreen(),
        '/signup': (context) => SignupScreen(), // Add SignupScreen to routes
       
      },
    );
  }
}

class TodoScreen extends StatefulWidget {
  final Function() onThemeChanged;
  final ThemeMode currentThemeMode;

  TodoScreen({required this.onThemeChanged, required this.currentThemeMode});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController =
      TextEditingController(); // Controller for notes
  final CollectionReference _todosCollection =
      FirebaseFirestore.instance.collection('transactions');

  // Sign out function
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(
        context, '/signin'); // Navigate to SigninScreen after sign-out
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Income & Expense Tracker',
          style: TextStyle(
            fontSize: 24.0, // Set font size
            fontWeight: FontWeight.bold, // Set font weight to bold
            color: Colors.white, // Set font color to white
            letterSpacing:
                1.5, // Add some spacing between letters for a cleaner look
          ),
        ),
        backgroundColor: Theme.of(context)
            .primaryColor, // Keep the background color as primary theme color (teal)
        actions: [
          // Add Sign Out Button
          IconButton(
            icon: FaIcon(
                FontAwesomeIcons.signOutAlt), // FontAwesome Sign Out icon
            onPressed: _signOut, // Call sign-out function
            color: Colors.white,
            tooltip: 'Sign Out',
          ),
          IconButton(
            icon: Icon(Icons.show_chart), // Choose an appropriate icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailsScreen()), // Navigate to DetailsScreen
              );
            },
            tooltip: 'View Details',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _todosCollection.snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());

                    // Sort transactions by date
                    List<QueryDocumentSnapshot> sortedTransactions =
                        snapshot.data!.docs;
                    sortedTransactions
                        .sort((a, b) => b['date'].compareTo(a['date']));

                    return ListView(
                      children: sortedTransactions
                          .asMap()
                          .map((index, doc) {
                            // Fetch the transaction data
                            double amount = doc['amount'];
                            String type = doc['type'];
                            String notes = doc['notes'] ?? '';
                            DateTime date = (doc['date'] as Timestamp).toDate();

                            // Define two colors for alternating based on theme
                            Color backgroundColor;
                            if (Theme.of(context).brightness ==
                                Brightness.light) {
                              backgroundColor = index.isEven
                                  ? Colors.teal[50]!
                                  : Colors.grey[200]!;
                            } else {
                              backgroundColor = index.isEven
                                  ? Colors.grey[800]!
                                  : Colors.grey[700]!;
                            }

                            return MapEntry(
                              index,
                              ListTile(
                                title: Text(
                                  '฿${amount.toString()} - $type',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: type == 'รายจ่าย'
                                        ? Colors.redAccent
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'วันที่: ${date.toLocal()} \nโน้ต: $notes', // Show date and notes
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: FaIcon(FontAwesomeIcons
                                          .pen), // FontAwesome edit icon
                                      color: Colors.blueAccent,
                                      onPressed: () =>
                                          _showEditTransactionDialog(
                                              context,
                                              doc.id,
                                              amount,
                                              type,
                                              date,
                                              notes),
                                    ),
                                    IconButton(
                                      icon: FaIcon(FontAwesomeIcons
                                          .trash), // FontAwesome delete icon
                                      color: Colors.redAccent,
                                      onPressed: () =>
                                          _deleteTransaction(doc.id),
                                    ),
                                  ],
                                ),
                                tileColor: backgroundColor, // Alternate colors
                              ),
                            );
                          })
                          .values
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: widget.onThemeChanged,
                child: Icon(
                  widget.currentThemeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                backgroundColor: Colors.teal,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog(context);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _addTransaction(
      String amount, String type, DateTime date, String notes) {
    if (amount.isNotEmpty) {
      _todosCollection.add({
        'amount': double.parse(amount),
        'type': type, // 'รายรับ' or 'รายจ่าย'
        'date': Timestamp.fromDate(
            date), // แปลงวันที่เป็น Timestamp สำหรับ Firestore
        'notes': notes,
        'userId': FirebaseAuth
            .instance.currentUser?.uid, // เก็บ userId ของผู้ใช้ที่บันทึกข้อมูล
      });
      _amountController.clear();
      _notesController.clear(); // Clear notes controller
    }
  }

  void _deleteTransaction(String id) {
    _todosCollection.doc(id).delete();
  }

  void _showAddTransactionDialog(BuildContext context) {
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _notesController = TextEditingController();
    String _selectedType = 'รายรับ'; // Default type: income
    DateTime _selectedDate = DateTime.now(); // Default to current date

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("เพิ่มรายการรายรับรายจ่าย"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  hintText: 'จำนวนเงิน',
                  border: OutlineInputBorder(), // Add border here
                ),
                keyboardType:
                    TextInputType.number, // Expect numeric input for amount
              ),
              SizedBox(height: 8.0),
              // Dropdown for selecting income or expense
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ประเภท',
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: ['รายรับ', 'รายจ่าย'].map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              SizedBox(height: 8.0),
              // Date picker for selecting transaction date
              ListTile(
                title: Text("วันที่: ${_selectedDate.toLocal()}".split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 8.0),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'โน้ต',
                  border: OutlineInputBorder(), // Add border to notes input
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("ยกเลิก"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("เพิ่ม"),
              onPressed: () {
                _addTransaction(_amountController.text, _selectedType,
                    _selectedDate, _notesController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // For editing transactions
  void _showEditTransactionDialog(BuildContext context, String id,
      double amount, String type, DateTime date, String notes) {
    final TextEditingController _editAmountController =
        TextEditingController(text: amount.toString());
    final TextEditingController _editNotesController =
        TextEditingController(text: notes);
    String _editType = type;
    DateTime _editDate = date;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("แก้ไขรายการรายรับรายจ่าย"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editAmountController,
                decoration: InputDecoration(
                  hintText: 'จำนวนเงิน',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _editType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ประเภท',
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _editType = newValue!;
                  });
                },
                items: ['รายรับ', 'รายจ่าย'].map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              SizedBox(height: 8.0),
              ListTile(
                title: Text("วันที่: ${_editDate.toLocal()}".split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _editDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != _editDate) {
                    setState(() {
                      _editDate = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 8.0),
              TextField(
                controller: _editNotesController,
                decoration: InputDecoration(
                  hintText: 'โน้ต',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("ยกเลิก"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("บันทึกการแก้ไข"),
              onPressed: () {
                _todosCollection.doc(id).update({
                  'amount': double.parse(_editAmountController.text),
                  'type': _editType,
                  'date': Timestamp.fromDate(_editDate),
                  'notes': _editNotesController.text,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
