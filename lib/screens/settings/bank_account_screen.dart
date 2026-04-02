// lib/screens/bank_account_screen.dart

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/bank_account.dart';
class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  
  bool _isLoading = false;
  BankAccount? _existingAccount;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _ibanController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBankDetails() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getBankDetails();
      if (result['success'] && result['data'] != null) {
        setState(() {
          _existingAccount = BankAccount.fromJson(result['data']);
        });
      }
    } catch (e) {
      print('Error loading bank details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBankAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.createBankDetails(
        accountHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        routingNumber: _routingNumberController.text.trim().isEmpty 
            ? null 
            : _routingNumberController.text.trim(),
        iban: _ibanController.text.trim().isEmpty 
            ? null 
            : _ibanController.text.trim(),
        swiftCode: _swiftCodeController.text.trim().isEmpty 
            ? null 
            : _swiftCodeController.text.trim(),
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to save'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading && _existingAccount == null
          ? const Center(child: CircularProgressIndicator())
          : _existingAccount != null
              ? _buildExistingAccountView()
              : _buildForm(),
    );
  }

  Widget _buildExistingAccountView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Bank Account Added',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Account Holder', _existingAccount!.accountHolderName),
          _buildInfoRow('Bank Name', _existingAccount!.bankName),
          _buildInfoRow('Account Number', _existingAccount!.maskedAccountNumber),
          if (_existingAccount!.routingNumber != null)
            _buildInfoRow('Routing Number', _existingAccount!.routingNumber!),
          if (_existingAccount!.iban != null)
            _buildInfoRow('IBAN', _existingAccount!.iban!),
          if (_existingAccount!.swiftCode != null)
            _buildInfoRow('SWIFT Code', _existingAccount!.swiftCode!),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _existingAccount = null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
      foregroundColor: Colors.white, // This will make text and icon white
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Update Bank Account'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Add Bank Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your earnings will be transferred to this account',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _accountHolderController,
            decoration: const InputDecoration(
              labelText: 'Account Holder Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Bank Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _routingNumberController,
            decoration: const InputDecoration(
              labelText: 'Routing Number (Optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ibanController,
            decoration: const InputDecoration(
              labelText: 'IBAN (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _swiftCodeController,
            decoration: const InputDecoration(
              labelText: 'SWIFT Code (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBankAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Bank Account', style: TextStyle(fontSize: 16,color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}