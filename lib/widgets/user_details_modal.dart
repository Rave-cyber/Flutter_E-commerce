import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserDetailsModal extends StatefulWidget {
  final UserModel user;

  const UserDetailsModal({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UserDetailsModal> createState() => _UserDetailsModalState();
}

class _UserDetailsModalState extends State<UserDetailsModal> {
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'delivery_staff':
        return 'Delivery Staff';
      case 'customer':
        return 'Customer';
      default:
        return role.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'delivery_staff':
        return Colors.orange;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.security;
      case 'delivery_staff':
        return Icons.local_shipping;
      case 'customer':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'User Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Basic Info
                    _buildUserBasicInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar - Centered
          Center(
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _getRoleColor(widget.user.role).withOpacity(0.1),
                ),
                child: Icon(
                  _getRoleIcon(widget.user.role),
                  size: 40,
                  color: _getRoleColor(widget.user.role),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Display Name - Centered
          Center(
            child: Text(
              widget.user.display_name ?? 'No Name',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Email - Full Width Box
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email Address',
            value: widget.user.email,
          ),

          const SizedBox(height: 8),

          // Role - Full Width Box
          _buildInfoRow(
            icon: _getRoleIcon(widget.user.role),
            label: 'User Role',
            value: _getRoleDisplayName(widget.user.role),
          ),

          const SizedBox(height: 8),

          // User ID - Full Width Box
          _buildInfoRow(
            icon: Icons.assignment_ind,
            label: 'User ID',
            value: widget.user.id,
          ),

          const SizedBox(height: 8),

          // Account Status - Full Width Box
          _buildInfoRow(
            icon: widget.user.is_archived ? Icons.archive : Icons.check_circle,
            label: 'Account Status',
            value: widget.user.is_archived ? 'Archived' : 'Active',
          ),

          const SizedBox(height: 8),

          // Created Date - Full Width Box
          if (widget.user.created_at != null) ...[
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Account Created',
              value: _formatDate(widget.user.created_at!),
            ),
          ],

          const SizedBox(height: 16),

          // Additional Information Section
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This user account was created on ${widget.user.created_at != null ? _formatDate(widget.user.created_at!) : 'Unknown date'}. '
            'The account is currently ${widget.user.is_archived ? 'archived and not accessible' : 'active and accessible'}. '
            'User role: ${_getRoleDisplayName(widget.user.role)}.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
