import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankAccountLinkingPage extends StatefulWidget {
  const BankAccountLinkingPage({super.key});

  @override
  State<BankAccountLinkingPage> createState() => _BankAccountLinkingPageState();
}

class _BankAccountLinkingPageState extends State<BankAccountLinkingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _routingNumberController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  Future<void> _linkBankAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Store bank account info in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('paymentInfo')
              .doc('bankAccount')
              .set({
            'accountHolderName': _accountHolderController.text,
            'bankName': _bankNameController.text,
            'accountNumber': _accountNumberController.text,
            'routingNumber': _routingNumberController.text,
            'dateLinked': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bank account linked successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _errorMessage = 'User not authenticated. Please log in again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error linking bank account: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Link Bank Account',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with illustration
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 200, 227, 230),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 60,
                          color: const Color.fromARGB(255, 56, 142, 136),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text(
                        'Link your bank account to receive payments directly when your listings sell.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Account Holder Name
                    _buildInputField(
                      controller: _accountHolderController,
                      label: 'Account Holder Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter account holder name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bank Name
                    _buildInputField(
                      controller: _bankNameController,
                      label: 'Bank Name',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter bank name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Account Number
                    _buildInputField(
                      controller: _accountNumberController,
                      label: 'Account Number',
                      icon: Icons.credit_card,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter account number';
                        }
                        return null;
                      },
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    // Routing Number
                    _buildInputField(
                      controller: _routingNumberController,
                      label: 'Routing Number',
                      icon: Icons.numbers,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter routing number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _linkBankAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 71, 169, 163),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Link Bank Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Why link your bank account?
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why link your bank account?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitItem(
                            'Receive payments directly when your listings sell',
                            Icons.payments,
                          ),
                          _buildBenefitItem(
                            'Faster payment processing',
                            Icons.speed,
                          ),
                          _buildBenefitItem(
                            'Secure and encrypted information transfer',
                            Icons.shield,
                          ),
                          _buildBenefitItem(
                            'No need to manually transfer funds',
                            Icons.sync_alt,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
