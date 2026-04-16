import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/staff/data/models/salary_report_model.dart';

abstract interface class SalaryRemoteDataSource {
  Future<void> saveSalaryReport(SalaryReportModel report);
  Future<List<SalaryReportModel>> getSalaryReportsByRange(DateTime start, DateTime end);
  Future<List<SalaryReportModel>> getSalaryReports();
}

class SalaryRemoteDataSourceImpl implements SalaryRemoteDataSource {
  final FirebaseFirestore _firestore;

  SalaryRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> saveSalaryReport(SalaryReportModel report) async {
    try {
      await _firestore
          .collection('salary_reports')
          .doc(report.id)
          .set(report.toJson());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<SalaryReportModel>> getSalaryReportsByRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('salary_reports')
          .where('period_start', isGreaterThanOrEqualTo: start)
          .where('period_start', isLessThanOrEqualTo: end)
          .get();

      return snapshot.docs
          .map((doc) => SalaryReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<SalaryReportModel>> getSalaryReports() async {
    try {
      final snapshot = await _firestore
          .collection('salary_reports')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SalaryReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
