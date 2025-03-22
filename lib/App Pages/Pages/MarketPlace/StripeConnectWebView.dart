import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StripeConnectWebView extends StatelessWidget {
  final String url;
  final VoidCallback onComplete;
  
  const StripeConnectWebView({
    Key? key, 
    required this.url, 
    required this.onComplete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // For mock URLs, we'll display a simulated Stripe Connect page
    if (url.startsWith('https://mockstripe.com')) {
      return _buildMockStripeConnect(context);
    }
    
    // Real WebView for when you switch to the actual Stripe implementation
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect your account'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              // Handle navigation to your return_url
              if (request.url.startsWith('https://yourdomain.com/stripe-connect-success')) {
                Navigator.of(context).pop();
                onComplete();
                return NavigationDecision.prevent;
              }
              
              // Handle refresh URL
              if (request.url.startsWith('https://yourdomain.com/stripe-connect-refresh')) {
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ))
          ..loadRequest(Uri.parse(url)),
      ),
    );
  }
  
  // Mock Stripe Connect UI for testing
  Widget _buildMockStripeConnect(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect with Stripe (Mock)'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/b/ba/Stripe_Logo%2C_revised_2016.svg',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.credit_card, size: 60, color: Colors.blue),
                ),
              ),
            ),
            Text(
              'Connect your bank account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This is a simulated Stripe Connect page for testing. In production, you would see the actual Stripe Connect onboarding form here.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            
            // Mock form fields
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Bank Account Number',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Routing Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: () {
                // Simulate successful connection
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bank account connected successfully')),
                );
                
                // Close the screen and trigger the callback
                Future.delayed(Duration(seconds: 1), () {
                  Navigator.of(context).pop();
                  onComplete();
                });
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Connect Account'),
                  ],
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}