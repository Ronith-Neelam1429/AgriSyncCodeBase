import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Add these configurations
    scopes: ['email'],
    //clientId: '52905t4282209-kr4laf56num8mkr68rpij7669slh577u.apps.googleusercontent.com', // Your web client ID from Google Cloud Console (for iOS)
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // First check if a user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      print("Starting Google Sign In process");
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("Google Sign In result: ${googleUser?.email}");

      if (googleUser == null) {
        print("Google Sign In cancelled by user");
        return null;
      }

      // Obtain the auth details from the request
      print("Getting Google auth details");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      print("Creating Firebase credential");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print("Signing in to Firebase");
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }
}