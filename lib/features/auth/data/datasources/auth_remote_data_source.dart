import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  User? get currentUser;
  Future<UserModel> signUpWithEmailAndPassword(
    String name,
    String email,
    String password, {
    String role,
  });
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> getCurrentUserData();
  Future<void> signOut();
  Future<void> updatePassword(String newPassword);
  Future<bool> checkOwnerExists();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firebaseAuth, this._firestore);

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String name,
    String email,
    String password, {
    String role = 'owner',
  }) async {
    try {
      // Limit to 1 Owner only
      if (role == 'owner') {
        final ownerQuery = await _firestore
            .collection('profiles')
            .where('role', isEqualTo: 'owner')
            .limit(1)
            .get();

        if (ownerQuery.docs.isNotEmpty) {
          throw const ServerException(
              'Aplikasi sudah memiliki Owner. Silakan hubungi Owner untuk akses.');
        }
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const ServerException('User creation failed');
      }

      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        username: email.contains('@flowpos.local') 
            ? email.split('@')[0] 
            : null,
      );

      // Save to Firestore 'profiles' collection
      await _firestore.collection('profiles').doc(credential.user!.uid).set({
        'id': userModel.id,
        'email': userModel.email,
        'name': userModel.name,
        'role': userModel.role,
        'username': userModel.username,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Authentication error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final effectiveEmail = email.contains('@') ? email : '${email.trim().toLowerCase()}@flowpos.local';
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: effectiveEmail,
        password: password,
      );

      if (credential.user == null) {
        throw const ServerException('Login failed');
      }

      final userData = await getCurrentUserData();
      if (userData == null) {
        throw const ServerException('User profile not found');
      }

      return userData;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Login failed');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('profiles').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          return UserModel(
            id: data['id'] ?? user.uid,
            email: data['email'] ?? user.email ?? '',
            name: data['name'] ?? '',
            role: data['role'] ?? 'cashier',
            username: data['username'],
          );
        }
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to fetch user data: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Password update failed');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkOwnerExists() async {
    try {
      final query = await _firestore
          .collection('profiles')
          .where('role', isEqualTo: 'owner')
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
