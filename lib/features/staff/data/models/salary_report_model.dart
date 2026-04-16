import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryReportModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int basePay;
  final int bonus;
  final int debt;
  final int netPay;
  final String? notes;
  final DateTime createdAt;

  SalaryReportModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.periodStart,
    required this.periodEnd,
    required this.basePay,
    this.bonus = 0,
    this.debt = 0,
    required this.netPay,
    this.notes,
    required this.createdAt,
  });

  factory SalaryReportModel.fromJson(Map<String, dynamic> json) {
    return SalaryReportModel(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      staffName: json['staff_name'] as String,
      periodStart: (json['period_start'] as Timestamp).toDate(),
      periodEnd: (json['period_end'] as Timestamp).toDate(),
      basePay: json['base_pay'] as int,
      bonus: json['bonus'] as int? ?? 0,
      debt: json['debt'] as int? ?? 0,
      netPay: json['net_pay'] as int,
      notes: json['notes'] as String?,
      createdAt: (json['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'period_start': periodStart,
      'period_end': periodEnd,
      'base_pay': basePay,
      'bonus': bonus,
      'debt': debt,
      'net_pay': netPay,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
