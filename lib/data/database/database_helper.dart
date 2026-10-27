import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_platform.dart';
import '../models/budget_category.dart';
import '../models/transaction_item.dart';
import '../models/wallet.dart';
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
    initPlatformDatabase();

    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    Database db;
    try {
      db = await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _createDB,
      );
    } catch (e) {
      if (kIsWeb) {
        db = await openDatabase(
          inMemoryDatabasePath,
          version: AppConstants.dbVersion,
          onCreate: _createDB,
        );
      } else {
        rethrow;
      }
    }

    // Ensure wallets, categories, and transactions schemas are up to date
    try {
      await _ensureSchemaUpToDate(db);
    } catch (e) {
      debugPrint('Schema update warning: $e');
    }

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Create Wallets Table
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        initial_balance REAL NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    // 2. Create Categories Table (Supports both expense and income)
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        allocated_amount REAL NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    // 3. Create Transactions Table (Supports both expense and income)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        wallet_id TEXT NOT NULL DEFAULT 'wallet_cash',
        type TEXT NOT NULL DEFAULT 'expense',
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');

    // 4. Seed Default Wallets
    final walletBatch = db.batch();
    for (final wallet in Wallet.defaultWallets) {
      walletBatch.insert('wallets', wallet.toMap());
    }
    await walletBatch.commit(noResult: true);

    // 5. Seed Default Expense Categories (Rp4.500.000 total)
    final catBatch = db.batch();
    for (final category in BudgetCategory.defaultCategories) {
      catBatch.insert('categories', category.toMap());
    }
    // 6. Seed Default Income Categories
    for (final incCategory in BudgetCategory.defaultIncomeCategories) {
      catBatch.insert('categories', incCategory.toMap());
    }
    await catBatch.commit(noResult: true);
  }

  Future<void> _ensureSchemaUpToDate(Database db) async {
    // 1. Create wallets table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        initial_balance REAL NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_default INTEGER NOT NULL
      )
    ''');

    // 2. Seed default wallets if empty
    final countWallets = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM wallets'),
    ) ?? 0;
    if (countWallets == 0) {
      final batch = db.batch();
      for (final w in Wallet.defaultWallets) {
        batch.insert('wallets', w.toMap());
      }
      await batch.commit(noResult: true);
    }

    // 3. Ensure wallet_id column in transactions exists
    try {
      await db.execute("ALTER TABLE transactions ADD COLUMN wallet_id TEXT DEFAULT 'wallet_cash'");
    } catch (_) {}

    // 4. Ensure type column in transactions exists
    try {
      await db.execute("ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT 'expense'");
    } catch (_) {}

    // 5. Ensure type column in categories exists
    try {
      await db.execute("ALTER TABLE categories ADD COLUMN type TEXT DEFAULT 'expense'");
    } catch (_) {}

    // 6. Seed default income categories if not yet in database
    try {
      final incomeCount = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM categories WHERE type = 'income'"),
      ) ?? 0;

      if (incomeCount == 0) {
        final batch = db.batch();
        for (final cat in BudgetCategory.defaultIncomeCategories) {
          batch.insert(
            'categories',
            cat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {}
  }

  // ================= WALLET OPERATIONS =================

  Future<List<Wallet>> getAllWallets() async {
    final db = await database;
    final walletsResult = await db.query('wallets', orderBy: 'is_default DESC, created_at ASC');

    // Calculate total spent and total income per wallet
    final statsResult = await db.rawQuery('''
      SELECT wallet_id,
             SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
             SUM(CASE WHEN type != 'income' THEN amount ELSE 0 END) as total_spent
      FROM transactions
      GROUP BY wallet_id
    ''');

    final Map<String, double> spentMap = {};
    final Map<String, double> incomeMap = {};
    for (final row in statsResult) {
      final wId = row['wallet_id'] as String? ?? 'wallet_cash';
      spentMap[wId] = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      incomeMap[wId] = (row['total_income'] as num?)?.toDouble() ?? 0.0;
    }

    return walletsResult.map((map) {
      final id = map['id'] as String;
      final spent = spentMap[id] ?? 0.0;
      final income = incomeMap[id] ?? 0.0;
      return Wallet.fromMap(map, spent: spent, income: income);
    }).toList();
  }

  Future<int> insertWallet(Wallet wallet) async {
    final db = await database;
    return await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateWallet(Wallet wallet) async {
    final db = await database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<int> deleteWallet(String id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final defaultWallet = await txn.query(
        'wallets',
        where: 'id != ?',
        orderBy: 'is_default DESC, created_at ASC',
        limit: 1,
      );

      final fallbackWalletId = defaultWallet.isNotEmpty
          ? (defaultWallet.first['id'] as String)
          : 'wallet_cash';

      await txn.update(
        'transactions',
        {'wallet_id': fallbackWalletId},
        where: 'wallet_id = ?',
        whereArgs: [id],
      );

      return await txn.delete(
        'wallets',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ================= CATEGORY OPERATIONS =================

  Future<List<BudgetCategory>> getAllCategories({String? type}) async {
    final db = await database;
    final List<Map<String, dynamic>> result;
    if (type != null && type.isNotEmpty && type != 'all') {
      result = await db.query(
        'categories',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'sort_order ASC',
      );
    } else {
      result = await db.query('categories', orderBy: 'sort_order ASC');
    }
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

  Future<List<TransactionItem>> getTransactionsForMonth(
    int year,
    int month, {
    String? walletId,
    String? type,
  }) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    String whereClause = 't.date >= ? AND t.date <= ?';
    List<dynamic> whereArgs = [startDate, endDate];

    if (walletId != null && walletId.isNotEmpty && walletId != 'all') {
      whereClause += ' AND t.wallet_id = ?';
      whereArgs.add(walletId);
    }

    if (type != null && type.isNotEmpty && type != 'all') {
      whereClause += ' AND t.type = ?';
      whereArgs.add(type);
    }

    final result = await db.rawQuery('''
      SELECT t.*, 
             c.name as category_name, c.type as category_type, c.allocated_amount as category_allocated,
             c.icon_code_point as category_icon, c.icon_font_family as category_font,
             c.color_value as category_color, c.sort_order as category_sort, c.is_default as category_default,
             w.name as wallet_name, w.initial_balance as wallet_initial,
             w.icon_code_point as wallet_icon, w.color_value as wallet_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE $whereClause
      ORDER BY t.date DESC, t.created_at DESC
    ''', whereArgs);

    return result.map((row) {
      BudgetCategory? category;
      if (row['category_name'] != null) {
        category = BudgetCategory(
          id: row['category_id'] as String,
          name: row['category_name'] as String,
          type: (row['category_type'] as String?) ?? 'expense',
          allocatedAmount: (row['category_allocated'] as num?)?.toDouble() ?? 0.0,
          iconCodePoint: (row['category_icon'] as int?) ?? 0,
          iconFontFamily: row['category_font'] as String?,
          colorValue: (row['category_color'] as int?) ?? 0,
          sortOrder: (row['category_sort'] as int?) ?? 0,
          isDefault: (row['category_default'] as int?) == 1,
        );
      }

      Wallet? wallet;
      if (row['wallet_name'] != null) {
        wallet = Wallet(
          id: (row['wallet_id'] as String?) ?? 'wallet_cash',
          name: row['wallet_name'] as String,
          initialBalance: (row['wallet_initial'] as num?)?.toDouble() ?? 0.0,
          iconCodePoint: (row['wallet_icon'] as int?) ?? 0,
          colorValue: (row['wallet_color'] as int?) ?? 0,
          createdAt: DateTime.now(),
        );
      }

      return TransactionItem.fromMap(row, category: category, wallet: wallet);
    }).toList();
  }

  Future<Map<String, double>> getSpentPerCategoryForMonth(
    int year,
    int month, {
    String? walletId,
  }) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    String whereClause = "date >= ? AND date <= ? AND (type != 'income' OR type IS NULL)";
    List<dynamic> whereArgs = [startDate, endDate];

    if (walletId != null && walletId.isNotEmpty && walletId != 'all') {
      whereClause += ' AND wallet_id = ?';
      whereArgs.add(walletId);
    }

    final result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total_spent
      FROM transactions
      WHERE $whereClause
      GROUP BY category_id
    ''', whereArgs);

    final Map<String, double> spentMap = {};
    for (final row in result) {
      final categoryId = row['category_id'] as String;
      final totalSpent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      spentMap[categoryId] = totalSpent;
    }

    return spentMap;
  }

  Future<Map<String, double>> getIncomePerCategoryForMonth(
    int year,
    int month, {
    String? walletId,
  }) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    String whereClause = "date >= ? AND date <= ? AND type = 'income'";
    List<dynamic> whereArgs = [startDate, endDate];

    if (walletId != null && walletId.isNotEmpty && walletId != 'all') {
      whereClause += ' AND wallet_id = ?';
      whereArgs.add(walletId);
    }

    final result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total_income
      FROM transactions
      WHERE $whereClause
      GROUP BY category_id
    ''', whereArgs);

    final Map<String, double> incomeMap = {};
    for (final row in result) {
      final categoryId = row['category_id'] as String;
      final totalIncome = (row['total_income'] as num?)?.toDouble() ?? 0.0;
      incomeMap[categoryId] = totalIncome;
    }

    return incomeMap;
  }

  Future<List<TransactionItem>> getAllTransactions({String? walletId}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (walletId != null && walletId.isNotEmpty && walletId != 'all') {
      whereClause = 'WHERE t.wallet_id = ?';
      whereArgs.add(walletId);
    }

    final result = await db.rawQuery('''
      SELECT t.*, 
             c.name as category_name, c.type as category_type, c.allocated_amount as category_allocated,
             c.icon_code_point as category_icon, c.icon_font_family as category_font,
             c.color_value as category_color, c.sort_order as category_sort, c.is_default as category_default,
             w.name as wallet_name, w.initial_balance as wallet_initial,
             w.icon_code_point as wallet_icon, w.color_value as wallet_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      $whereClause
      ORDER BY t.date DESC, t.created_at DESC
    ''', whereArgs);

    return result.map((row) {
      BudgetCategory? category;
      if (row['category_name'] != null) {
        category = BudgetCategory(
          id: row['category_id'] as String,
          name: row['category_name'] as String,
          type: (row['category_type'] as String?) ?? 'expense',
          allocatedAmount: (row['category_allocated'] as num?)?.toDouble() ?? 0.0,
          iconCodePoint: (row['category_icon'] as int?) ?? 0,
          colorValue: (row['category_color'] as int?) ?? 0,
        );
      }

      Wallet? wallet;
      if (row['wallet_name'] != null) {
        wallet = Wallet(
          id: (row['wallet_id'] as String?) ?? 'wallet_cash',
          name: row['wallet_name'] as String,
          initialBalance: (row['wallet_initial'] as num?)?.toDouble() ?? 0.0,
          iconCodePoint: (row['wallet_icon'] as int?) ?? 0,
          colorValue: (row['wallet_color'] as int?) ?? 0,
          createdAt: DateTime.now(),
        );
      }

      return TransactionItem.fromMap(row, category: category, wallet: wallet);
    }).toList();
  }

  // ================= BACKUP & RESTORE =================

  Future<void> restoreAllData(
    List<BudgetCategory> categories,
    List<TransactionItem> transactions, {
    List<Wallet>? wallets,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('categories');
      if (wallets != null && wallets.isNotEmpty) {
        await txn.delete('wallets');
        final walletBatch = txn.batch();
        for (final w in wallets) {
          walletBatch.insert('wallets', w.toMap());
        }
        await walletBatch.commit(noResult: true);
      }

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
      await txn.delete('wallets');

      final walletBatch = txn.batch();
      for (final w in Wallet.defaultWallets) {
        walletBatch.insert('wallets', w.toMap());
      }
      await walletBatch.commit(noResult: true);

      final catBatch = txn.batch();
      for (final category in BudgetCategory.defaultCategories) {
        catBatch.insert('categories', category.toMap());
      }
      for (final incCategory in BudgetCategory.defaultIncomeCategories) {
        catBatch.insert('categories', incCategory.toMap());
      }
      await catBatch.commit(noResult: true);
    });
  }
}
