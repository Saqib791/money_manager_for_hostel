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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  List<String> quickNotes = ["🍔 Food", "🍟 Fries", "🥤 Cold Drink", "☕ Tea", "🚌 Travel", "🛒 Grocery", "🎬 Movie"];

  void addQuickNote(String note) {
    if (!quickNotes.contains(note)) {
      quickNotes.add(note);
      saveData();
    }
  }

  void removeQuickNote(String note) {
    quickNotes.remove(note);
    saveData();
  }
  
  String tiffinName = "";
  DateTime? tiffinStartDate;
  int tiffinDietsPerDay = 2;
  int tiffinTotalDays = 30;
  double tiffinPricePerDiet = 0.0;
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
    quickNotes = prefs.getStringList('quickNotes') ?? ["🍔 Food", "🍟 Fries", "🥤 Cold Drink", "☕ Tea/Coffee", "🚌 Travel", "🛒 Grocery", "🎬 Movie", "⛽ Petrol"];
    
    final txnString = prefs.getString('transactions');
    if (txnString != null) {
      final List<dynamic> decoded = jsonDecode(txnString);
      transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
    }

    tiffinName = prefs.getString('tiffinName') ?? "";
    final startStr = prefs.getString('tiffinStartDate');
    if (startStr != null) tiffinStartDate = DateTime.parse(startStr);
    tiffinDietsPerDay = prefs.getInt('tiffinDietsPerDay') ?? 2;
    tiffinTotalDays = prefs.getInt('tiffinTotalDays') ?? 30;
    tiffinPricePerDiet = prefs.getDouble('tiffinPricePerDiet') ?? 0.0;
    
    final exStr = prefs.getString('tiffinExceptions');
    if (exStr != null) tiffinExceptions = Map<String, String>.from(jsonDecode(exStr));
    
    final histStr = prefs.getString('tiffinHistory');
    if (histStr != null) {
      tiffinHistory = List<Map<String, dynamic>>.from(jsonDecode(histStr));
    }

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
    prefs.setStringList('quickNotes', quickNotes);
    
    prefs.setString('transactions', jsonEncode(transactions.map((e) => e.toJson()).toList()));
    
    prefs.setString('tiffinName', tiffinName);
    if(tiffinStartDate != null) prefs.setString('tiffinStartDate', tiffinStartDate!.toIso8601String());
    else prefs.remove('tiffinStartDate');
    prefs.setInt('tiffinDietsPerDay', tiffinDietsPerDay);
    prefs.setInt('tiffinTotalDays', tiffinTotalDays);
    prefs.setDouble('tiffinPricePerDiet', tiffinPricePerDiet);
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
        'quickNotes': quickNotes,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'tiffin': {
          'name': tiffinName,
          'start': tiffinStartDate?.toIso8601String(),
          'dietsPerDay': tiffinDietsPerDay,
          'totalDays': tiffinTotalDays,
          'pricePerDiet': tiffinPricePerDiet,
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
          if (data.containsKey('quickNotes')) quickNotes = List<String>.from(data['quickNotes']);
          if (data.containsKey('transactions')) {
            transactions = (data['transactions'] as List).map((e) => Transaction.fromJson(e)).toList();
          }
          if (data.containsKey('tiffin')) {
            var t = data['tiffin'];
            tiffinName = t['name'] ?? "";
            tiffinStartDate = t['start'] != null ? DateTime.parse(t['start']) : null;
            tiffinDietsPerDay = t['dietsPerDay'] ?? 2;
            tiffinTotalDays = t['totalDays'] ?? 30;
            tiffinPricePerDiet = (t['pricePerDiet'] as num?)?.toDouble() ?? 0.0;
            if (t['ex'] != null) tiffinExceptions = Map<String, String>.from(t['ex']);
            if (t['hist'] != null) tiffinHistory = List<Map<String, dynamic>>.from(t['hist']);
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
    } else if (txn.contact == 'Wallet') {
      if (txn.type == 'add') totalBalance += txn.amount;
      if (txn.type == 'withdraw') totalBalance -= txn.amount;
      if (txn.type == 'edit') totalBalance = txn.amount;
    } else {
      if (txn.type == 'give') totalBalance += txn.amount;
      if (txn.type == 'take') totalBalance -= txn.amount;
      if (txn.type == 'paid') totalBalance -= txn.amount;
      if (txn.type == 'got') totalBalance += txn.amount;
    }
    saveData();
  }

  void editTransactionNote(String id, String newNote, [double? newAmount]) {
    int index = transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final oldTxn = transactions[index];
      
      if (newAmount != null && newAmount != oldTxn.amount) {
        // Revert old balance
        if (oldTxn.contact == 'Self') {
          totalBalance += oldTxn.amount; 
        } else if (oldTxn.contact == 'Wallet') {
          if (oldTxn.type == 'add') totalBalance -= oldTxn.amount;
          if (oldTxn.type == 'withdraw') totalBalance += oldTxn.amount;
        } else {
          if (oldTxn.type == 'give') totalBalance -= oldTxn.amount;
          if (oldTxn.type == 'take') totalBalance += oldTxn.amount;
          if (oldTxn.type == 'paid') totalBalance += oldTxn.amount;
          if (oldTxn.type == 'got') totalBalance -= oldTxn.amount;
        }

        // Apply new balance
        if (oldTxn.contact == 'Self') {
          totalBalance -= newAmount; 
        } else if (oldTxn.contact == 'Wallet') {
          if (oldTxn.type == 'add') totalBalance += newAmount;
          if (oldTxn.type == 'withdraw') totalBalance -= newAmount;
          if (oldTxn.type == 'edit') totalBalance = newAmount;
        } else {
          if (oldTxn.type == 'give') totalBalance += newAmount;
          if (oldTxn.type == 'take') totalBalance -= newAmount;
          if (oldTxn.type == 'paid') totalBalance -= newAmount;
          if (oldTxn.type == 'got') totalBalance += newAmount;
        }
      }

      transactions[index] = Transaction(
        id: oldTxn.id,
        contact: oldTxn.contact,
        type: oldTxn.type,
        amount: newAmount ?? oldTxn.amount,
        note: newNote,
        date: oldTxn.date,
      );
      saveData();
    }
  }

  void deleteTransaction(String id) {
    int index = transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final txn = transactions[index];
      if (txn.contact == 'Self') {
        totalBalance += txn.amount; 
      } else if (txn.contact == 'Wallet') {
        if (txn.type == 'add') totalBalance -= txn.amount;
        if (txn.type == 'withdraw') totalBalance += txn.amount;
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

  void startTiffinPlan(String name, DateTime start, int dietsPerDay, int totalDays, double pricePerDiet) {
    tiffinName = name;
    tiffinStartDate = start;
    tiffinDietsPerDay = dietsPerDay;
    tiffinTotalDays = totalDays;
    tiffinPricePerDiet = pricePerDiet;
    
    double totalCost = dietsPerDay * totalDays * pricePerDiet;
    
    totalBalance -= totalCost;
    
    transactions.insert(0, Transaction(
      id: DateTime.now().toString(),
      contact: 'Self',
      type: 'expense',
      amount: totalCost,
      note: "${dietsPerDay * totalDays} diets from $tiffinName",
      date: DateTime.now()
    ));
    
    saveData();
  }

  void resetCurrentTiffinData() {
    tiffinName = "";
    tiffinStartDate = null;
    tiffinDietsPerDay = 2;
    tiffinTotalDays = 30;
    tiffinPricePerDiet = 0.0;
    tiffinExceptions = {};
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
      'dietsPerDay': tiffinDietsPerDay,
      'totalDays': tiffinTotalDays,
      'pricePerDiet': tiffinPricePerDiet
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

  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    contacts = [];
    transactions = [];
    quickNotes = ["🍔 Food", "🍟 Fries", "🥤 Cold Drink", "☕ Tea/Coffee", "🚌 Travel", "🛒 Grocery", "🎬 Movie", "⛽ Petrol"];
    totalBalance = 0.0;
    tiffinName = "";
    tiffinStartDate = null;
    tiffinDietsPerDay = 2;
    tiffinTotalDays = 30;
    tiffinPricePerDiet = 0.0;
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
        'quickNotes': quickNotes,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'tiffin': {
          'name': tiffinName,
          'start': tiffinStartDate?.toIso8601String(),
          'dietsPerDay': tiffinDietsPerDay,
          'totalDays': tiffinTotalDays,
          'pricePerDiet': tiffinPricePerDiet,
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

  Future<String> exportAsPDF() async {
    try {
      // User se folder select karwayein
      String? exportDir = await FilePicker.platform.getDirectoryPath();
      if (exportDir == null) return "Cancelled";

      final pdf = pw.Document();

      // Helper function: Tiffin ke chhuttiyon (exceptions) ko "04-27 (half)" format me convert karne ke liye
      String formatExceptions(Map<dynamic, dynamic>? exceptions) {
        if (exceptions == null || exceptions.isEmpty) return '';
        List<String> items = [];
        exceptions.forEach((dateStr, status) {
          // dateStr usually 'yyyy-MM-dd' hota hai
          final parts = dateStr.toString().split('-');
          if (parts.length == 3) {
            items.add('${parts[1]}-${parts[2]} ($status)');
          }
        });
        return items.join(', ');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // --- HEADER SECTION ---
              pw.Center(
                child: pw.Text("Financial & Personal Report", 
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text("Generated on: ${DateFormat('d/M/yyyy, h:mm:ss a').format(DateTime.now())}", 
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              ),
              pw.SizedBox(height: 30),

              // --- CURRENT TIFFIN PROVIDER ---
              pw.Text("Current Tiffin Provider", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              if (tiffinName.isNotEmpty)
                pw.TableHelper.fromTextArray(
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headers: ['Provider Name', 'Start Date', 'Current Month Adjustments:'],
                  data: [
                    [
                      tiffinName, 
                      tiffinStartDate != null ? DateFormat('d/M/yyyy').format(tiffinStartDate!) : '', 
                      formatExceptions(tiffinExceptions)
                    ]
                  ],
                )
              else
                pw.Text("No active tiffin plan.", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              pw.SizedBox(height: 30),

              // --- CURRENT BALANCE ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("CURRENT BALANCE", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text("Rs ${totalBalance.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  ]
                )
              ),
              pw.SizedBox(height: 30),

              // --- TIFFIN HISTORY ---
              pw.Text("Tiffin History", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              if (tiffinHistory.isEmpty)
                 pw.Text("No history available.", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
              else
                pw.TableHelper.fromTextArray(
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(4),
                  },
                  headers: ['Provider', 'Period', 'Adjustments'],
                  data: tiffinHistory.map((h) {
                    String start = h['start'] != null ? DateFormat('d/M/yyyy').format(DateTime.parse(h['start'])) : '';
                    String end = (h['end'] != null && h['end'].toString().isNotEmpty) ? h['end'] : 'Ongoing';
                    return [
                      h['name'] ?? '',
                      '$start to $end',
                      formatExceptions(h['ex'])
                    ];
                  }).toList(),
                ),
              pw.SizedBox(height: 30),

              // --- TRANSACTION HISTORY ---
              pw.Text("Transaction History", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              if (transactions.isEmpty)
                pw.Text("No transactions available.", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
              else
                pw.TableHelper.fromTextArray(
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  // Padding kam ki hai taaki box ki height choti ho jaye
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), 
                  
                  // YAHAN ADD KIYA HAI COLUMN WIDTHS
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.7), // DATE
                    1: const pw.FlexColumnWidth(3.5), // NOTE (Isko patla kiya)
                    2: const pw.FlexColumnWidth(0.8), // CONTACT
                    3: const pw.FlexColumnWidth(1.2), // TYPE (Isko chauda kiya)
                    4: const pw.FlexColumnWidth(0.9), // AMOUNT
                  },
                  
                  headers: ['DATE', 'NOTE', 'CONTACT', 'TYPE', 'AMOUNT'],
                  data: transactions.map((t) {
                    return [
                      DateFormat('d/M/yyyy hh:mm a').format(t.date),
                      t.note,
                      t.contact,
                      t.type.toUpperCase(),
                      'Rs ${t.amount.toStringAsFixed(2)}'
                    ];
                  }).toList(),
                ),
            ];
          }
        )
      );
      // File ko format kiye huye naam ke sath save karna
      String fileName = 'Financial_Report_${DateFormat('dd_MMM_yyyy').format(DateTime.now())}.pdf';
      File file = File('$exportDir/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      return "PDF Saved to: $exportDir/$fileName";
    } catch (e) {
      return "Error generating PDF: $e";
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
      if (data.containsKey('quickNotes')) quickNotes = List<String>.from(data['quickNotes']);
      if (data.containsKey('transactions')) {
        transactions = (data['transactions'] as List).map((e) => Transaction.fromJson(e)).toList();
      }
      
      if (data.containsKey('tiffin')) {
        var t = data['tiffin'];
        tiffinName = t['name'] ?? "";
        tiffinStartDate = t['start'] != null ? DateTime.parse(t['start']) : null;
        tiffinDietsPerDay = t['dietsPerDay'] ?? 2;
        tiffinTotalDays = t['totalDays'] ?? 30;
        tiffinPricePerDiet = (t['pricePerDiet'] as num?)?.toDouble() ?? 0.0;
        if (t['ex'] != null) tiffinExceptions = Map<String, String>.from(t['ex']);
        if (t['hist'] != null) tiffinHistory = List<Map<String, dynamic>>.from(t['hist']);
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
      } else if (t.contact == 'Wallet') {
        // ignore for stats
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

  void toggleTiffinDay(DateTime date) {
    if (tiffinStartDate == null || date.isBefore(DateUtils.dateOnly(tiffinStartDate!))) return;
    String dStr = DateFormat('yyyy-MM-dd').format(date);
    String? current = tiffinExceptions[dStr];
    if (tiffinDietsPerDay == 2) {
      if (current == null) tiffinExceptions[dStr] = 'half';
      else if (current == 'half') tiffinExceptions[dStr] = 'off';
      else tiffinExceptions.remove(dStr);
    } else {
      if (current == null) tiffinExceptions[dStr] = 'off';
      else tiffinExceptions.remove(dStr);
    }
    saveData();
  }

  Map<String, dynamic> calculateCycle() {
    if (tiffinStartDate == null) return {};

    double quota = 0;
    double consumedQuota = 0;
    double targetQuota = tiffinTotalDays.toDouble();
    
    DateTime cursor = DateUtils.dateOnly(tiffinStartDate!);
    DateTime origEnd = cursor.add(Duration(days: tiffinTotalDays - 1));
    DateTime today = DateUtils.dateOnly(DateTime.now());
    
    String actualEndStr = "";
    double remainder = 0;
    int safety = 0;

    while (quota < targetQuota && safety < 365) {
      String dStr = DateFormat('yyyy-MM-dd').format(cursor);
      String status = tiffinExceptions[dStr] ?? 'active';

      double dayQuota = 0;
      if (status == 'active') dayQuota = 1;
      else if (status == 'half') dayQuota = 0.5;

      quota += dayQuota;
      
      if (cursor.isBefore(today) || DateUtils.isSameDay(cursor, today)) {
        consumedQuota += dayQuota;
      }
      
      if (quota >= targetQuota && actualEndStr.isEmpty) {
        actualEndStr = dStr;
        if (quota > targetQuota) remainder = 0.5;
      }
      cursor = cursor.add(const Duration(days: 1));
      safety++;
    }

    return {
      'origEnd': DateFormat('yyyy-MM-dd').format(origEnd),
      'actualEnd': actualEndStr,
      'quota': quota, // The full quota (should equal targetQuota)
      'consumedQuota': consumedQuota, // Quota up to today
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

// === TIFFIN SCREEN (SUBSCRIPTION TRACKER) ===
class TiffinScreen extends StatefulWidget {
  const TiffinScreen({super.key});
  @override
  State<TiffinScreen> createState() => _TiffinScreenState();
}

class _TiffinScreenState extends State<TiffinScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _daysController = TextEditingController(text: "30");
  int _dietsPerDay = 2;
  DateTime _startDate = DateTime.now();
  DateTime _viewMonth = DateTime.now();
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.tiffinStartDate != null) {
      _viewMonth = provider.tiffinStartDate!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _daysController.dispose();
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
            
            // HISTORY DROPDOWN
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
            
            if (_historyIndex == -1 && provider.tiffinStartDate == null)
              _buildSetupForm(context, provider)
            else if (_historyIndex == -1 && provider.tiffinStartDate != null)
              _buildProgressUI(context, provider, false)
            else
              _buildProgressUI(context, provider, true),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm(BuildContext context, AppProvider provider) {
    int days = int.tryParse(_daysController.text) ?? 30;
    double price = double.tryParse(_priceController.text) ?? 0.0;
    double totalCost = _dietsPerDay * days * price;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Setup New Tiffin Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Provider Name (e.g., Aunty Tiffin)", prefixIcon: Icon(Icons.restaurant_menu_rounded)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Total Days", prefixIcon: Icon(Icons.calendar_view_day_rounded)),
                    onChanged: (v) => setState((){}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).inputDecorationTheme.enabledBorder!.borderSide.color)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _dietsPerDay,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("1 Diet/Day")),
                          DropdownMenuItem(value: 2, child: Text("2 Diets/Day")),
                        ],
                        onChanged: (v) => setState(() => _dietsPerDay = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price per Diet (₹)", prefixIcon: Icon(Icons.currency_rupee_rounded)),
              onChanged: (v) => setState((){}),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime(2030), initialDate: _startDate);
                if (d != null) setState(() => _startDate = d);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: provider.primaryColor),
                    const SizedBox(width: 10),
                    Text("Start Date: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    Text(
                      DateFormat('dd MMM yyyy').format(_startDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: provider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: provider.primaryColor.withOpacity(0.3))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Calculated Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₹${totalCost.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: provider.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: provider.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter provider name")));
                    return;
                  }
                  if (days <= 0 || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter valid days and price")));
                    return;
                  }
                  provider.startTiffinPlan(_nameController.text.trim(), _startDate, _dietsPerDay, days, price);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tiffin Started! Cost deducted from balance.")));
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text("Start Tiffin & Pay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressUI(BuildContext context, AppProvider provider, bool isHistory) {
    String tName = provider.tiffinName;
    DateTime? tStart = provider.tiffinStartDate;
    int tDiets = provider.tiffinDietsPerDay;
    int tDays = provider.tiffinTotalDays;
    double tPrice = provider.tiffinPricePerDiet;
    double consumedQuota = 0;

    if (isHistory && _historyIndex != -1) {
      final h = provider.tiffinHistory[_historyIndex];
      tName = h['name'] ?? "";
      tStart = DateTime.parse(h['start']);
      tDiets = h['dietsPerDay'] ?? 2;
      tDays = h['totalDays'] ?? 30;
      tPrice = (h['pricePerDiet'] as num?)?.toDouble() ?? 0.0;
      consumedQuota = tDays.toDouble(); // fully consumed for history
    } else {
      var cycle = provider.calculateCycle();
      consumedQuota = cycle['consumedQuota'] ?? 0.0;
    }
    
    // Ensure we don't go over 100% just in case
    if (consumedQuota > tDays) consumedQuota = tDays.toDouble();
    
    double progress = tDays > 0 ? consumedQuota / tDays : 0;
    
    double totalCost = tDiets * tDays * tPrice;
    double consumedCost = tDiets * consumedQuota * tPrice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: provider.primaryColor.withOpacity(0.2), child: Icon(Icons.restaurant, color: provider.primaryColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Started: ${DateFormat('dd MMM yyyy').format(tStart!)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: provider.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text("$tDiets Diets/Day", style: TextStyle(color: provider.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Days Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${consumedQuota.toStringAsFixed(consumedQuota.truncateToDouble() == consumedQuota ? 0 : 1)} / $tDays Days", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                color: provider.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        const Text("Consumed", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("₹${consumedCost.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        const Text("Total Paid", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("₹${totalCost.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["S", "M", "T", "W", "T", "F", "S"].map((day) => 
                Expanded(child: Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))))
              ).toList(),
            ),
            const SizedBox(height: 4),

            _buildCalendar(provider, isHistory),

            const SizedBox(height: 12),
            const Center(
              child: Wrap(
                spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
                children: [
                  _Tag(col: Colors.green, txt: "Active"),
                  _Tag(col: Colors.orange, txt: "Half"),
                  _Tag(col: Colors.red, txt: "Off"),
                  _Tag(col: Colors.purple, txt: "End"),
                ],
              ),
            ),

            const SizedBox(height: 24),
           if (isHistory)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  onPressed: () {
                    showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete Record?"),
                        content: const Text("Are you sure you want to delete this history record? This action cannot be undone."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx), 
                            child: const Text("Cancel")
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteTiffinHistoryItem(_historyIndex);
                              setState(() => _historyIndex = -1);
                              Navigator.pop(ctx); // Close the dialog
                              
                              // Optional: Show a little confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Record deleted successfully!"))
                              );
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red))
                          ),
                        ],
                      )
                    );
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete This Record"),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: provider.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        provider.archiveTiffinMonth();
                        setState(() => _historyIndex = -1);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Month completed and saved to history!")));
                      },
                      icon: const Icon(Icons.archive_rounded),
                      label: const Text("Complete Month & Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(context: context, builder: (ctx) => AlertDialog(
                        title: const Text("End Tiffin Plan Early?"),
                        content: const Text("This will clear the current plan without saving to history. No money will be refunded automatically to your wallet. Are you sure?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              provider.resetCurrentTiffinData();
                              Navigator.pop(ctx);
                            },
                            child: const Text("End Plan", style: TextStyle(color: Colors.red))
                          ),
                        ],
                      ));
                    },
                    icon: const Icon(Icons.stop_circle_rounded, color: Colors.red),
                    label: const Text("End Tiffin Plan Early", style: TextStyle(color: Colors.red)),
                  )
                ]
              )
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(AppProvider provider, bool isHistory) {
    DateTime? start;
    Map<String, dynamic> exceptions = {};
    String actualEndStr = "";
    String origEndStr = "";
    double rem = 0.0;

    if (isHistory && _historyIndex != -1) {
      final h = provider.tiffinHistory[_historyIndex];
      start = DateTime.parse(h['start']);
      exceptions = h['ex'] ?? {};
      actualEndStr = h['end'] ?? "";
      int tDays = h['totalDays'] ?? 30;
      origEndStr = DateFormat('yyyy-MM-dd').format(DateUtils.dateOnly(start).add(Duration(days: tDays - 1)));
    } else {
      if (provider.tiffinStartDate == null) return const SizedBox();
      start = provider.tiffinStartDate;
      exceptions = provider.tiffinExceptions;
      var cycle = provider.calculateCycle();
      actualEndStr = cycle['actualEnd'] ?? "";
      origEndStr = cycle['origEnd'] ?? "";
      rem = cycle['rem'] ?? 0.0;
    }
    
    if (start == null) return const SizedBox();

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

        if (dStr == actualEndStr) {
          if (rem == 0.5) {
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
        // Updated to include the start date in the active (green) section
        else if ((date.isAfter(start!) || DateUtils.isSameDay(date, start!)) && (actualEndStr == "" || dStr.compareTo(actualEndStr) < 0)) {
           bg = isDark 
                ? const Color(0xFF6BFFB2).withOpacity(0.5) 
                : Colors.green.shade100;
           
           txt = isDark ? Colors.white : Colors.green.shade900; 
        }

        if (dStr == origEndStr) border = Border.all(color: Colors.grey, width: 2);

        return GestureDetector(
          onTap: isHistory ? null : () => provider.toggleTiffinDay(date),
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), 
                shape: BoxShape.circle
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                tooltip: "Manage Balance",
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Theme.of(context).cardColor,
                onSelected: (String type) {
                  _showWalletDialog(context, provider, type);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 20, color: Colors.green),
                        SizedBox(width: 10),
                        Text('Add Balance'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'withdraw',
                    child: Row(
                      children: [
                        Icon(Icons.remove_rounded, size: 20, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('Withdraw Balance'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Edit Balance'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, AppProvider provider, IconData icon, String tooltip, String type) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
      child: IconButton(
        onPressed: () => _showWalletDialog(context, provider, type),
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showWalletDialog(BuildContext context, AppProvider provider, String type) {
    final controller = TextEditingController();
    String title = type == 'add' ? "Add Balance" : type == 'withdraw' ? "Withdraw Balance" : "Edit Balance";
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
                provider.addTransaction(Transaction(
                  id: DateTime.now().toString(),
                  contact: 'Wallet',
                  type: type,
                  amount: double.parse(controller.text),
                  note: type == 'add' ? 'Added funds' : type == 'withdraw' ? 'Withdrew funds' : 'Edited balance',
                  date: DateTime.now(),
                ));
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Save")
          ),
        ],
      )
    );
  }
}

void _showTxnOptionsDialog(BuildContext context, AppProvider provider, Transaction t) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Options"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(ctx);
                final noteCtrl = TextEditingController(text: t.note);
                final amtCtrl = TextEditingController(text: t.amount.toStringAsFixed(0));
                showDialog(
                  context: context,
                  builder: (editCtx) => AlertDialog(
                    title: const Text("Edit Transaction"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: amtCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Amount", prefixText: "₹ "),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteCtrl,
                          decoration: const InputDecoration(labelText: "Note"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(editCtx), child: const Text("Cancel")),
                      FilledButton(
                        onPressed: () {
                          double? newAmt = double.tryParse(amtCtrl.text);
                          if (newAmt != null) {
                            provider.editTransactionNote(t.id, noteCtrl.text.trim(), newAmt);
                            Navigator.pop(editCtx);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () {
                provider.deleteTransaction(t.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    },
  );
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showSearch(context: context, delegate: TransactionSearchDelegate(provider));
                        },
                        icon: Icon(Icons.search_rounded, color: provider.primaryColor, size: 24),
                        tooltip: "Search",
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                        },
                        icon: Icon(Icons.history_rounded, color: provider.primaryColor, size: 24),
                        tooltip: "Analysis",
                      ),
                    ],
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
              itemCount: provider.transactions.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final t = provider.transactions[i];
                Color col;
                IconData ico;
                if(t.contact == 'Wallet') {
                  col = Colors.blue; 
                  ico = t.type == 'add' ? Icons.account_balance_wallet : t.type == 'withdraw' ? Icons.money_off : Icons.edit; 
                }
                else if(t.contact == 'Self') { col = Colors.orange; ico = Icons.fastfood_rounded; }
                else if(t.type == 'paid') { col = Colors.purple; ico = Icons.done_all_rounded; }
                else if(t.type == 'got') { col = Colors.teal; ico = Icons.done_all_rounded; }
                else if(t.type.contains('old')) { col = Colors.grey; ico = Icons.history_rounded; }
                else if(t.type == 'take') { col = Colors.green; ico = Icons.arrow_upward_rounded; }
                else { col = Colors.red; ico = Icons.arrow_downward_rounded; }

                String typeStr = t.type;
                if (t.type == 'give') typeStr = 'Udhar Liya';
                else if (t.type == 'take') typeStr = 'Udhar Diya';
                else if (t.type == 'paid') typeStr = 'I Paid';
                else if (t.type == 'got') typeStr = 'Got Paid';
                else if (t.contact == 'Self') typeStr = '';

                String noteDisplay = t.note.isEmpty ? typeStr : typeStr.isEmpty ? t.note : "${t.note} ($typeStr)";
                if (noteDisplay.isEmpty) noteDisplay = DateFormat('d MMM').format(t.date);
                else noteDisplay = "$noteDisplay • ${DateFormat('d MMM').format(t.date)}";

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
                      noteDisplay,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
                    ),
                    trailing: Text("₹${t.amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: col)),
                    onLongPress: () => _showTxnOptionsDialog(context, provider, t),
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
                IconData ico;
                if(t.contact == 'Wallet') {
                  col = Colors.blue;
                  ico = t.type == 'add' ? Icons.account_balance_wallet : t.type == 'withdraw' ? Icons.money_off : Icons.edit;
                }
                else if(t.contact == 'Self') { col = Colors.orange; ico = Icons.fastfood_rounded; }
                else if(t.type == 'paid') { col = Colors.purple; ico = Icons.done_all_rounded; }
                else if(t.type == 'got') { col = Colors.teal; ico = Icons.done_all_rounded; }
                else if(t.type.contains('old')) { col = Colors.grey; ico = Icons.history_rounded; }
                else if(t.type == 'take') { col = Colors.green; ico = Icons.arrow_upward_rounded; }
                else { col = Colors.red; ico = Icons.arrow_downward_rounded; }

                String typeStr = t.type;
                if (t.type == 'give') typeStr = 'Udhar Liya';
                else if (t.type == 'take') typeStr = 'Udhar Diya';
                else if (t.type == 'paid') typeStr = 'I Paid';
                else if (t.type == 'got') typeStr = 'Got Paid';
                else if (t.contact == 'Self') typeStr = '';

                String noteDisplay = t.note.isEmpty ? typeStr : typeStr.isEmpty ? t.note : "${t.note} ($typeStr)";
                if (noteDisplay.isEmpty) noteDisplay = DateFormat('d MMM').format(t.date);
                else noteDisplay = "$noteDisplay • ${DateFormat('d MMM').format(t.date)}";

                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: CircleAvatar(
                      backgroundColor: col.withOpacity(0.1),
                      radius: 16,
                      child: Icon(ico, color: col, size: 16),
                    ),
                    title: Text(t.contact, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      noteDisplay,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
                    ),
                    trailing: Text(
                      "₹${t.amount.toStringAsFixed(0)}", 
                      style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    onLongPress: () => _showTxnOptionsDialog(context, provider, t),
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
      else if (t.contact == 'Wallet') {} // ignore
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

  Widget _buildQuickNoteChip(BuildContext context, AppProvider provider, String text) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_noteCtrl.text.trim().isEmpty) {
            _noteCtrl.text = text;
          } else {
            _noteCtrl.text = "${_noteCtrl.text.trim()}, $text";
          }
          _noteCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _noteCtrl.text.length));
        });
      },
      onLongPress: () {
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Quick Note?"),
            content: Text("Remove '$text'?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  provider.removeQuickNote(text);
                  Navigator.pop(ctx);
                }, 
                child: const Text("Delete", style: TextStyle(color: Colors.red))
              ),
            ]
          )
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildAddQuickNoteChip(BuildContext context, AppProvider provider) {
    return InkWell(
      onTap: () {
        final ctrl = TextEditingController();
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: const Text("Add Quick Note"),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: "Note (e.g., 🍕 Pizza)", border: OutlineInputBorder()),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              FilledButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    provider.addQuickNote(ctrl.text.trim());
                    Navigator.pop(ctx);
                  }
                }, 
                child: const Text("Add")
              ),
            ]
          )
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: provider.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: provider.primaryColor.withOpacity(0.5)),
        ),
        child: Icon(Icons.add, size: 16, color: provider.primaryColor),
      ),
    );
  }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contacts.contains(selectedContact) ? selectedContact : "Self",
                    isExpanded: true,
                    isDense: true,
                    items: contacts.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() {
                      selectedContact = v!;
                      txnType = v == 'Self' ? 'expense' : 'give';
                    }),
                    decoration: const InputDecoration(labelText: "Who?", prefixIcon: Icon(Icons.person_outline, size: 20)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  padding: const EdgeInsets.all(14),
                  icon: const Icon(Icons.people_alt_rounded),
                  tooltip: "Manage People",
                  onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const PeopleSheet()),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            if (selectedContact != 'Self')
              DropdownButtonFormField<String>(
                value: txnType,
                isExpanded: true,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'give', child: Text("🔴 Udhar Liya (Dena)", overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'take', child: Text("🟢 Udhar Diya (Lena)", overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'paid', child: Text("✅ Maine Udhar Chukadiya (I Paid)", overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'got', child: Text("✅ Usne Udhar Chukadiya (Got Paid)", overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => txnType = v!),
                decoration: const InputDecoration(labelText: "Type", prefixIcon: Icon(Icons.swap_horiz, size: 20)),
              ),
            if (selectedContact != 'Self') const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount", prefixText: "₹ "),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(labelText: "Note", prefixIcon: Icon(Icons.edit_note, size: 20)),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...provider.quickNotes.map((note) => _buildQuickNoteChip(context, provider, note)),
                  _buildAddQuickNoteChip(context, provider),
                ],
              ),
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
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22),
                  title: const Text("Export as PDF", style: TextStyle(fontSize: 14)),
                  subtitle: const Text("Generate Tiffin & Expense report", style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating PDF... Please wait")));
                    String msg = await provider.exportAsPDF();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
                  },
                ),
                const Divider(height: 1), 

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

class TransactionSearchDelegate extends SearchDelegate<String> {
  final AppProvider provider;

  TransactionSearchDelegate(this.provider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final list = provider.transactions.where((t) {
      return t.contact.toLowerCase().contains(query.toLowerCase()) || 
             t.note.toLowerCase().contains(query.toLowerCase()) || 
             t.amount.toString().contains(query);
    }).toList();

    if (list.isEmpty) {
      return const Center(child: Text("No transactions found", style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final t = list[i];
        Color col;
        IconData ico;
        if(t.contact == 'Wallet') {
          col = Colors.blue; 
          ico = t.type == 'add' ? Icons.account_balance_wallet : t.type == 'withdraw' ? Icons.money_off : Icons.edit; 
        }
        else if(t.contact == 'Self') { col = Colors.orange; ico = Icons.fastfood_rounded; }
        else if(t.type == 'paid') { col = Colors.purple; ico = Icons.done_all_rounded; }
        else if(t.type == 'got') { col = Colors.teal; ico = Icons.done_all_rounded; }
        else if(t.type.contains('old')) { col = Colors.grey; ico = Icons.history_rounded; }
        else if(t.type == 'take') { col = Colors.green; ico = Icons.arrow_upward_rounded; }
        else { col = Colors.red; ico = Icons.arrow_downward_rounded; }

        String typeStr = t.type;
        if (t.type == 'give') typeStr = 'Udhar Liya';
        else if (t.type == 'take') typeStr = 'Udhar Diya';
        else if (t.type == 'paid') typeStr = 'I Paid';
        else if (t.type == 'got') typeStr = 'Got Paid';
        else if (t.contact == 'Self') typeStr = '';

        String noteDisplay = t.note.isEmpty ? typeStr : typeStr.isEmpty ? t.note : "${t.note} ($typeStr)";
        if (noteDisplay.isEmpty) noteDisplay = DateFormat('d MMM').format(t.date);
        else noteDisplay = "$noteDisplay • ${DateFormat('d MMM').format(t.date)}";

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: CircleAvatar(
              backgroundColor: col.withOpacity(0.1),
              radius: 16,
              child: Icon(ico, color: col, size: 16),
            ),
            title: Text(t.contact, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              noteDisplay,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
            ),
            trailing: Text("₹${t.amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: col)),
          ),
        );
      },
    );
  }
}