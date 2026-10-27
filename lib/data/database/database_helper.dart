import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/budget_category.dart';
import '../models/transaction_item.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Create Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        allocated_amount REAL NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    // 2. Create Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Seed Default 8 Budget Categories (Rp4.500.000 total)
    final batch = db.batch();
    for (final category in BudgetCategory.defaultCategories) {
      batch.insert('categories', category.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ================= CATEGORY OPERATIONS =================

  Future<List<BudgetCategory>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'sort_order ASC');
    return result.map((json) => BudgetCategory.fromMap(json)).toList();
  }

  Future<int> updateCategory(BudgetCategory category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> updateCategoryBudget(String id, double newAmount) async {
    final db = await database;
    return await db.update(
      'categories',
      {'allocated_amount': newAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCategory(BudgetCategory category) async {
    final db = await database;
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= TRANSACTION OPERATIONS =================

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    return await db.insert(
      'transactions',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(TransactionItem item) async {
    final db = await database;
    return await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.allocated_amount as category_allocated,
             c.icon_code_point, c.icon_font_family, c.color_value, c.sort_order, c.is_default
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date <= ?
      ORDER BY t.date DESC, t.created_at DESC
    ''', [startDate, endDate]);

    return result.map((row) {
      BudgetCategory? category;
      if (row['category_name'] != null) {
        category = BudgetCategory(
          id: row['category_id'] as String,
          name: row['category_name'] as String,
          allocatedAmount: (row['category_allocated'] as num).toDouble(),
          iconCodePoint: row['icon_code_point'] as int,
          iconFontFamily: row['icon_font_family'] as String?,
          colorValue: row['color_value'] as int,
          sortOrder: (row['sort_order'] as int?) ?? 0,
          isDefault: (row['is_default'] as int?) == 1,
        );
      }
      return TransactionItem.fromMap(row, category: category);
    }).toList();
  }

  Future<Map<String, double>> getSpentPerCategoryForMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total_spent
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY category_id
    ''', [startDate, endDate]);

    final Map<String, double> spentMap = {};
    for (final row in result) {
      final categoryId = row['category_id'] as String;
      final totalSpent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      spentMap[categoryId] = totalSpent;
    }
    return spentMap;
  }

  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.allocated_amount as category_allocated,
             c.icon_code_point, c.icon_font_family, c.color_value, c.sort_order, c.is_default
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC, t.created_at DESC
    ''');

    return result.map((row) {
      BudgetCategory? category;
      if (row['category_name'] != null) {
        category = BudgetCategory(
          id: row['category_id'] as String,
          name: row['category_name'] as String,
          allocatedAmount: (row['category_allocated'] as num).toDouble(),
          iconCodePoint: row['icon_code_point'] as int,
          iconFontFamily: row['icon_font_family'] as String?,
          colorValue: row['color_value'] as int,
        );
      }
      return TransactionItem.fromMap(row, category: category);
    }).toList();
  }

  // ================= BACKUP & RESTORE =================

  Future<void> restoreAllData(
    List<BudgetCategory> categories,
    List<TransactionItem> transactions,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('categories');

      final catBatch = txn.batch();
      for (final cat in categories) {
        catBatch.insert('categories', cat.toMap());
      }
      await catBatch.commit(noResult: true);

      final txBatch = txn.batch();
      for (final tx in transactions) {
        txBatch.insert('transactions', tx.toMap());
      }
      await txBatch.commit(noResult: true);
    });
  }

  Future<void> resetToDefault() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('categories');
      final batch = txn.batch();
      for (final category in BudgetCategory.defaultCategories) {
        batch.insert('categories', category.toMap());
      }
      await batch.commit(noResult: true);
    });
  }
}
