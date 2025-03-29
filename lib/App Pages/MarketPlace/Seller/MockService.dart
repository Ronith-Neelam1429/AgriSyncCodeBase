// Create MockService.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFunctionsService {
  Future<Map<String, dynamic>> createConnectAccount({String? country, required String baseUrl}) async {
    // Mock implementation for testing
    final mockAccountId = 'acct_mock${DateTime.now().millisecondsSinceEpoch}';
    final mockUrl = 'https://mockstripe.com/connect/setup?token=${DateTime.now().millisecondsSinceEpoch}';
    
    // Save to Firestore for persistence
    await saveMockStripeData(accountId: mockAccountId, status: 'pending');
    
    return {
      'accountId': mockAccountId,
      'accountLinkUrl': mockUrl,
    };
  }
  
  Future<Map<String, dynamic>> updateStripeAccountStatus() async {
    // For mock purposes, randomly decide between statuses
    final statuses = ['pending', 'submitted', 'active'];
    final mockStatus = statuses[DateTime.now().second % 3]; // Simple way to get different results
    
    return {'status': mockStatus};
  }
  
  Future<Map<String, dynamic>> refreshAccountLink({required String baseUrl}) async {
    final mockUrl = 'https://mockstripe.com/connect/setup?refreshed=${DateTime.now().millisecondsSinceEpoch}';
    return {'url': mockUrl};
  }
  
  Future<void> saveMockStripeData({required String accountId, required String status}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'stripeAccountId': accountId,
        'stripeAccountStatus': status,
      });
    }
  }
}