import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/budget_category.dart';
import '../data/models/transaction_item.dart';
import '../data/models/wallet.dart';
import '../core/utils/date_formatter.dart';
import '../core/constants/app_constants.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime _selectedMonth = DateTime.now();
  List<Wallet> _wallets = [];
  String? _selectedWalletId; // specific wallet id or 'all'
  List<BudgetCategory> _categories = [];
  List<TransactionItem> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Transaction filter state
  String _selectedTypeFilter = 'all'; // 'all', 'expense', 'income'
  String? _selectedCategoryFilter;
  String _searchQuery = '';

  FinanceProvider() {
    loadData();
  }

  // Getters
  DateTime get selectedMonth => _selectedMonth;
  List<Wallet> get wallets => _wallets;
  String? get selectedWalletId => _selectedWalletId;

  Wallet? get selectedWallet {
    if (_selectedWalletId == 'all' || _selectedWalletId == null) {
      return null;
    }
    try {
      return _wallets.firstWhere((w) => w.id == _selectedWalletId);
    } catch (_) {
      return _wallets.isNotEmpty ? _wallets.first : null;
    }
  }

  List<BudgetCategory> get categories => _categories;
  List<BudgetCategory> get expenseCategories => _categories.where((c) => c.isExpense).toList();
  List<BudgetCategory> get incomeCategories => _categories.where((c) => c.isIncome).toList();

  List<TransactionItem> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedTypeFilter => _selectedTypeFilter;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;

  // Filtered transactions (by type, category, and search query)
  List<TransactionItem> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesType = _selectedTypeFilter == 'all' || tx.type == _selectedTypeFilter;
      final matchesCategory = _selectedCategoryFilter == null ||
          tx.categoryId == _selectedCategoryFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          tx.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.category?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesType && matchesCategory && matchesSearch;
    }).toList();
  }

  // Financial Summaries
  double get totalWalletBalance {
    if (selectedWallet != null) {
      return selectedWallet!.currentBalance;
    }
    return _wallets.fold(0.0, (sum, w) => sum + w.currentBalance);
  }

  double get totalInitialBalance {
    if (selectedWallet != null) {
      return selectedWallet!.initialBalance;
    }
    return _wallets.fold(0.0, (sum, w) => sum + w.initialBalance);
  }

  // Total budget is sum of expense envelopes only
  double get totalBudget {
    return expenseCategories.fold(0.0, (sum, cat) => sum + cat.allocatedAmount);
  }

  // Total spent in this month (expenses only)
  double get totalSpent {
    return _transactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Total income in this month
  double get totalIncome {
    return _transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Net Cash Flow for the month (Pemasukan - Pengeluaran)
  double get netCashFlow {
    return totalIncome - totalSpent;
  }

  double get remainingBalance {
    return totalBudget - totalSpent;
  }

  double get totalUsageRatio {
    return totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
  }

  // Dynamic Daily Meal Gauge Calculations
  BudgetCategory? get foodCategory {
    try {
      return _categories.firstWhere((cat) => cat.id == 'food');
    } catch (_) {
      return null;
    }
  }

  int get remainingDaysInMonth {
    return DateFormatter.getRemainingDaysInMonth(_selectedMonth);
  }

  double get dailyMealAllowance {
    final food = foodCategory;
    if (food == null) return 0.0;
    final remainingFoodBudget = food.remainingAmount;
    if (remainingFoodBudget <= 0) return 0.0;
    final days = remainingDaysInMonth;
    return remainingFoodBudget / (days > 0 ? days : 1);
  }

  double get mealHealthRatio {
    const baseline = AppConstants.defaultDailyMealTarget;
    if (baseline == 0) return 1.0;
    return (dailyMealAllowance / baseline).clamp(0.0, 1.5);
  }

  // ================= DATA LOADING =================

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch all wallets
      _wallets = await _dbHelper.getAllWallets();
      if (_wallets.isNotEmpty && _selectedWalletId == null) {
        _selectedWalletId = _wallets.first.id;
      }

      // 2. Fetch all categories
      final dbCategories = await _dbHelper.getAllCategories();

      // 3. Fetch transactions for selected month and active wallet
      final monthTransactions = await _dbHelper.getTransactionsForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        walletId: _selectedWalletId,
      );

      // 4. Fetch spent & income per category for the selected month and wallet
      final spentMap = await _dbHelper.getSpentPerCategoryForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        walletId: _selectedWalletId,
      );

      final incomeMap = await _dbHelper.getIncomePerCategoryForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        walletId: _selectedWalletId,
      );

      // 5. Update categories with computed amount (spent for expense, earned for income)
      _categories = dbCategories.map((cat) {
        final amount = cat.isIncome
            ? (incomeMap[cat.id] ?? 0.0)
            : (spentMap[cat.id] ?? 0.0);
        return cat.copyWith(spentAmount: amount);
      }).toList();

      _transactions = monthTransactions;
    } catch (e) {
      _errorMessage = 'Gagal memuat data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectWallet(String? walletId) {
    _selectedWalletId = walletId;
    loadData();
  }

  void changeMonth(DateTime newMonth) {
    _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    loadData();
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryFilter = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ================= WALLET MUTATIONS =================

  Future<bool> addWallet({
    required String name,
    required double initialBalance,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    try {
      final now = DateTime.now();
      final newWallet = Wallet(
        id: 'wallet_${now.millisecondsSinceEpoch}',
        name: name.trim(),
        initialBalance: initialBalance,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        createdAt: now,
        isDefault: false,
      );

      await _dbHelper.insertWallet(newWallet);
      _selectedWalletId = newWallet.id;
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah dompet: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWallet(Wallet wallet) async {
    try {
      await _dbHelper.updateWallet(wallet);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui dompet: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWallet(String id) async {
    if (_wallets.length <= 1) {
      _errorMessage = 'Tidak dapat menghapus satu-satunya dompet';
      notifyListeners();
      return false;
    }

    try {
      await _dbHelper.deleteWallet(id);
      if (_selectedWalletId == id) {
        final remaining = _wallets.where((w) => w.id != id);
        _selectedWalletId = remaining.isNotEmpty ? remaining.first.id : null;
      }
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus dompet: $e';
      notifyListeners();
      return false;
    }
  }

  // ================= TRANSACTION MUTATIONS =================

  Future<bool> addTransaction({
    required String categoryId,
    required double amount,
    required DateTime date,
    String type = 'expense',
    String note = '',
    String? walletId,
  }) async {
    try {
      final now = DateTime.now();
      final effectiveWalletId = walletId ??
          (_selectedWalletId != 'all' ? _selectedWalletId : null) ??
          (_wallets.isNotEmpty ? _wallets.first.id : 'wallet_cash');

      final item = TransactionItem(
        id: 'tx_${now.millisecondsSinceEpoch}',
        categoryId: categoryId,
        walletId: effectiveWalletId,
        type: type,
        amount: amount,
        date: date,
        note: note.trim(),
        createdAt: now,
      );

      await _dbHelper.insertTransaction(item);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionItem item) async {
    try {
      await _dbHelper.updateTransaction(item);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _dbHelper.deleteTransaction(id);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategoryBudget(String categoryId, double newAmount) async {
    try {
      await _dbHelper.updateCategoryBudget(categoryId, newAmount);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah anggaran kategori: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetData() async {
    try {
      await _dbHelper.resetToDefault();
      _selectedWalletId = null;
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mereset data: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> reloadAfterRestore() async {
    await loadData();
  }
}
