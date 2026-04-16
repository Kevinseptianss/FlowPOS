import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/expense/data/models/expense_category_model.dart';
import 'package:flow_pos/features/expense/data/models/expense_model.dart';

abstract interface class ExpenseRemoteDataSource {
  Future<List<ExpenseCategoryModel>> getCategories();
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category);
  Future<void> deleteCategory(String categoryId);

  Future<List<ExpenseModel>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? type,
    String? staffId,
    String? shiftId,
  });
  Future<ExpenseModel> createExpense(ExpenseModel expense);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore _firestore;

  ExpenseRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<ExpenseCategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('expense_categories').get();
      return snapshot.docs
          .map((doc) => ExpenseCategoryModel.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category) async {
    try {
      final docRef = _firestore.collection('expense_categories').doc();
      final data = category.toJson();
      data['id'] = docRef.id;
      await docRef.set(data);
      return ExpenseCategoryModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('expense_categories').doc(categoryId).delete();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('expenses').doc();
      final expenseData = expense.toJson();
      expenseData['id'] = docRef.id;
      
      // Ensure specific timestamp if not provided, or use server timestamp
      expenseData['created_at'] = FieldValue.serverTimestamp();

      batch.set(docRef, expenseData);

      // If it's a SHIFT type expense, update the shift totals
      if (expense.type == 'SHIFT' && expense.shiftId != null) {
        final shiftRef = _firestore.collection('shifts').doc(expense.shiftId);
        
        if (expense.cashActionType == 'CASH_OUT') {
          batch.update(shiftRef, {
            'total_cash_out': FieldValue.increment(expense.amount),
          });
        } else if (expense.cashActionType == 'CASH_IN') {
          batch.update(shiftRef, {
            'total_cash_in': FieldValue.increment(expense.amount),
          });
        }
      }

      await batch.commit();
      
      // Return with local timestamp for UI immediate feedback
      return ExpenseModel.fromJson(expenseData..['created_at'] = DateTime.now().toIso8601String());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? type,
    String? staffId,
    String? shiftId,
  }) async {
    try {
      Query query = _firestore.collection('expenses').orderBy('created_at', descending: true);

      if (start != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
      }
      if (end != null) {
        query = query.where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (staffId != null) {
        query = query.where('staff_id', isEqualTo: staffId);
      }
      if (shiftId != null) {
        query = query.where('shift_id', isEqualTo: shiftId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>..['id'] = doc.id))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
