import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Coleção principal
  CollectionReference get _usersRef => _firestore.collection('users');

  Future<void> createUser({
    required UserModel user,
    required String password,
  }) async {
    // Cria a conta no Firebase Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    String? uid = credential.user?.uid;

    if (uid != null) {
      // Cria o documento no Firestore com o mesmo ID (UID) do Auth
      await _usersRef.doc(uid).set(user.toMap());
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    DocumentSnapshot doc = await _usersRef.doc(uid).get();

    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<UserModel?> streamUserProfile() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    await _usersRef.doc(uid).update({
      'name': name,
      'phone': phone,
      'updatedAt': DateTime.now(),
    });
  }

  // Reautentica o usuário com a senha atual. O Firebase exige isso antes
  // de qualquer operação sensível (trocar e-mail ou senha), ou lança o
  // erro "requires-recent-login" se o login foi feito há muito tempo.
  Future<void> _reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("Usuário não autenticado");
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
  }

  // Atualiza o e-mail de acesso.
  // Importante: nas versões atuais do firebase_auth o método antigo
  // updateEmail() foi removido. O fluxo correto é verifyBeforeUpdateEmail,
  // que envia um link de confirmação para o e-mail novo — a troca só
  // é efetivada no Firebase Auth depois que o usuário clica nesse link.
  // Aqui já atualizamos o Firestore com o e-mail novo (para refletir no
  // app), mas o login continua exigindo o e-mail atual até a confirmação.
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado");

    await _reauthenticate(currentPassword);
    await user.verifyBeforeUpdateEmail(newEmail);

    await _usersRef.doc(user.uid).update({
      'email': newEmail,
      'updatedAt': DateTime.now(),
    });
  }

  // Atualiza a senha de acesso. Também exige reautenticação recente.
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado");

    await _reauthenticate(currentPassword);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Remove o documento do Firestore
    await _usersRef.doc(currentUser.uid).delete();

    // Remove a conta de acesso do Firebase Auth
    await currentUser.delete();
  }
}