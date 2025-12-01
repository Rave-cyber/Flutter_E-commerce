import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_checker_model.dart';
import '/services/admin/stock_checker_service.dart';

class AdminStockCheckerForm extends StatefulWidget {
  final StockCheckerModel? checker;
  const AdminStockCheckerForm({Key? key, this.checker}) : super(key: key);

  @override
  State<AdminStockCheckerForm> createState() => _AdminStockCheckerFormState();
}

class _AdminStockCheckerFormState extends State<AdminStockCheckerForm> {
  final _formKey = GlobalKey<FormState>();
  final StockCheckerService _checkerService = StockCheckerService();

  late TextEditingController _firstnameController;
  late TextEditingController _middlenameController;
  late TextEditingController _lastnameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;

  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    final checker = widget.checker;

    _firstnameController =
        TextEditingController(text: checker?.firstname ?? '');
    _middlenameController =
        TextEditingController(text: checker?.middlename ?? '');
    _lastnameController = TextEditingController(text: checker?.lastname ?? '');
    _addressController = TextEditingController(text: checker?.address ?? '');
    _contactController = TextEditingController(text: checker?.contact ?? '');

    _isArchived = checker?.is_archived ?? false;
  }

  Future<void> _saveChecker() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.checker?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final checker = StockCheckerModel(
      id: id,
      firstname: _firstnameController.text.trim(),
      middlename: _middlenameController.text.trim(),
      lastname: _lastnameController.text.trim(),
      address: _addressController.text.trim(),
      contact: _contactController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.checker?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.checker == null) {
      await _checkerService.createStockChecker(checker);
    } else {
      await _checkerService.updateStockChecker(checker);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BACK BUTTON
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // FIRSTNAME
                  TextFormField(
                    controller: _firstnameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // MIDDLENAME
                  TextFormField(
                    controller: _middlenameController,
                    decoration: const InputDecoration(labelText: 'Middle Name'),
                  ),
                  const SizedBox(height: 12),

                  // LASTNAME
                  TextFormField(
                    controller: _lastnameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ADDRESS
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // CONTACT
                  TextFormField(
                    controller: _contactController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Number'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  /// ARCHIVED SWITCH
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveChecker,
                    child: Text(widget.checker == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
