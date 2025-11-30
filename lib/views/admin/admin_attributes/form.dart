import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/attribute_model.dart';
import '/models/attribute_value_model.dart';
import '/services/admin/attribute_service.dart';

class AdminAttributeForm extends StatefulWidget {
  final AttributeModel? attribute;
  const AdminAttributeForm({Key? key, this.attribute}) : super(key: key);

  @override
  State<AdminAttributeForm> createState() => _AdminAttributeFormState();
}

class _AdminAttributeFormState extends State<AdminAttributeForm> {
  final _formKey = GlobalKey<FormState>();
  final AttributeService _attributeService = AttributeService();

  late TextEditingController _nameController;
  bool _isArchived = false;

  // List of controllers for attribute values
  List<TextEditingController> _valueControllers = [];

  @override
  void initState() {
    super.initState();
    final attribute = widget.attribute;
    _nameController = TextEditingController(text: attribute?.name ?? '');
    _isArchived = attribute?.is_archived ?? false;

    // If editing an attribute, load existing values
    if (attribute != null) {
      _loadAttributeValues(attribute.id);
    } else {
      _addValueController(); // start with one empty field
    }
  }

  void _loadAttributeValues(String attributeId) async {
    final values = await _attributeService.getAttributeValues(attributeId);
    setState(() {
      _valueControllers =
          values.map((v) => TextEditingController(text: v.name)).toList();
    });
  }

  void _addValueController() {
    setState(() {
      _valueControllers.add(TextEditingController());
    });
  }

  void _removeValueController(int index) {
    setState(() {
      _valueControllers.removeAt(index);
    });
  }

  Future<void> _saveAttribute() async {
    if (!_formKey.currentState!.validate()) return;

    final attributeId = widget.attribute?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final attribute = AttributeModel(
      id: attributeId,
      name: _nameController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.attribute?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.attribute == null) {
      await _attributeService.createAttribute(attribute);
    } else {
      await _attributeService.updateAttribute(attribute);
    }

    // Save attribute values
    for (var controller in _valueControllers) {
      final valueName = controller.text.trim();
      if (valueName.isEmpty) continue;

      final valueId = DateTime.now().millisecondsSinceEpoch.toString();
      final value = AttributeValueModel(
        id: valueId,
        attribute_id: attributeId,
        name: valueName,
        is_archived: false,
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
      );

      await _attributeService.createAttributeValue(value);
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
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Attribute Name'),
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

                  const SizedBox(height: 12),

                  /// ATTRIBUTE VALUES
                  const Text(
                    'Attribute Values',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _valueControllers.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _valueControllers[index],
                              decoration: InputDecoration(
                                  labelText: 'Value ${index + 1}'),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeValueController(index),
                          ),
                        ],
                      );
                    },
                  ),

                  TextButton.icon(
                    onPressed: _addValueController,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Value'),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveAttribute,
                    child: Text(widget.attribute == null ? 'Create' : 'Update'),
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
