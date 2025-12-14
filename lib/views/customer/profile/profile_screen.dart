import 'package:firebase/views/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../customer/checkout/checkout_screen.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
import '../../../services/auth_service.dart';
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
  String _addressText = '';

  @override
  void initState() {
    super.initState();
    _addressText = widget.customer?.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: cardColor,
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 1,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
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
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildMenuItems(authService),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              backgroundImage: (Provider.of<AuthService>(context)
                              .currentUser
                              ?.photoURL !=
                          null &&
                      Provider.of<AuthService>(context)
                          .currentUser!
                          .photoURL!
                          .isNotEmpty)
                  ? NetworkImage(
                      Provider.of<AuthService>(context).currentUser!.photoURL!)
                  : null,
              child: (Provider.of<AuthService>(context).currentUser?.photoURL ??
                          '')
                      .isEmpty
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.email.split('@').first,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
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
            _buildMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Address',
              subtitle: _addressText.isNotEmpty
                  ? _addressText
                  : 'Add your delivery address',
              onTap: _showEditAddressSheet,
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              subtitle: 'Secure payment options',
              onTap: () => _showGuestMessage(context, 'Payment Methods'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 12),
        _buildMenuItemCard(
          children: [
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Customize alerts',
              onTap: () => _showGuestMessage(context, 'Notification Settings'),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              subtitle: 'Manage your data',
              onTap: () => _showGuestMessage(context, 'Privacy Settings'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Support'),
        const SizedBox(height: 12),
        _buildMenuItemCard(
          children: [
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get assistance',
              onTap: () => _showGuestMessage(context, 'Help Center'),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out from account',
              isLogout: true,
              onTap: () => _showLogoutConfirmation(context, authService),
            ),
          ],
        ),
      ],
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
              ? Colors.red.withOpacity(0.1)
              : primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : primaryGreen,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isLogout ? Colors.red.withOpacity(0.7) : textSecondary,
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
          color: isLogout ? Colors.red : Colors.grey[600],
        ),
      ),
      onTap: onTap,
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
                    widget.user.role == 'admin' ? Colors.orange : primaryGreen,
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

  void _showGuestMessage(BuildContext context, String feature) {
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
                    Icons.construction_rounded,
                    size: 40,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$feature is under development and will be available in the next update!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
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
                    'Got it',
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          if (!initialized) {
            initialized = true;
            Future.microtask(() async {
              try {
                final r = await PhilippineAddressService.getRegions();
                setModalState(() {
                  regions = r;
                  loadingRegions = false;
                });
              } catch (_) {
                setModalState(() => loadingRegions = false);
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit Address',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  value: selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: loadingRegions
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Loading regions...'),
                          ),
                        ]
                      : regions
                          .map((region) => DropdownMenuItem(
                                value: region,
                                child: Text(
                                    region['regionName'] ?? region['name']),
                              ))
                          .toList(),
                  onChanged: loadingRegions
                      ? null
                      : (value) async {
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
                            } catch (_) {
                              setModalState(() => loadingProvinces = false);
                            }
                          } else {
                            setModalState(() => loadingProvinces = false);
                          }
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  value: selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: provinces.isEmpty && !loadingProvinces
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select a region first'),
                          ),
                        ]
                      : provinces
                          .map((province) => DropdownMenuItem(
                                value: province,
                                child: Text(province['name']),
                              ))
                          .toList(),
                  onChanged: loadingProvinces
                      ? null
                      : (value) async {
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
                            } catch (_) {
                              setModalState(() => loadingCities = false);
                            }
                          } else {
                            setModalState(() => loadingCities = false);
                          }
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  value: selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City/Municipality',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: cities.isEmpty && !loadingCities
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select a province first'),
                          ),
                        ]
                      : cities
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city['name']),
                              ))
                          .toList(),
                  onChanged: loadingCities
                      ? null
                      : (value) async {
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
                            } catch (_) {
                              setModalState(() => loadingBarangays = false);
                            }
                          } else {
                            setModalState(() => loadingBarangays = false);
                          }
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  value: selectedBarangay,
                  decoration: const InputDecoration(
                    labelText: 'Barangay (Optional)',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: barangays.isEmpty && !loadingBarangays
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select a city/municipality first'),
                          ),
                        ]
                      : barangays
                          .map((brgy) => DropdownMenuItem(
                                value: brgy,
                                child: Text(brgy['name']),
                              ))
                          .toList(),
                  onChanged: loadingBarangays
                      ? null
                      : (value) {
                          setModalState(() {
                            selectedBarangay = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: houseController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'House/Unit and Street',
                    hintText: 'e.g., Unit 3B, 123 Sample St',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final house = houseController.text.trim();
                            if (selectedRegion == null ||
                                selectedProvince == null ||
                                selectedCity == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please select your region, province, and city/municipality')),
                              );
                              return;
                            }
                            if (house.isEmpty || house.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter house/unit and street')),
                              );
                              return;
                            }
                            setModalState(() => saving = true);
                            try {
                              final parts = <String>[];
                              parts.add(house);
                              if (selectedBarangay != null)
                                parts.add(selectedBarangay!['name']);
                              parts.add(selectedCity!['name']);
                              parts.add(selectedProvince!['name']);
                              parts.add(selectedRegion!['regionName'] ??
                                  selectedRegion!['name']);
                              final finalAddress = parts.join(', ');

                              final auth = Provider.of<AuthService>(context,
                                  listen: false);
                              final user = auth.currentUser;
                              if (user == null) {
                                throw 'Not logged in';
                              }

                              final fs = FirebaseFirestore.instance;
                              final query = await fs
                                  .collection('customers')
                                  .where('user_id', isEqualTo: user.uid)
                                  .limit(1)
                                  .get();
                              if (query.docs.isNotEmpty) {
                                await fs
                                    .collection('customers')
                                    .doc(query.docs.first.id)
                                    .update({'address': finalAddress});
                              } else {
                                await fs.collection('customers').add({
                                  'id': '',
                                  'user_id': user.uid,
                                  'firstname': '',
                                  'middlename': '',
                                  'lastname': '',
                                  'address': finalAddress,
                                  'contact': user.email ?? '',
                                  'created_at': DateTime.now(),
                                });
                              }

                              setState(() {
                                _addressText = finalAddress;
                              });

                              if (mounted) Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Address updated')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to update address: $e')),
                              );
                            } finally {
                              if (mounted) setModalState(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Save Address'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthService authService) {
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
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.red,
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
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
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
                          Navigator.pop(context);
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
                          backgroundColor: Colors.red,
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
