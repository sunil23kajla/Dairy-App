import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/farmer_cubit.dart';
import '../../cubits/auth_cubit.dart';
import '../../models/farmer.dart';
import '../../widgets/dairy_button.dart';

class AddEditFarmerScreen extends StatefulWidget {
  final Farmer? farmer;

  const AddEditFarmerScreen({super.key, this.farmer});

  @override
  State<AddEditFarmerScreen> createState() => _AddEditFarmerScreenState();
}

class _AddEditFarmerScreenState extends State<AddEditFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _mobileController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farmer?.name ?? '');
    _nicknameController = TextEditingController(text: widget.farmer?.nickname ?? '');
    _mobileController = TextEditingController(text: widget.farmer?.mobile ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _saveForm(BuildContext context, Language lang) {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final nickname = _nicknameController.text.trim();
      final mobile = _mobileController.text.trim();
      final activeDairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';

      if (widget.farmer == null) {
        context.read<FarmerCubit>().addFarmer(name, nickname, mobile, activeDairyCode);
      } else {
        context.read<FarmerCubit>().editFarmer(widget.farmer!.id, activeDairyCode, name, nickname, mobile);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.farmer == null ? AppConstants.translate('farmerAddedSuccess', lang) : AppConstants.translate('farmerUpdatedSuccess', lang)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _confirmDeleteFarmer(BuildContext context, Language lang) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            lang == Language.hindi ? 'किसान को हटाएं?' : 'Delete Farmer?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              lang == Language.hindi
                  ? 'क्या आप वाकई इस किसान प्रोफाइल को हटाना चाहते हैं? यह क्रिया वापस नहीं ली जा सकती।'
                  : 'Are you sure you want to delete this farmer profile? This action cannot be undone.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppConstants.translate('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(dialogCtx); // close dialog
                final activeDairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';
                context.read<FarmerCubit>().deleteFarmer(widget.farmer!.id, activeDairyCode);
                Navigator.pop(context); // pop screen back to farmer list
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == Language.hindi
                          ? 'किसान प्रोफाइल सफलतापूर्वक हटा दी गई!'
                          : 'Farmer profile deleted successfully!',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: Text(
                lang == Language.hindi ? 'हटाएं' : 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isEdit = widget.farmer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? AppConstants.translate('editFarmer', lang) : AppConstants.translate('addFarmer', lang)),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeleteFarmer(context, lang),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEdit) ...[
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      widget.farmer!.id,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Farmer Name Field
              Text(
                AppConstants.translate('farmerName', lang),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.translate('pleaseEnterName', lang);
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: AppConstants.translate('nameHint', lang),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Nickname Field
              Text(
                AppConstants.translate('nickname', lang),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: AppConstants.translate('nicknameHint', lang),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Mobile Number Field
              Text(
                AppConstants.translate('mobile', lang),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.translate('pleaseEnterMobile', lang);
                  }
                  if (value.trim().length < 10) {
                    return AppConstants.translate('pleaseEnterValidMobile', lang);
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: AppConstants.translate('mobileHint', lang),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              DairyButton(
                text: isEdit ? AppConstants.translate('updateDetails', lang) : AppConstants.translate('saveFarmer', lang),
                onPressed: () => _saveForm(context, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
