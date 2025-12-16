import 'package:firebase/views/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_provider.dart';
import '../../../services/philippine_address_service.dart';
import '../orders/orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final CustomerModel? customer;

  const ProfileScreen({
    Key? key,
    required this.user,
    this.customer,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryGreen = const Color(0xFF2C8610);
  final Color accentBlue = const Color(0xFF4A90E2);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF1A1A1A);
  final Color textSecondary = const Color(0xFF64748B);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color successColor = const Color(0xFF10B981);
  final Color errorColor = const Color(0xFFEF4444);
  final Color warningColor = const Color(0xFFF59E0B);

  String _addressText = '';

  @override
  void initState() {
    super.initState();
    _addressText = widget.customer?.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: isDark ? const Color(0xFF111111) : cardColor,
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 1,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGreen.withOpacity(0.08),
                      accentBlue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildMenuItems(authService),
                const SizedBox(height: 32),
                _buildVersionInfo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryGreen.withOpacity(0.9), accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              backgroundImage: (currentUser?.photoURL != null &&
                      currentUser!.photoURL!.isNotEmpty)
                  ? NetworkImage(currentUser.photoURL!)
                  : null,
              child: (currentUser?.photoURL ?? '').isEmpty
                  ? Text(
                      (widget.user.display_name?.isNotEmpty == true
                              ? widget.user.display_name!
                              : widget.user.email.split('@').first)
                          .trim()
                          .split(' ')
                          .where((p) => p.isNotEmpty)
                          .map((p) => p[0].toUpperCase())
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.email.split('@').first,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.user.role.toUpperCase(),
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(AuthService authService) {
    return Column(
      children: [
        _buildSectionTitle('Account Settings'),
        const SizedBox(height: 12),
        _buildMenuItemCard(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Personal Information',
              subtitle: 'View your profile details',
              onTap: () => _showPersonalInfo(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              subtitle: 'Track and view orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildAddressSection(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 12),
        _buildMenuItemCard(
          children: [
            _buildAppearanceTile(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Support'),
        const SizedBox(height: 12),
        _buildMenuItemCard(
          children: [
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'App information and version',
              onTap: () => _showAboutDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out from account',
              isLogout: true,
              onTap: () => _showLogoutConfirmation(
                  context, authService), // Fixed: Pass authService
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppearanceTile() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.dark_mode_outlined,
          color: primaryGreen,
          size: 22,
        ),
      ),
      title: Text(
        'Appearance',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        'Toggle light / dark mode',
        style: TextStyle(
          fontSize: 13,
          color: textSecondary,
        ),
      ),
      trailing: Switch(
        value: isDark,
        activeColor: primaryGreen,
        onChanged: (value) {
          themeProvider.toggle(value);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isLogout
              ? errorColor.withOpacity(0.1)
              : primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isLogout ? errorColor : primaryGreen,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLogout ? errorColor : textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isLogout ? errorColor.withOpacity(0.7) : textSecondary,
        ),
      ),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isLogout ? errorColor : Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_addressText.isNotEmpty) _buildAddressPreview(),
                    if (_addressText.isEmpty)
                      Text(
                        'Add your delivery address',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showEditAddressSheet,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Current Address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _addressText,
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap edit icon to update',
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[100],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'Version 1.0.0 • © 2024',
        style: TextStyle(
          fontSize: 12,
          color: textSecondary.withOpacity(0.6),
        ),
      ),
    );
  }

  void _showPersonalInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ),
              _buildInfoTile(
                icon: Icons.person_rounded,
                title: 'Name',
                value: widget.user.email.split('@').first,
              ),
              _buildInfoTile(
                icon: Icons.email_rounded,
                title: 'Email',
                value: widget.user.email,
              ),
              _buildInfoTile(
                icon: Icons.verified_user_rounded,
                title: 'Role',
                value: widget.user.role.toUpperCase(),
                valueColor:
                    widget.user.role == 'admin' ? warningColor : successColor,
              ),
              if (widget.customer != null &&
                  widget.customer!.contact.isNotEmpty)
                _buildInfoTile(
                  icon: Icons.phone_rounded,
                  title: 'Contact',
                  value: widget.customer!.contact,
                ),
              const SizedBox(height: 24),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    size: 40,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Why we built this app',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app was crafted to give customers a smooth, modern shopping experience with reliable delivery, transparent pricing, and easy account management.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditAddressSheet() {
    final TextEditingController houseController = TextEditingController();
    bool saving = false;

    List<Map<String, dynamic>> regions = [];
    List<Map<String, dynamic>> provinces = [];
    List<Map<String, dynamic>> cities = [];
    List<Map<String, dynamic>> barangays = [];

    Map<String, dynamic>? selectedRegion;
    Map<String, dynamic>? selectedProvince;
    Map<String, dynamic>? selectedCity;
    Map<String, dynamic>? selectedBarangay;

    bool loadingRegions = true;
    bool loadingProvinces = false;
    bool loadingCities = false;
    bool loadingBarangays = false;
    bool initialized = false;

    // Parse existing address
    void parseExistingAddress() {
      if (_addressText.isNotEmpty) {
        final parts = _addressText.split(', ');
        if (parts.isNotEmpty) {
          houseController.text = parts[0];
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          if (!initialized) {
            initialized = true;
            parseExistingAddress();
            Future.microtask(() async {
              try {
                final r = await PhilippineAddressService.getRegions();
                setModalState(() {
                  regions = r;
                  loadingRegions = false;
                });
              } catch (e) {
                setModalState(() => loadingRegions = false);
                _showErrorSnackbar('Failed to load regions');
              }
            });
          }

          return GestureDetector(
            onTap: () => FocusScope.of(ctx).unfocus(),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Address',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Update your delivery location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Current Address Preview
                      if (_addressText.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: primaryGreen.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _addressText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: borderColor),
                        const SizedBox(height: 20),
                      ],

                      // Form Title
                      Text(
                        'New Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in your complete address details',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // House/Unit and Street
                      _buildFormField(
                        controller: houseController,
                        label: 'House/Unit and Street',
                        hint: 'e.g., Unit 3B, 123 Sample Street',
                        icon: Icons.home_rounded,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Region Dropdown
                      _buildDropdownFormField(
                        value: selectedRegion,
                        label: 'Region',
                        hint: 'Select region',
                        icon: Icons.map_rounded,
                        isLoading: loadingRegions,
                        items: regions
                            .map((region) => DropdownMenuItem(
                                  value: region,
                                  child: Text(
                                      region['regionName'] ?? region['name']),
                                ))
                            .toList(),
                        onChanged: (value) async {
                          setModalState(() {
                            selectedRegion = value;
                            selectedProvince = null;
                            selectedCity = null;
                            selectedBarangay = null;
                            provinces = [];
                            cities = [];
                            barangays = [];
                            loadingProvinces = true;
                          });
                          if (value != null) {
                            try {
                              final p =
                                  await PhilippineAddressService.getProvinces(
                                      value['code']);
                              setModalState(() {
                                provinces = p;
                                loadingProvinces = false;
                              });
                            } catch (e) {
                              setModalState(() => loadingProvinces = false);
                              _showErrorSnackbar('Failed to load provinces');
                            }
                          } else {
                            setModalState(() => loadingProvinces = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Province Dropdown
                      _buildDropdownFormField(
                        value: selectedProvince,
                        label: 'Province',
                        hint: 'Select province',
                        icon: Icons.place_rounded,
                        isLoading: loadingProvinces,
                        items: provinces
                            .map((province) => DropdownMenuItem(
                                  value: province,
                                  child: Text(province['name']),
                                ))
                            .toList(),
                        onChanged: (value) async {
                          setModalState(() {
                            selectedProvince = value;
                            selectedCity = null;
                            selectedBarangay = null;
                            cities = [];
                            barangays = [];
                            loadingCities = true;
                          });
                          if (value != null) {
                            try {
                              final c = await PhilippineAddressService
                                  .getCitiesMunicipalities(value['code']);
                              setModalState(() {
                                cities = c;
                                loadingCities = false;
                              });
                            } catch (e) {
                              setModalState(() => loadingCities = false);
                              _showErrorSnackbar('Failed to load cities');
                            }
                          } else {
                            setModalState(() => loadingCities = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // City/Municipality Dropdown
                      _buildDropdownFormField(
                        value: selectedCity,
                        label: 'City/Municipality',
                        hint: 'Select city or municipality',
                        icon: Icons.location_city_rounded,
                        isLoading: loadingCities,
                        items: cities
                            .map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city['name']),
                                ))
                            .toList(),
                        onChanged: (value) async {
                          setModalState(() {
                            selectedCity = value;
                            selectedBarangay = null;
                            barangays = [];
                            loadingBarangays = true;
                          });
                          if (value != null) {
                            try {
                              final b =
                                  await PhilippineAddressService.getBarangays(
                                      value['code']);
                              setModalState(() {
                                barangays = b;
                                loadingBarangays = false;
                              });
                            } catch (e) {
                              setModalState(() => loadingBarangays = false);
                              _showErrorSnackbar('Failed to load barangays');
                            }
                          } else {
                            setModalState(() => loadingBarangays = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Barangay Dropdown (API-powered)
                      _buildDropdownFormField(
                        value: selectedBarangay,
                        label: 'Barangay',
                        hint: 'Select barangay',
                        icon: Icons.home_work_rounded,
                        isLoading: loadingBarangays,
                        items: barangays
                            .map((brgy) => DropdownMenuItem(
                                  value: brgy,
                                  child: Text(brgy['name']),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedBarangay = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(color: borderColor),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final house = houseController.text.trim();

                                      if (selectedRegion == null ||
                                          selectedProvince == null ||
                                          selectedCity == null ||
                                          selectedBarangay == null) {
                                        _showErrorSnackbar(
                                            'Please select all address fields');
                                        return;
                                      }
                                      if (house.isEmpty) {
                                        _showErrorSnackbar(
                                            'Please enter house/unit and street');
                                        return;
                                      }

                                      setModalState(() => saving = true);
                                      try {
                                        final parts = <String>[];
                                        parts.add(house);

                                        if (selectedBarangay != null) {
                                          parts.add(
                                              'Brgy. ${selectedBarangay!['name']}');
                                        }

                                        parts.add(selectedCity!['name']);
                                        parts.add(selectedProvince!['name']);
                                        parts.add(
                                            selectedRegion!['regionName'] ??
                                                selectedRegion!['name']);

                                        final finalAddress = parts.join(', ');

                                        final auth = Provider.of<AuthService>(
                                            context,
                                            listen: false);
                                        final user = auth.currentUser;
                                        if (user == null) throw 'Not logged in';

                                        final fs = FirebaseFirestore.instance;
                                        final query = await fs
                                            .collection('customers')
                                            .where('user_id',
                                                isEqualTo: user.uid)
                                            .limit(1)
                                            .get();

                                        if (query.docs.isNotEmpty) {
                                          await fs
                                              .collection('customers')
                                              .doc(query.docs.first.id)
                                              .update({
                                            'address': finalAddress,
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          });
                                        } else {
                                          await fs.collection('customers').add({
                                            'user_id': user.uid,
                                            'firstname': '',
                                            'middlename': '',
                                            'lastname': '',
                                            'address': finalAddress,
                                            'contact': user.email ?? '',
                                            'created_at':
                                                FieldValue.serverTimestamp(),
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          });
                                        }

                                        setState(() {
                                          _addressText = finalAddress;
                                        });

                                        if (mounted) Navigator.pop(ctx);
                                        _showSuccessSnackbar(
                                            '✅ Address updated successfully!');
                                      } catch (e) {
                                        _showErrorSnackbar(
                                            '❌ Failed to update address: ${e.toString()}');
                                      } finally {
                                        if (mounted) {
                                          setModalState(() => saving = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: saving
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Save Address',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: errorColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: primaryGreen),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              fontSize: 15,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFormField({
    required Map<String, dynamic>? value,
    required String label,
    required String hint,
    required IconData icon,
    required bool isLoading,
    required List<DropdownMenuItem<Map<String, dynamic>>> items,
    required Function(Map<String, dynamic>?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<Map<String, dynamic>>(
              value: value,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(primaryGreen),
                        ),
                      )
                    : Icon(icon, color: primaryGreen),
              ),
              hint: Text(
                isLoading ? 'Loading...' : hint,
                style: TextStyle(
                  color:
                      isLoading ? primaryGreen : textSecondary.withOpacity(0.6),
                ),
              ),
              items: items,
              onChanged: onChanged,
              dropdownColor: cardColor,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: primaryGreen,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: errorColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout from your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: borderColor),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await authService.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorColor,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
