import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../layouts/delivery_staff_layout.dart';
import '../../../firestore_service.dart';

class DeliveryProofForm extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const DeliveryProofForm({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryProofForm> createState() => _DeliveryProofFormState();
}

class _DeliveryProofFormState extends State<DeliveryProofForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  XFile? _selectedImage;
  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Stepper navigation methods
  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      }
    } else {
      _showValidationMessage();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showValidationMessage() {
    if (!context.mounted) return;

    String message = '';
    switch (_currentStep) {
      case 1: // Photo step
        if (_selectedImage == null) {
          message = 'Please take or select a delivery proof photo';
        }
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Individual step validation
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Order summary step
        return true; // Always valid
      case 1: // Photo step
        return _selectedImage != null;
      case 2: // Notes step
        return true; // Notes are optional
      default:
        return true;
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.green.shade200,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildImagePicker(
      {required String imageUrl,
      required VoidCallback onTap,
      bool isFile = false}) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isFile && imageUrl.isNotEmpty
                ? Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Order Summary
  Widget _buildOrderSummaryStep() {
    final delivery = widget.delivery;
    final items = (delivery['items'] as List<dynamic>?) ?? [];
    final totalAmount = delivery['total']?.toDouble() ?? 0.0;

    return _buildSectionCard(
      title: 'Order Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${delivery['id'].toString().substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Order details
          _buildDetailRow('Items', '${items.length} item(s)'),
          const SizedBox(height: 8),
          _buildDetailRow('Total Amount', '₱${totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildDetailRow('Shipping Address',
              delivery['shippingAddress'] ?? 'No address provided'),
          const SizedBox(height: 8),
          _buildDetailRow('Contact Number',
              delivery['contactNumber'] ?? 'No contact number'),

          if (delivery['shippedAt'] != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Picked Up',
                '${delivery['shippedAt'].toDate().day}/${delivery['shippedAt'].toDate().month}/${delivery['shippedAt'].toDate().year} ${delivery['shippedAt'].toDate().hour}:${delivery['shippedAt'].toDate().minute.toString().padLeft(2, '0')}'),
          ],

          const SizedBox(height: 24),

          // Items list
          if (items.isNotEmpty) ...[
            Text(
              'Order Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['name'] ?? 'Unknown Item',
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                      Text(
                        'x${item['quantity'] ?? 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // Step 2: Photo Capture
  Widget _buildPhotoCaptureStep() {
    return _buildSectionCard(
      title: 'Delivery Proof Photo',
      child: Column(
        children: [
          _buildImagePicker(
            imageUrl: _selectedImage?.path ?? '',
            onTap: _showImageSourceDialog,
            isFile: _selectedImage != null,
          ),
          const SizedBox(height: 16),
          Text(
            'Take a clear photo of the delivered items as proof of successful delivery',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Step 3: Notes & Confirmation
  Widget _buildNotesStep() {
    return _buildSectionCard(
      title: 'Delivery Notes & Confirmation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            _notesController,
            'Delivery Notes',
            icon: Icons.note_add,
            maxLines: 4,
            hintText: 'Enter any delivery notes or comments (optional)...',
          ),
          const SizedBox(height: 24),

          // Confirmation summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Confirmation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'By confirming this delivery, you are certifying that:',
                  style: TextStyle(color: Colors.green.shade700),
                ),
                const SizedBox(height: 8),
                ...[
                  '• The order has been successfully delivered',
                  '• The customer has received all items',
                  '• The delivery proof photo has been captured',
                  '• Any delivery notes have been recorded',
                ].map((item) => Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 4),
                      child: Text(
                        item,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDeliveryProof() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or select a delivery proof photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // In a real app, you would upload the image to Firebase Storage
      // For now, we'll simulate with a placeholder URL
      final String proofImageUrl =
          'https://example.com/proof_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Get current delivery staff ID (you'll need to implement user authentication)
      // For now, using a placeholder - replace with actual user ID
      const String deliveryStaffId = 'current_delivery_staff_id';

      await FirestoreService.markOrderAsDelivered(
        widget.delivery['id'],
        deliveryStaffId,
        proofImageUrl,
        _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to deliveries list
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Step> steps = [
      Step(
        title: const Text('Summary'),
        content: _buildOrderSummaryStep(),
        isActive: _currentStep >= 0,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Photo'),
        content: _buildPhotoCaptureStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Confirm'),
        content: _buildNotesStep(),
        isActive: _currentStep >= 2,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
    ];

    return DeliveryStaffLayout(
      title: 'Delivery Proof',
      selectedRoute: '/delivery-staff/deliveries',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Delivery Proof',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.green.shade50,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade50!,
                Colors.white,
                Colors.grey.shade50!,
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: _currentStep == steps.length - 1
                  ? _submitDeliveryProof
                  : _nextStep,
              onStepCancel: _previousStep,
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        ElevatedButton(
                          onPressed: details.onStepCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed:
                            _isSubmitting ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _currentStep == steps.length - 1
                                    ? 'Confirm Delivery'
                                    : 'Next',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                );
              },
              steps: steps,
            ),
          ),
        ),
      ),
    );
  }
}
