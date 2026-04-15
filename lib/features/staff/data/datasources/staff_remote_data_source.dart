import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/staff/data/models/staff_model.dart';

abstract interface class StaffRemoteDataSource {
  Future<List<StaffModel>> getStaff();
  Future<StaffModel> updateStaffRole(String staffId, String role);
  Future<StaffModel> createStaff(String name, String username, String password);
  Future<void> deleteStaff(String staffId);
  Future<bool> checkUsername(String username);
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  final FirebaseFirestore _firestore;

  StaffRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<StaffModel>> getStaff() async {
    try {
      final snapshot = await _firestore
          .collection('profiles')
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs.map((data) => StaffModel.fromJson(data.data())).toList();
    } catch (e) {
      debugPrint('StaffRemoteDataSource.getStaff error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<StaffModel> updateStaffRole(String staffId, String role) async {
    try {
      await _firestore.collection('profiles').doc(staffId).update({'role': role});
      
      final doc = await _firestore.collection('profiles').doc(staffId).get();
      return StaffModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('StaffRemoteDataSource.updateStaffRole error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<StaffModel> createStaff(String name, String username, String password) async {
    FirebaseApp? secondaryApp;
    try {
      final email = '${username.trim().toLowerCase()}@flowpos.local';
      
      // Secondary app initialization to create user without logging out current user
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final profileData = {
        'id': uid,
        'name': name,
        'username': username.trim().toLowerCase(),
        'email': email,
        'role': 'cashier',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('profiles').doc(uid).set(profileData);

      return StaffModel.fromJson(profileData);
    } catch (e) {
      debugPrint('StaffRemoteDataSource.createStaff error: $e');
      throw ServerException(e.toString());
    } finally {
      await secondaryApp?.delete();
    }
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    try {
      // In Firebase, we can't easily delete an Auth user from the client side
      // unless it's the current user. We'll disable them by removing their profile
      // or marking them as inactive.
      await _firestore.collection('profiles').doc(staffId).delete();
    } catch (e) {
      debugPrint('StaffRemoteDataSource.deleteStaff error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkUsername(String username) async {
    try {
      final snapshot = await _firestore
          .collection('profiles')
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('StaffRemoteDataSource.checkUsername error: $e');
      return false; 
    }
  }
}
