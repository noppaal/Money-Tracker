import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/budget_category.dart';
import '../models/transaction_item.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Exports all data as JSON and triggers the Android share sheet to save or send file
  Future<String?> exportBackup() async {
    try {
      final categories = await _dbHelper.getAllCategories();
      final transactions = await _dbHelper.getAllTransactions();

      final backupData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Write to temp file for sharing
      final directory = await getTemporaryDirectory();
      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'moneytracker_backup_$timeStamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Trigger system share
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Cadangan Data MoneyTracker ($timeStamp)',
        text: 'File cadangan data transaksi MoneyTracker',
      );

      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Picks a JSON backup file and restores the database
  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return false; // User cancelled
      }

      final path = result.files.single.path;
      if (path == null) return false;

      final file = File(path);
      final content = await file.readAsString();
      return await restoreFromJson(content);
    } catch (e) {
      rethrow;
    }
  }

  /// Restores database from raw JSON string with validation
  Future<bool> restoreFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (!data.containsKey('categories') || !data.containsKey('transactions')) {
        throw const FormatException('Format file cadangan tidak valid: Kunci tidak cocok');
      }

      final categoriesList = (data['categories'] as List)
          .map((item) => BudgetCategory.fromMap(item as Map<String, dynamic>))
          .toList();

      final transactionsList = (data['transactions'] as List)
          .map((item) => TransactionItem.fromMap(item as Map<String, dynamic>))
          .toList();

      await _dbHelper.restoreAllData(categoriesList, transactionsList);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
