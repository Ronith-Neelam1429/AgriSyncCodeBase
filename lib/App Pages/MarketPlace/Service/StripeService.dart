// StripeService.dart
import 'package:agrisync/App%20Pages/MarketPlace/Seller/MockService.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StripeService {
  final bool useMock;
  final MockFunctionsService _mockService = MockFunctionsService();
  
  StripeService({this.useMock = false});
  
  Future<Map<String, dynamic>> createConnectAccount({String? country, required String baseUrl}) async {
    if (useMock) {
      return _mockService.createConnectAccount(country: country, baseUrl: baseUrl);
    } else {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createConnectAccount').call({
        'country': country ?? 'US',
        'baseUrl': baseUrl,
      });
      return result.data;
    }
  }
  
  Future<Map<String, dynamic>> updateStripeAccountStatus() async {
    if (useMock) {
      return _mockService.updateStripeAccountStatus();
    } else {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('updateStripeAccountStatus').call({});
      return result.data;
    }
  }
  
  Future<Map<String, dynamic>> refreshAccountLink({required String baseUrl}) async {
    if (useMock) {
      return _mockService.refreshAccountLink(baseUrl: baseUrl);
    } else {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('refreshAccountLink').call({
        'baseUrl': baseUrl,
      });
      return result.data;
    }
  }
  
  // Save mock Stripe account data to Firestore for testing
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