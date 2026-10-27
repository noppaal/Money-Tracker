import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/budget_category.dart';
import '../data/models/transaction_item.dart';
import '../core/utils/date_formatter.dart';
import '../core/constants/app_constants.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime _selectedMonth = DateTime.now();
  List<BudgetCategory> _categories = [];
  List<TransactionItem> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Transaction filter state
  String? _selectedCategoryFilter;
  String _searchQuery = '';

  FinanceProvider() {
    loadData();
  }

  // Getters
  DateTime get selectedMonth => _selectedMonth;
  List<BudgetCategory> get categories => _categories;
  List<TransactionItem> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;

  // Filtered transactions
  List<TransactionItem> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesCategory = _selectedCategoryFilter == null ||
          tx.categoryId == _selectedCategoryFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          tx.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.category?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Financial Summaries for Current Month
  double get totalBudget {
    return _categories.fold(0.0, (sum, cat) => sum + cat.allocatedAmount);
  }

  double get totalSpent {
    return _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
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

  /// Sisa budget makan harian dihitung dari:
  /// (Sisa Budget Makan) / (Sisa Hari dalam Bulan Ini)
  double get dailyMealAllowance {
    final food = foodCategory;
    if (food == null) return 0.0;
    final remainingFoodBudget = food.remainingAmount;
    if (remainingFoodBudget <= 0) return 0.0;
    final days = remainingDaysInMonth;
    return remainingFoodBudget / (days > 0 ? days : 1);
  }

  /// Baseline comparison ratio for Meal Gauge
  double get mealHealthRatio {
    // Baseline is AppConstants.defaultDailyMealTarget (Rp60.000)
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
      // 1. Fetch all categories
      final dbCategories = await _dbHelper.getAllCategories();

      // 2. Fetch monthly transactions
      final monthTransactions = await _dbHelper.getTransactionsForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      // 3. Fetch spent per category for the selected month
      final spentMap = await _dbHelper.getSpentPerCategoryForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      // 4. Update categories with computed spent amount
      _categories = dbCategories.map((cat) {
        final spent = spentMap[cat.id] ?? 0.0;
        return cat.copyWith(spentAmount: spent);
      }).toList();

      _transactions = monthTransactions;
    } catch (e) {
      _errorMessage = 'Gagal memuat data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeMonth(DateTime newMonth) {
    _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
    loadData();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryFilter = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ================= MUTATIONS =================

  Future<bool> addTransaction({
    required String categoryId,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    try {
      final now = DateTime.now();
      final item = TransactionItem(
        id: 'tx_${now.millisecondsSinceEpoch}',
        categoryId: categoryId,
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
