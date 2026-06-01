import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/farmer_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../../core/print_helper.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentType = 'Cash';
  String _searchQuery = '';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _callNumber(String number) async {
    final Uri url = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }

  void _showAddPaymentDialog(BuildContext context, String farmerId, String farmerName, double balance, bool isOwner) {
    final lang = context.read<ThemeCubit>().state.language;
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.translate('workerAccessOnly', lang)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _amountController.text = balance > 0 ? balance.toStringAsFixed(0) : '';
    _notesController.clear();
    _paymentType = 'Cash';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
              title: Text(
                '${AppConstants.translate('recordPayoutTitle', lang)} $farmerName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppConstants.translate('outstanding', lang)}: ₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppConstants.translate('amountLabel', lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: InputDecoration(
                        labelText: AppConstants.translate('paymentTypeLabel', lang),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Cash', child: Text(AppConstants.translate('cash', lang))),
                        DropdownMenuItem(value: 'Bank Transfer', child: Text(AppConstants.translate('bankTransfer', lang))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _paymentType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: AppConstants.translate('notesLabel', lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(AppConstants.translate('cancel', lang)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text) ?? 0.0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppConstants.translate('validAmountError', lang)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    final activeDairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';
                    final notes = _notesController.text.trim();
                    context.read<CollectionCubit>().addPayment(
                          farmerId,
                          farmerName,
                          amount,
                          _paymentType,
                          notes,
                          activeDairyCode,
                        );

                    // Print payment slip if connected
                    final authState = context.read<AuthCubit>().state;
                    final printHelper = PrintHelper();
                    printHelper.isConnected().then((connected) {
                      if (connected) {
                        printHelper.printPaymentSlip(
                          dairyName: authState.dairyName ?? 'Smart Dairy',
                          dairyCode: activeDairyCode,
                          farmerId: farmerId,
                          farmerName: farmerName,
                          date: DateTime.now(),
                          amount: amount,
                          paymentType: _paymentType,
                          notes: notes,
                        );
                      }
                    });

                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppConstants.translate('payoutLogged', lang)} ₹$amount'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(AppConstants.translate('savePayment', lang)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;
    final isOwner = context.watch<AuthCubit>().state.role == 'owner';

    final activeDairyCode = context.watch<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    final farmers = context.watch<FarmerCubit>().state.farmers;
    final collectionCubit = context.watch<CollectionCubit>();
    final payments = collectionCubit.state.payments.where((p) => p.dairyCode == activeDairyCode).toList();

    final filteredFarmers = farmers.where((farmer) {
      if (farmer.dairyCode != activeDairyCode) return false;
      final query = _searchQuery.toLowerCase();
      return farmer.id.contains(query) ||
          farmer.name.toLowerCase().contains(query) ||
          farmer.nickname.toLowerCase().contains(query);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppConstants.translate('payments', lang)),
          bottom: TabBar(
            tabs: [
              Tab(text: AppConstants.translate('farmerLedger', lang)),
              Tab(text: AppConstants.translate('paymentHistory', lang)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Farmer Ledger list
            Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppConstants.translate('searchFarmer', lang),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF14221D) : const Color(0xFFF1F5F3),
                    ),
                  ),
                ),

                Expanded(
                  child: filteredFarmers.isEmpty
                      ? Center(child: Text(AppConstants.translate('noFarmersFound', lang)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredFarmers.length,
                          itemBuilder: (context, index) {
                            final farmer = filteredFarmers[index];
                            final balance = collectionCubit.getFarmerBalance(farmer.id, activeDairyCode);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  child: Text(farmer.id),
                                ),
                                title: Text(farmer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _callNumber(farmer.mobile),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 14, color: theme.colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            farmer.mobile,
                                            style: TextStyle(
                                              decoration: TextDecoration.underline,
                                              color: theme.colorScheme.primary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${AppConstants.translate('balanceLabel', lang)}: ₹${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: balance > 0 ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: 110,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: balance > 0 ? theme.colorScheme.primary : Colors.grey,
                                      foregroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _showAddPaymentDialog(context, farmer.id, farmer.name, balance, isOwner),
                                    child: Text(AppConstants.translate('pay', lang), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // Tab 2: Payment History list
            payments.isEmpty
                ? Center(child: Text(AppConstants.translate('noPaymentsHistory', lang)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      // Reverse order to show newest first
                      final payment = payments[payments.length - 1 - index];
                      final dateStr = "${payment.date.day}/${payment.date.month} ${payment.date.hour.toString().padLeft(2, '0')}:${payment.date.minute.toString().padLeft(2, '0')}";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.check, color: Colors.green),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  payment.farmerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '- ₹${payment.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${AppConstants.translate('type', lang)}: ${payment.paymentType == 'Cash' ? AppConstants.translate('cash', lang) : AppConstants.translate('bankTransfer', lang)}${payment.notes.isNotEmpty ? ' | ${payment.notes}' : ''}',
                                    maxLines: 2,
                                    overflow: TextOverflow.clip,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
