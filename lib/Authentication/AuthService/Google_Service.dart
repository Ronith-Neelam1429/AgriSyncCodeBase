import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Add these configurations
    scopes: ['email'], // Ask for email access
    //clientId: '52905t4282209-kr4laf56num8mkr68rpij7669slh577u.apps.googleusercontent.com', // Your web client ID from Google Cloud Console (for iOS)
  );
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase auth hookup

  // Signs in with Google and links it to Firebase
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // First check if a user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut(); // Log out any old session to start fresh
      }

      print("Starting Google Sign In process");
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn(); // Pops up the Google sign-in screen
      print("Google Sign In result: ${googleUser?.email}");

      if (googleUser == null) {
        print("Google Sign In cancelled by user");
        return null; // User bailed, so we’re done
      }

      // Obtain the auth details from the request
      print("Getting Google auth details");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication; // Grab the tokens
      
      // Create a new credential
      print("Creating Firebase credential");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print("Signing in to Firebase");
      return await _auth.signInWithCredential(credential); // Hook it up to Firebase
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow; // Toss the error up to whoever’s calling this
    }
  }
}