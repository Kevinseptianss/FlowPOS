import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/shift/data/models/shift_model.dart';

abstract interface class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShiftHistory();
  Future<ShiftModel> openShift({
    required String cashierId,
    required double openingBalance,
  });
  Future<ShiftModel> closeShift({
    required String shiftId,
    required double closingBalance,
  });
  Future<ShiftModel?> getActiveShift(String cashierId);
  Future<List<ShiftModel>> getShiftsByRange(DateTime start, DateTime end);
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final FirebaseFirestore _firestore;

  ShiftRemoteDataSourceImpl(this._firestore);

  @override
  Future<ShiftModel?> getActiveShift(String cashierId) async {
    try {
      final snapshot = await _firestore
          .collection('shifts')
          .where('cashier_id', isEqualTo: cashierId)
          .where('closed_at', isNull: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ShiftModel.fromJson(snapshot.docs.first.data()..['id'] = snapshot.docs.first.id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ShiftModel>> getShiftHistory() async {
    try {
      final snapshot = await _firestore
          .collection('shifts')
          .orderBy('opened_at', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ShiftModel.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ShiftModel> openShift({
    required String cashierId,
    required double openingBalance,
  }) async {
    try {
      // 1. Check for existing active shift
      final active = await getActiveShift(cashierId);
      if (active != null) {
        throw const ServerException('Anda masih memiliki shift yang belum ditutup. Tutup shift tersebut terlebih dahulu sebelum membuka shift baru.');
      }

      // 2. Get cashier name for denormalization
      final profileDoc = await _firestore.collection('profiles').doc(cashierId).get();
      final cashierName = profileDoc.data()?['name'] ?? 'Unknown';

      // 3. Create shift record
      final docRef = _firestore.collection('shifts').doc();
      final data = {
        'id': docRef.id,
        'cashier_id': cashierId,
        'opening_balance': openingBalance.toInt(),
        'opened_at': FieldValue.serverTimestamp(),
        'closed_at': null,
        'profiles': {'name': cashierName}, // Replicate Supabase join structure for model compat
      };

      await docRef.set(data);
      
      return ShiftModel.fromJson(data..['opened_at'] = DateTime.now().toIso8601String());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ShiftModel> closeShift({
    required String shiftId,
    required double closingBalance,
  }) async {
    try {
      await _firestore.collection('shifts').doc(shiftId).update({
        'closed_at': FieldValue.serverTimestamp(),
        'closing_balance': closingBalance.toInt(),
      });
      
      final doc = await _firestore.collection('shifts').doc(shiftId).get();
      return ShiftModel.fromJson(doc.data()!..['id'] = shiftId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ShiftModel>> getShiftsByRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('shifts')
          .where('opened_at', isGreaterThanOrEqualTo: start)
          .where('opened_at', isLessThanOrEqualTo: end)
          .orderBy('opened_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ShiftModel.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
