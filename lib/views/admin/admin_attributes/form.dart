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
            // BACK BUTTON with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FORM CONTAINER with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.attribute == null
                                    ? Icons.add
                                    : Icons.edit,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.attribute == null
                                    ? 'Add Attribute'
                                    : 'Edit Attribute',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Attribute Name Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(12),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Attribute Name',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.label,
                                  color: Colors.green.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade400,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ARCHIVED SWITCH with improved styling
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.orange.shade50,
                            child: SwitchListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    _isArchived
                                        ? Icons.unarchive
                                        : Icons.archive,
                                    color: Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Archived',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              value: _isArchived,
                              onChanged: (val) =>
                                  setState(() => _isArchived = val),
                              activeColor: Colors.orange.shade600,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ATTRIBUTE VALUES section
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.purple.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.list,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Attribute Values',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Dynamic value fields
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _valueControllers.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          elevation: 1,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _valueControllers[index],
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Value ${index + 1}',
                                                    labelStyle: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    prefixIcon: Icon(
                                                      Icons.tag,
                                                      color: Colors
                                                          .purple.shade600,
                                                      size: 20,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .purple.shade400,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                  ),
                                                  validator: (val) =>
                                                      val == null || val.isEmpty
                                                          ? 'Required'
                                                          : null,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Material(
                                                elevation: 2,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      _removeValueController(
                                                          index),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Add Value Button
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _addValueController,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor:
                                            Colors.purple.withOpacity(0.5),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 20),
                                      label: const Text('Add Value'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // SAVE BUTTON with improved styling
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveAttribute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.green.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.attribute == null
                                      ? Icons.add
                                      : Icons.save,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.attribute == null
                                      ? 'Create Attribute'
                                      : 'Update Attribute',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
