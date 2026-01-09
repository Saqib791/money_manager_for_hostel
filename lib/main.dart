import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Money Manager',
      themeMode: provider.isDark ? ThemeMode.dark : ThemeMode.light,
      
      // === COMPACT LIGHT THEME ===
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact, // Compact Mode
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
        cardColor: Colors.white,
        brightness: Brightness.light,
        primaryColor: provider.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: provider.primaryColor,
          brightness: Brightness.light,
          primary: provider.primaryColor,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 2,
          toolbarHeight: 50, // Smaller AppBar
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Smaller Inputs
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade50,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),

      // === COMPACT DARK THEME ===
      darkTheme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        primaryColor: provider.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: provider.primaryColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
          primary: provider.primaryColor,
          onSurface: const Color(0xFFE0E0E0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 50,
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF444444)),
          ),
        ),
      ),
      
      home: const SplashScreen(),
    );
  }
}

// === 1. ANIMATED SPLASH SCREEN ===
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    final minWait = Future.delayed(const Duration(seconds: 2));
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.loadData(); 
    await minWait;
    if (!mounted) return;
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const HomeScreenWrapper())
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.primaryColor.withOpacity(0.1),
                  border: Border.all(color: provider.primaryColor.withOpacity(0.3), width: 2)
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded, 
                  size: 60, 
                  color: provider.primaryColor
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "My Money Manager",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Theme.of(context).textTheme.bodyLarge?.color
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: provider.primaryColor),
            )
          ],
        ),
      ),
    );
  }
}

// === 2. HOME WRAPPER ===
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    if (provider.isFirstRun && !provider.hasAskedForFolder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.markFolderAsked();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Setup Auto-Backup"),
            content: const Text("Select a folder to keep your data safe automatically."),
            actions: [
               TextButton(
                 onPressed: () {
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Warning: Data might be lost if app uninstalled.")));
                 },
                 child: const Text("Skip"),
               ),
               FilledButton(
                 onPressed: () async {
                   Navigator.pop(ctx);
                   await provider.requestPermissionsAndPickFolder(context);
                 },
                 child: const Text("Select Folder"),
               )
            ],
          )
        );
      });
    }

    return const MainScreen();
  }
}

// --- LOGIC ENGINE ---
class AppProvider with ChangeNotifier {
  bool isDark = true;
  Color primaryColor = Colors.cyan; 
  String lastBackupPath = "Not selected";
  bool isFirstRun = true;
  bool hasAskedForFolder = false;

  double totalBalance = 0.0;

  List<String> contacts = [];
  List<Transaction> transactions = [];
  
  String tiffinName = "";
  DateTime? tiffinStartDate;
  Map<String, String> tiffinExceptions = {}; 
  List<Map<String, dynamic>> tiffinHistory = [];

  AppProvider();

  void toggleTheme() {
    isDark = !isDark;
    saveData();
  }

  void updateThemeColor(Color color) {
    primaryColor = color;
    saveData();
  }
  
  void markFolderAsked() { hasAskedForFolder = true; }
  void updateBalance(double amount) { totalBalance = amount; saveData(); }
  void addMoneyToWallet(double amount) { totalBalance += amount; saveData(); }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDark') ?? true;
    
    int? colorInt = prefs.getInt('themeColor');
    if(colorInt != null) primaryColor = Color(colorInt);

    lastBackupPath = prefs.getString('lastBackupPath') ?? "Not selected";
    isFirstRun = (lastBackupPath == "Not selected");

    totalBalance = prefs.getDouble('totalBalance') ?? 0.0;
    contacts = prefs.getStringList('contacts') ?? [];
    
    final txnString = prefs.getString('transactions');
    if (txnString != null) {
      final List<dynamic> decoded = jsonDecode(txnString);
      transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
    }

    tiffinName = prefs.getString('tiffinName') ?? "";
    final startStr = prefs.getString('tiffinStartDate');
    if (startStr != null) tiffinStartDate = DateTime.parse(startStr);
    
    final exStr = prefs.getString('tiffinExceptions');
    if (exStr != null) tiffinExceptions = Map<String, String>.from(jsonDecode(exStr));

    final histStr = prefs.getString('tiffinHistory');
    if (histStr != null) tiffinHistory = List<Map<String, dynamic>>.from(jsonDecode(histStr));

    if (lastBackupPath != "Not selected") await _loadFromFile();

    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
    prefs.setInt('themeColor', primaryColor.value);
    prefs.setString('lastBackupPath', lastBackupPath);
    prefs.setDouble('totalBalance', totalBalance);
    prefs.setStringList('contacts', contacts);
    
    if(transactions.length < 50) {
       prefs.setString('transactions', jsonEncode(transactions.map((e) => e.toJson()).toList()));
    }
    
    prefs.setString('tiffinName', tiffinName);
    if(tiffinStartDate != null) prefs.setString('tiffinStartDate', tiffinStartDate!.toIso8601String());
    else prefs.remove('tiffinStartDate');
    
    prefs.setString('tiffinExceptions', jsonEncode(tiffinExceptions));
    prefs.setString('tiffinHistory', jsonEncode(tiffinHistory));
    
    await _saveToFile();
    notifyListeners();
  }
  
  Future<void> _saveToFile() async {
     if (lastBackupPath == "Not selected") return;
     try {
      final data = {
        'balance': totalBalance,
        'contacts': contacts,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'tiffin': {
          'name': tiffinName,
          'start': tiffinStartDate?.toIso8601String(),
          'ex': tiffinExceptions,
          'hist': tiffinHistory
        }
      };
      
      File file = File('$lastBackupPath/auto_save_manager_backup.json');
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Auto-save failed: $e");
    }
  }
  
  Future<void> _loadFromFile() async {
    try {
       File file = File('$lastBackupPath/auto_save_manager_backup.json');
       if (!await file.exists()) file = File('$lastBackupPath/manager_backup.json');

       if (await file.exists()) {
          String content = await file.readAsString();
          Map<String, dynamic> data = jsonDecode(content);
          
          if (data.containsKey('balance')) totalBalance = (data['balance'] as num).toDouble();
          if (data.containsKey('contacts')) contacts = List<String>.from(data['contacts']);
          if (data.containsKey('transactions')) {
            transactions = (data['transactions'] as List).map((e) => Transaction.fromJson(e)).toList();
          }
          if (data.containsKey('tiffin')) {
            var t = data['tiffin'];
            tiffinName = t['name'] ?? "";
            tiffinStartDate = t['start'] != null ? DateTime.parse(t['start']) : null;
            tiffinExceptions = Map<String, String>.from(t['ex']);
            tiffinHistory = List<Map<String, dynamic>>.from(t['hist']);
          }
       }
    } catch(e) {
      debugPrint("Load error: $e");
    }
  }

  void addContact(String name) {
    if (!contacts.contains(name)) {
      contacts.add(name);
      saveData();
    }
  }

  void deleteContact(String name) {
    contacts.remove(name);
    saveData();
  }

  void addTransaction(Transaction txn) {
    transactions.insert(0, txn);
    if (txn.contact == 'Self') {
      totalBalance -= txn.amount; 
    } else {
      if (txn.type == 'give') totalBalance += txn.amount;
      if (txn.type == 'take') totalBalance -= txn.amount;
      if (txn.type == 'paid') totalBalance -= txn.amount;
      if (txn.type == 'got') totalBalance += txn.amount;
    }
    saveData();
  }

  void deleteTransaction(String id) {
    int index = transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final txn = transactions[index];
      if (txn.contact == 'Self') {
        totalBalance += txn.amount; 
      } else {
        if (txn.type == 'give') totalBalance -= txn.amount;
        if (txn.type == 'take') totalBalance += txn.amount;
        if (txn.type == 'paid') totalBalance += txn.amount;
        if (txn.type == 'got') totalBalance -= txn.amount;
      }
      transactions.removeAt(index);
      saveData();
    }
  }

  void setTiffinStart(DateTime date) { tiffinStartDate = date; saveData(); }
  void updateTiffinName(String name) { tiffinName = name; saveData(); }
  
  void toggleTiffinDay(DateTime date) {
    if (tiffinStartDate == null || date.isBefore(DateUtils.dateOnly(tiffinStartDate!))) return;
    String dStr = DateFormat('yyyy-MM-dd').format(date);
    String? current = tiffinExceptions[dStr];
    if (current == null) tiffinExceptions[dStr] = 'half';
    else if (current == 'half') tiffinExceptions[dStr] = 'off';
    else tiffinExceptions.remove(dStr);
    saveData();
  }

  void archiveTiffinMonth() {
    if (tiffinStartDate == null) return;
    var cycle = calculateCycle();
    tiffinHistory.insert(0, {
      'name': tiffinName,
      'start': tiffinStartDate!.toIso8601String(),
      'end': cycle['actualEnd'],
      'ex': jsonDecode(jsonEncode(tiffinExceptions)),
    });
    tiffinName = "";
    tiffinStartDate = null;
    tiffinExceptions = {};
    saveData();
  }

  void deleteTiffinHistoryItem(int index) {
    if (index >= 0 && index < tiffinHistory.length) {
      tiffinHistory.removeAt(index);
      saveData();
    }
  }

  void resetCurrentTiffinData() {
    tiffinName = "";
    tiffinStartDate = null;
    tiffinExceptions = {};
    saveData();
  }

  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    contacts = [];
    transactions = [];
    totalBalance = 0.0;
    tiffinName = "";
    tiffinStartDate = null;
    tiffinExceptions = {};
    tiffinHistory = [];
    lastBackupPath = "Not selected";
    isDark = true;
    primaryColor = Colors.cyan;
    isFirstRun = true;
    hasAskedForFolder = false;
    notifyListeners();
  }

  Future<void> requestPermissionsAndPickFolder(BuildContext context) async {
    await [Permission.storage, Permission.manageExternalStorage].request();
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        lastBackupPath = selectedDirectory;
        saveData(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location: $lastBackupPath")));
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<String> exportBackup() async {
    try {
      String? exportDir = await FilePicker.platform.getDirectoryPath();
      if (exportDir == null) return "Cancelled";

      final data = {
        'balance': totalBalance,
        'contacts': contacts,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'tiffin': {
          'name': tiffinName,
          'start': tiffinStartDate?.toIso8601String(),
          'ex': tiffinExceptions,
          'hist': tiffinHistory
        }
      };

      final file = File('$exportDir/manager_backup.json');
      await file.writeAsString(jsonEncode(data));
      return "Saved to: $exportDir";
    } catch (e) {
      return "Failed: $e";
    }
  }

  Future<String> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) return "Cancelled";

      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      if (data.containsKey('balance')) totalBalance = (data['balance'] as num).toDouble();
      if (data.containsKey('contacts')) contacts = List<String>.from(data['contacts']);
      if (data.containsKey('transactions')) {
        transactions = (data['transactions'] as List).map((e) => Transaction.fromJson(e)).toList();
      }
      
      if (data.containsKey('tiffin')) {
        var t = data['tiffin'];
        tiffinName = t['name'] ?? "";
        tiffinStartDate = t['start'] != null ? DateTime.parse(t['start']) : null;
        tiffinExceptions = Map<String, String>.from(t['ex']);
        tiffinHistory = List<Map<String, dynamic>>.from(t['hist']);
      }
      
      if(file.parent.existsSync()) lastBackupPath = file.parent.path;

      saveData();
      return "Restored!";
    } catch (e) {
      return "Error: $e";
    }
  }

  Map<String, double> getStats() {
    double kharcha = 0, lena = 0, dena = 0;
    Map<String, double> pMap = {};

    for (var t in transactions) {
      if (t.contact == 'Self') {
        kharcha += t.amount;
      } else {
        if (!pMap.containsKey(t.contact)) pMap[t.contact] = 0;
        if (t.type == 'take' || t.type == 'old_take') pMap[t.contact] = pMap[t.contact]! + t.amount;
        if (t.type == 'give' || t.type == 'old_give') pMap[t.contact] = pMap[t.contact]! - t.amount;
        if (t.type == 'paid') pMap[t.contact] = pMap[t.contact]! + t.amount;
        if (t.type == 'got') pMap[t.contact] = pMap[t.contact]! - t.amount;
      }
    }

    pMap.forEach((key, val) {
      if (val > 0) lena += val;
      if (val < 0) dena += val.abs();
    });

    return {'kharcha': kharcha, 'lena': lena, 'dena': dena};
  }

  Map<String, dynamic> calculateCycle() {
    if (tiffinStartDate == null) return {};

    double quota = 0;
    DateTime cursor = DateUtils.dateOnly(tiffinStartDate!);
    DateTime origEnd = cursor.add(const Duration(days: 29));
    String actualEndStr = "";
    double remainder = 0;
    int safety = 0;

    while (quota < 30 && safety < 100) {
      String dStr = DateFormat('yyyy-MM-dd').format(cursor);
      String status = tiffinExceptions[dStr] ?? 'active';

      if (status == 'active') quota += 1;
      if (status == 'half') quota += 0.5;

      if (quota >= 30) {
        actualEndStr = dStr;
        if (quota == 30.5) remainder = 0.5;
      }
      cursor = cursor.add(const Duration(days: 1));
      safety++;
    }

    return {
      'origEnd': DateFormat('yyyy-MM-dd').format(origEnd),
      'actualEnd': actualEndStr,
      'quota': quota,
      'rem': remainder
    };
  }
}

class Transaction {
  final String id;
  final String contact;
  final String type; 
  final double amount;
  final String note;
  final DateTime date;

  Transaction({required this.id, required this.contact, required this.type, required this.amount, required this.note, required this.date});

  Map<String, dynamic> toJson() => { 'id': id, 'contact': contact, 'type': type, 'amount': amount, 'note': note, 'date': date.toIso8601String() };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'], contact: json['contact'], type: json['type'], amount: json['amount'], note: json['note'], date: DateTime.parse(json['date'])
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 1;
  final List<Widget> _screens = [
    const TiffinScreen(),
    const HisabScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    return Scaffold(
      body: SafeArea(child: _screens[_idx]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // Background color yahan set kiya
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Boxy look hatane ke liye
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
        ),
        child: ClipRRect(
          // Child ko cut karne ke liye (Important)
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), 
          child: BottomNavigationBar(
            currentIndex: _idx,
            onTap: (i) => setState(() => _idx = i),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            backgroundColor: Theme.of(context).cardColor, // Yahan bhi same color
            selectedItemColor: provider.primaryColor,
            unselectedItemColor: Colors.grey,
            iconSize: 28,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.bento_rounded), label: 'Tiffin'),
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  const PageHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w800, 
          letterSpacing: 0.5,
          color: Theme.of(context).textTheme.bodyLarge?.color
        ),
      ),
    );
  }
}

// === TIFFIN SCREEN (COMPACT & COLOR FIX) ===
class TiffinScreen extends StatefulWidget {
  const TiffinScreen({super.key});
  @override
  State<TiffinScreen> createState() => _TiffinScreenState();
}

class _TiffinScreenState extends State<TiffinScreen> {
  DateTime _viewMonth = DateTime.now();
  int _historyIndex = -1;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.tiffinName);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if(_nameController.text != provider.tiffinName) {
      _nameController.text = provider.tiffinName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const PageHeader(title: "Tiffin Manager"),
            
            // DROP DOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, 
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _historyIndex,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: [
                    const DropdownMenuItem(value: -1, child: Text("Current Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    ...List.generate(provider.tiffinHistory.length, (index) {
                       final h = provider.tiffinHistory[index];
                       return DropdownMenuItem(value: index, child: Text("${h['name']} (${h['start'].substring(0,10)})", style: const TextStyle(fontSize: 14)));
                    })
                  ],
                  onChanged: (v) {
                    setState(() {
                      _historyIndex = v!;
                      if (v != -1) {
                        _viewMonth = DateTime.parse(provider.tiffinHistory[v]['start']);
                      } else if (provider.tiffinStartDate != null) {
                        _viewMonth = provider.tiffinStartDate!;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_historyIndex == -1) 
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Service Name", isDense: true, prefixIcon: Icon(Icons.restaurant_menu_rounded, size: 20)),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (v) => provider.updateTiffinName(v),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime(2030), initialDate: provider.tiffinStartDate ?? DateTime.now());
                          if (d != null) {
                            provider.setTiffinStart(d);
                            setState(() => _viewMonth = d);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: provider.primaryColor),
                              const SizedBox(width: 10),
                              Text("Start: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              Text(
                                provider.tiffinStartDate == null ? "Select Date" : DateFormat('dd MMM yyyy').format(provider.tiffinStartDate!),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20), 
                  onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                ),
                Text(DateFormat('MMMM yyyy').format(_viewMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20), 
                  onPressed: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1)),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildCalendar(provider),

            const SizedBox(height: 12),
            const Wrap(
              spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
              children: [
                _Tag(col: Colors.blue, txt: "Start"),
                _Tag(col: Colors.green, txt: "Full"),
                _Tag(col: Colors.orange, txt: "Half"),
                _Tag(col: Colors.red, txt: "Off"),
                _Tag(col: Colors.purple, txt: "End"),
              ],
            ),

            const SizedBox(height: 16),
            if (_historyIndex == -1 && provider.tiffinStartDate != null)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () {
                        provider.archiveTiffinMonth();
                        _nameController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved & Reset!")));
                        setState(() => _historyIndex = -1);
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("Complete Month & Reset", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                       showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text("Clear Current Data?"),
                          content: const Text("This will DELETE current progress without saving."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                            TextButton(onPressed: () {
                              provider.resetCurrentTiffinData();
                              _nameController.clear();
                              Navigator.pop(ctx);
                            }, child: const Text("CLEAR ALL", style: TextStyle(color: Colors.red))),
                          ],
                        ));
                    }, 
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    label: const Text("Reset (Delete All)", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              ),
              
            if(_historyIndex != -1)
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton.icon(
                   style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                   onPressed: () {
                      provider.deleteTiffinHistoryItem(_historyIndex);
                      setState(() => _historyIndex = -1);
                   }, 
                   icon: const Icon(Icons.delete_forever, size: 18), 
                   label: const Text("Delete This Record")
                 ),
               )
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(AppProvider provider) {
    DateTime? start;
    Map<String, dynamic> exceptions = {};
    String actualEndStr = "";
    String origEndStr = "";
    double rem = 0;

    if (_historyIndex == -1) {
      start = provider.tiffinStartDate;
      exceptions = provider.tiffinExceptions;
      var cycle = provider.calculateCycle();
      actualEndStr = cycle['actualEnd'] ?? "";
      origEndStr = cycle['origEnd'] ?? "";
      rem = cycle['rem'] ?? 0.0;
    } else {
      final h = provider.tiffinHistory[_historyIndex];
      start = DateTime.parse(h['start']);
      exceptions = h['ex'];
      actualEndStr = h['end'];
    }

    if (start == null) return const SizedBox(height: 80, child: Center(child: Text("Select Start Date above", style: TextStyle(color: Colors.grey))));

    final daysInMonth = DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);
    final firstDayOffset = DateUtils.firstDayOffset(_viewMonth.year, _viewMonth.month, MaterialLocalizations.of(context));
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.1, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: daysInMonth + firstDayOffset,
      itemBuilder: (ctx, i) {
        if (i < firstDayOffset) return const SizedBox();
        final day = i - firstDayOffset + 1;
        final date = DateTime(_viewMonth.year, _viewMonth.month, day);
        final dStr = DateFormat('yyyy-MM-dd').format(date);
        
        Color? bg;
        Color txt = Theme.of(context).textTheme.bodyMedium!.color!;
        Border? border;
        String? status = exceptions[dStr];

        bool isDark = provider.isDark;

        if (DateUtils.isSameDay(date, start)) {
          bg = Colors.blueAccent; txt = Colors.white;
        } else if (dStr == actualEndStr) {
          if (_historyIndex == -1 && rem == 0.5) {
             bg = const Color(0xFFE0B0FF); txt = Colors.black;
          } else {
             bg = Colors.purpleAccent; txt = Colors.white;
          }
        } 
        else if (status == 'off') {
          bg = isDark ? Colors.redAccent.withOpacity(0.5) : Colors.red.shade100;
          txt = isDark ? Colors.redAccent.shade100 : Colors.red.shade900;
        } 
        else if (status == 'half') {
          bg = isDark ? Colors.orangeAccent.withOpacity(0.5) : Colors.orange.shade100;
          txt = isDark ? Colors.orangeAccent.shade100 : Colors.orange.shade900;
        } 
        // --- CUSTOM GREEN COLOR FIX (Neon Mint for Dark Mode) ---
        else if (date.isAfter(start!) && (actualEndStr == "" || dStr.compareTo(actualEndStr) < 0)) {
           // USER REQUESTED: #6bffb2 for Dark Mode
           bg = isDark 
                ? const Color(0xFF6BFFB2).withOpacity(0.5) 
                : Colors.green.shade100;
           
           txt = isDark ? Colors.white : Colors.green.shade900; // Text White in dark mode
        }

        if (dStr == origEndStr) border = Border.all(color: Colors.grey, width: 2);

        return GestureDetector(
          onTap: _historyIndex == -1 ? () => provider.toggleTiffinDay(date) : null,
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: border),
            alignment: Alignment.center,
            child: Text("$day", style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final Color col; final String txt;
  const _Tag({required this.col, required this.txt});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: col)),
      child: Text(txt, style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// === NEW: WALLET BALANCE CARD (COMPACT) ===
class WalletCard extends StatelessWidget {
  const WalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade800, 
            Colors.green.shade700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.green.shade900.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text("TOTAL BALANCE", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${provider.totalBalance.toStringAsFixed(0)}", 
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: IconButton(
                onPressed: () => _showAddMoneyDialog(context, provider),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                tooltip: "Add Funds",
                constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                padding: EdgeInsets.zero,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Add Funds"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount", prefixText: "₹ ", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addMoneyToWallet(double.parse(controller.text));
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Add Amount")
          ),
        ],
      )
    );
  }
}

class HisabScreen extends StatelessWidget {
  const HisabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final stats = provider.getStats();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const PageHeader(title: "Dashboard"),
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                    },
                    icon: Icon(Icons.history_rounded, color: provider.primaryColor, size: 24),
                    tooltip: "Analysis",
                  ),
                )
              ],
            ),
            
            const WalletCard(),

            Row(
              children: [
                _Stat(title: "EXPENSE", val: stats['kharcha']!, col: Colors.orange),
                const SizedBox(width: 8),
                _Stat(title: "RECEIVE", val: stats['lena']!, col: Colors.green),
                const SizedBox(width: 8),
                _Stat(title: "PAY", val: stats['dena']!, col: Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.people_alt_rounded, color: Colors.grey, size: 20),
              ),
              title: const Text("Manage People", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              onTap: () => _showPeopleSheet(context),
            ),
            const SizedBox(height: 16),
            
            const AddTxnForm(),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Transactions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.transactions.length > 15 ? 15 : provider.transactions.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final t = provider.transactions[i];
                Color col;
                IconData ico;
                if(t.contact == 'Self') { col = Colors.orange; ico = Icons.fastfood_rounded; }
                else if(t.type.contains('old')) { col = Colors.grey; ico = Icons.history_rounded; }
                else if(['take', 'paid'].contains(t.type)) { col = Colors.green; ico = Icons.arrow_upward_rounded; }
                else { col = Colors.red; ico = Icons.arrow_downward_rounded; }

                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: col.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(ico, color: col, size: 18),
                    ),
                    title: Text(t.contact, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      "${t.note.isEmpty ? t.type : t.note} • ${DateFormat('d MMM').format(t.date)}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
                    ),
                    trailing: Text("₹${t.amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: col)),
                    onLongPress: () => provider.deleteTransaction(t.id),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _showPeopleSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const PeopleSheet());
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filterType = 'Month'; 
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final filteredList = _getFilteredTransactions(provider.transactions);
    final stats = _calculateStats(filteredList);

    return Scaffold(
      appBar: AppBar(title: const Text("Analysis")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: ['Day', 'Month', 'Year'].map((e) {
                bool isSel = filterType == e;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(e, style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      onSelected: (v) => setState(() => filterType = e),
                      selectedColor: provider.primaryColor,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : null,
                        fontWeight: FontWeight.bold
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left, size: 20), 
                  onPressed: () => _changeDate(-1),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                ),
                InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(_formatDate(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right, size: 20), 
                  onPressed: () => _changeDate(1),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
                ),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HistoryStat("SPENT", stats['kharcha']!, Colors.orange),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _HistoryStat("RECEIVE", stats['lena']!, Colors.green),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _HistoryStat("PAY", stats['dena']!, Colors.red),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: filteredList.isEmpty 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 50, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text("No transactions", style: TextStyle(color: Colors.grey)),
                ],
              )
            : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredList.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final t = filteredList[i];
                Color col;
                if(t.contact == 'Self') col = Colors.orange;
                else if(t.type.contains('old')) col = Colors.grey;
                else if(['take', 'paid'].contains(t.type)) col = Colors.green;
                else col = Colors.red;

                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: CircleAvatar(
                      backgroundColor: col.withOpacity(0.1),
                      radius: 16,
                      child: Icon(t.contact == 'Self' ? Icons.fastfood : Icons.swap_horiz, color: col, size: 16),
                    ),
                    title: Text(t.contact, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      "${t.note.isEmpty ? t.type : t.note} • ${DateFormat('d MMM').format(t.date)}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
                    ),
                    trailing: Text(
                      "₹${t.amount.toStringAsFixed(0)}", 
                      style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14)
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

  Widget _HistoryStat(String label, double val, Color col) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("₹${val.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _changeDate(int offset) {
    setState(() {
      if (filterType == 'Day') {
        selectedDate = selectedDate.add(Duration(days: offset));
      } else if (filterType == 'Month') {
        selectedDate = DateTime(selectedDate.year, selectedDate.month + offset, 1);
      } else {
        selectedDate = DateTime(selectedDate.year + offset, 1, 1);
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: filterType == 'Year' ? DatePickerMode.year : DatePickerMode.day,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  String _formatDate() {
    if (filterType == 'Day') return DateFormat('d MMM yyyy').format(selectedDate);
    if (filterType == 'Month') return DateFormat('MMMM yyyy').format(selectedDate);
    return DateFormat('yyyy').format(selectedDate);
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> all) {
    return all.where((t) {
      if (filterType == 'Day') return DateUtils.isSameDay(t.date, selectedDate);
      else if (filterType == 'Month') return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
      else return t.date.year == selectedDate.year;
    }).toList();
  }

  Map<String, double> _calculateStats(List<Transaction> list) {
    double kharcha = 0, lena = 0, dena = 0;
    for (var t in list) {
      if (t.contact == 'Self') kharcha += t.amount;
      else {
        if (t.type == 'take') lena += t.amount;
        if (t.type == 'give') dena += t.amount;
        if (t.type == 'old_take') lena += t.amount;
        if (t.type == 'old_give') dena += t.amount;
      }
    }
    return {'kharcha': kharcha, 'lena': lena, 'dena': dena};
  }
}

class _Stat extends StatelessWidget {
  final String title; final double val; final Color col;
  const _Stat({required this.title, required this.val, required this.col});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), // Reduced Padding
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(12), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
          border: Border(top: BorderSide(color: col, width: 3))
        ),
        child: Column(children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text("₹${val.toStringAsFixed(0)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col))
        ]),
      ),
    );
  }
}

class AddTxnForm extends StatefulWidget {
  const AddTxnForm({super.key});
  @override
  State<AddTxnForm> createState() => _AddTxnFormState();
}

class _AddTxnFormState extends State<AddTxnForm> {
  String selectedContact = "Self";
  String txnType = "expense";
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.contacts.contains(selectedContact) && selectedContact != 'Self') selectedContact = 'Self';
    final contacts = ["Self", ...provider.contacts];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Entry", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Name Dropdown
            DropdownButtonFormField<String>(
              value: contacts.contains(selectedContact) ? selectedContact : "Self",
              isExpanded: true,
              isDense: true,
              items: contacts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                selectedContact = v!;
                txnType = v == 'Self' ? 'expense' : 'give';
              }),
              decoration: const InputDecoration(labelText: "Who?", prefixIcon: Icon(Icons.person_outline, size: 20)),
            ),
            const SizedBox(height: 10),
            
            if (selectedContact != 'Self')
              DropdownButtonFormField<String>(
                value: txnType,
                isExpanded: true,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'give', child: Text("🔴 Udhar Liya (Dena)")),
                  DropdownMenuItem(value: 'take', child: Text("🟢 Udhar Diya (Lena)")),
                  DropdownMenuItem(value: 'old_give', child: Text("⬜ Purana Baki (Dena)", style: TextStyle(color: Colors.grey))),
                  DropdownMenuItem(value: 'old_take', child: Text("⬜ Purana Baki (Lena)", style: TextStyle(color: Colors.grey))),
                ],
                onChanged: (v) => setState(() => txnType = v!),
                decoration: const InputDecoration(labelText: "Type", prefixIcon: Icon(Icons.swap_horiz, size: 20)),
              ),
            if (selectedContact != 'Self') const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount", prefixText: "₹ "),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(labelText: "Note", prefixIcon: Icon(Icons.edit_note, size: 20)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () {
                  if (_amtCtrl.text.isEmpty) return;
                  provider.addTransaction(Transaction(
                    id: DateTime.now().toString(),
                    contact: selectedContact,
                    type: selectedContact == 'Self' ? 'expense' : txnType,
                    amount: double.parse(_amtCtrl.text),
                    note: _noteCtrl.text,
                    date: DateTime.now(),
                  ));
                  _amtCtrl.clear();
                  _noteCtrl.clear();
                  FocusScope.of(context).unfocus();
                },
                child: const Text("SAVE ENTRY", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PeopleSheet extends StatelessWidget {
  const PeopleSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final controller = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Manage People", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: "New Name", prefixIcon: Icon(Icons.person_add)),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) { if(v.isNotEmpty) { provider.addContact(v); controller.clear(); }},
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.primaryColor,
                    foregroundColor: Colors.white
                  ),
                  onPressed: () { if(controller.text.isNotEmpty) { provider.addContact(controller.text); controller.clear(); }},
                  child: const Text("Add"),
                )
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: provider.contacts.length,
                separatorBuilder: (_,__) => const Divider(height: 1),
                itemBuilder: (ctx, i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
  radius: 16,
  backgroundColor: Colors.grey.withOpacity(0.2), // Halka Grey Background
  child: const Icon(Icons.person, size: 18, color: Colors.grey), // Dark Grey Icon
),
                  title: Text(provider.contacts[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => provider.deleteContact(provider.contacts[i]),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const PageHeader(title: "Settings"),
          
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  secondary: Icon(provider.isDark ? Icons.dark_mode : Icons.light_mode, size: 22),
                  title: const Text("Dark Theme", style: TextStyle(fontSize: 14)),
                  value: provider.isDark, 
                  onChanged: (v) => provider.toggleTheme()
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.color_lens, size: 22),
                  title: const Text("Accent Color", style: TextStyle(fontSize: 14)),
                  trailing: CircleAvatar(backgroundColor: provider.primaryColor, radius: 12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pick Color'),
                        content: SingleChildScrollView(
                          child: HueRingPicker(
                            pickerColor: provider.primaryColor,
                            onColorChanged: (c) => provider.updateThemeColor(c),
                            enableAlpha: false, displayThumbColor: true,
                          ),
                        ),
                        actions: [ElevatedButton(child: const Text('Done'), onPressed: () => Navigator.pop(context))],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  title: const Text("Data Folder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(provider.lastBackupPath, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: TextButton(onPressed: () async => await provider.requestPermissionsAndPickFolder(context), child: const Text("Change")),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.upload_file_rounded, color: Colors.blue, size: 22),
                  title: const Text("Export Backup", style: TextStyle(fontSize: 14)),
                  onTap: () async {
                    String msg = await provider.exportBackup();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.download_rounded, color: Colors.green, size: 22),
                  title: const Text("Restore Data", style: TextStyle(fontSize: 14)),
                  onTap: () async {
                    String msg = await provider.restoreBackup();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  },
                ),
              ],
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                showDialog(
                  context: context, 
                  builder: (ctx) => AlertDialog(
                    title: const Text("Factory Reset?"),
                    content: const Text("This will delete ALL data. This cannot be undone."),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: (){
                          provider.factoryReset();
                          Navigator.pop(ctx);
                        }, child: const Text("RESET APP")),
                    ],
                  )
                );
              },
              icon: const Icon(Icons.warning_rounded, size: 20),
              label: const Text("Factory Reset App"),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}