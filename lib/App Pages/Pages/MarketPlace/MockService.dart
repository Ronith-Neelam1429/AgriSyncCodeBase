// MockFunctionsService.dart
class MockFunctionsService {
  // Simulates createConnectAccount function
  Future<Map<String, dynamic>> createConnectAccount({String? country, required String baseUrl}) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));
    
    // Mock response data
    return {
      'accountId': 'acct_mock${DateTime.now().millisecondsSinceEpoch}',
      'accountLinkUrl': 'https://mockstripe.com/connect?session=${DateTime.now().millisecondsSinceEpoch}',
    };
  }
  
  // Simulates updateStripeAccountStatus function
  Future<Map<String, dynamic>> updateStripeAccountStatus() async {
    await Future.delayed(Duration(seconds: 1));
    
    // Randomly select a status to simulate different cases
    final statuses = ['pending', 'submitted', 'active'];
    final status = statuses[DateTime.now().second % 3]; // Simple way to get different results
    
    return {'status': status};
  }
  
  // Simulates refreshAccountLink function
  Future<Map<String, dynamic>> refreshAccountLink({required String baseUrl}) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    return {
      'url': 'https://mockstripe.com/connect/refresh?session=${DateTime.now().millisecondsSinceEpoch}',
    };
  }
}