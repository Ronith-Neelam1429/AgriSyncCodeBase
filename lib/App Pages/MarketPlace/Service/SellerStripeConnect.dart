import 'package:agrisync/App%20Pages/MarketPlace/Service/StripeConnectWebView.dart';
import 'package:agrisync/App%20Pages/MarketPlace/Service/StripeService.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SellerStripeConnect extends StatefulWidget {
  @override
  _SellerStripeConnectState createState() => _SellerStripeConnectState();
}

class _SellerStripeConnectState extends State<SellerStripeConnect> {
  bool _isLoading = false;
  String? _stripeAccountId;
  String? _stripeAccountStatus;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final StripeService _stripeService = StripeService(useMock: false); // Use mock mode

  @override
  void initState() {
    super.initState();
    _fetchStripeAccountDetails();
  }

  Future<void> _fetchStripeAccountDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _stripeAccountId = userData['stripeAccountId'];
          _stripeAccountStatus = userData['stripeAccountStatus'];
        });
        
        // If account exists but we need to check its status
        if (_stripeAccountId != null && 
            (_stripeAccountStatus == 'pending' || _stripeAccountStatus == 'submitted')) {
          _checkAccountStatus();
        }
      }
    } catch (e) {
      print('Error fetching Stripe account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading account information')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // In SellerStripeConnect.dart, modify _connectStripeAccount() method
  Future<void> _connectStripeAccount() async {
    setState(() => _isLoading = true);
    
    try {
      final baseUrl = 'https://yourdomain.com'; // Your domain for redirects
      
      final result = await _stripeService.createConnectAccount(baseUrl: baseUrl);
      
      final accountId = result['accountId'];
      final accountLinkUrl = result['accountLinkUrl'];
      
      // Update local state
      setState(() => _stripeAccountId = accountId);
      
      // Save to Firestore for persistence
      await _stripeService.saveMockStripeData(accountId: accountId, status: 'pending');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe account created successfully')),
      );
      
      // Navigate to WebView
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StripeConnectWebView(
            url: accountLinkUrl,
            onComplete: () {
              _fetchStripeAccountDetails();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error connecting Stripe account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create Stripe account')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

    Future<void> _checkAccountStatus() async {
    try {
      final result = await _stripeService.updateStripeAccountStatus();
      
      setState(() {
        _stripeAccountStatus = result['status'];
      });
      
      // Also update in Firestore
      if (_stripeAccountId != null) {
        await _stripeService.saveMockStripeData(
          accountId: _stripeAccountId!,
          status: _stripeAccountStatus ?? 'pending'
        );
      }
      
      // Show appropriate message based on status
      if (_stripeAccountStatus == 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your account is now active and ready to receive payments!')),
        );
      } else if (_stripeAccountStatus == 'submitted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your account details have been submitted but are still being reviewed')),
        );
      }
    } catch (e) {
      print('Error checking account status: $e');
    }
  }
  
  Future<void> _refreshAccountLink() async {
    setState(() => _isLoading = true);
    
    try {
      final baseUrl = 'https://yourdomain.com';
      
      final result = await _stripeService.refreshAccountLink(baseUrl: baseUrl);
      
      final accountLinkUrl = result['url'];
      
      // Navigate to WebView
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StripeConnectWebView(
            url: accountLinkUrl,
            onComplete: () {
              _fetchStripeAccountDetails();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error refreshing account link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh account link')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Account Setup'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stripe Connect for Sellers',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Connect your bank account to receive payments directly from customers',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                
                if (_stripeAccountId == null)
                  _buildConnectButton()
                else
                  _buildAccountStatus(),
                
                SizedBox(height: 16),
                Text(
                  'By connecting your account, you agree to Stripe\'s Terms of Service and Privacy Policy.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _connectStripeAccount,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance),
            SizedBox(width: 8),
            Text('Connect Bank Account'),
          ],
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildAccountStatus() {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    bool showCompleteButton = false;
    
    switch (_stripeAccountStatus) {
      case 'active':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Your account is active and ready to receive payments';
        break;
      case 'submitted':
        statusIcon = Icons.hourglass_bottom;
        statusColor = Colors.orange;
        statusText = 'Your account is being reviewed by Stripe';
        break;
      case 'pending':
      default:
        statusIcon = Icons.warning;
        statusColor = Colors.orange;
        statusText = 'Your account setup is incomplete';
        showCompleteButton = true;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(fontSize: 16, color: statusColor),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Stripe Account ID: ${_stripeAccountId!.substring(0, 10)}...',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        if (showCompleteButton)
          ElevatedButton(
            onPressed: _refreshAccountLink,
            child: Text('Complete Account Setup'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        SizedBox(height: 8),
        TextButton(
          onPressed: _checkAccountStatus,
          child: Text('Refresh Account Status'),
        ),
      ],
    );
  }
}

