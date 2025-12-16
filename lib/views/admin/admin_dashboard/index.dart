import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/admin_layout.dart';
import '../../../models/product.dart';
import '../../../firestore_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DateTime selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime selectedEndDate = DateTime.now();
  String selectedPeriod = 'Last 30 days';

  // Modern Green Theme Colors
  final Color _primaryColor = const Color(0xFF2C8610);
  final Color _primaryLight = const Color(0xFFF0F9EE);
  final Color _accentColor = const Color(0xFF4CAF50);
  final Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: selectedStartDate,
        end: selectedEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        selectedPeriod =
            '${DateFormat('MMM dd').format(picked.start)} - ${DateFormat('MMM dd, yyyy').format(picked.end)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/dashboard',
      child: Container(
        color: _primaryLight.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
               // Replace the Header section in your build method with this:

// Header
Container(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        blurRadius: 15,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.dashboard,
                color: _primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back! Here\'s your business summary.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Date Range Picker - Moved below with full width
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showDateRangePicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filter Period',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        selectedPeriod,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ],
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
const SizedBox(height: 24),

                // Main Content
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService.getAllOrders(),
                  builder: (context, ordersSnapshot) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getCustomersStream(),
                      builder: (context, customersSnapshot) {
                        return StreamBuilder<List<ProductModel>>(
                          stream: _getProductsStream(),
                          builder: (context, productsSnapshot) {
                            if (ordersSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                customersSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                productsSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _primaryColor),
                                ),
                              );
                            }

                            if (ordersSnapshot.hasError ||
                                customersSnapshot.hasError ||
                                productsSnapshot.hasError) {
                              return Center(
                                child: Text('Error loading data'),
                              );
                            }

                            final orders = ordersSnapshot.data ?? [];
                            final customers = customersSnapshot.data ?? [];
                            final products = productsSnapshot.data ?? [];

                            return _buildDashboardContent(
                              orders,
                              customers,
                              products,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    List<Map<String, dynamic>> orders,
    List<Map<String, dynamic>> customers,
    List<ProductModel> products,
  ) {
    // Calculate filtered data
    final filteredOrders = orders.where((order) {
      final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(selectedStartDate) &&
          createdAt.isBefore(selectedEndDate.add(const Duration(days: 1)));
    }).toList();

    final filteredCustomers = customers.where((customer) {
      final createdAt = (customer['created_at'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(selectedStartDate) &&
          createdAt.isBefore(selectedEndDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate metrics
    final totalRevenue = filteredOrders
        .where((order) => order['status'] == 'delivered')
        .fold(0.0, (sum, order) => sum + (order['total'] as num).toDouble());

    final totalOrders = filteredOrders.length;
    final totalCustomers = filteredCustomers.length;
    final lowStockProducts = products
        .where((product) => (product.stock_quantity ?? 0) <= 10)
        .length;

    final totalStockValue = products.fold(
        0.0,
        (sum, product) =>
            sum + (product.sale_price * (product.stock_quantity ?? 0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Metrics Cards - FIXED: Use MediaQuery for responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
            final isDesktop = constraints.maxWidth >= 1200;
            
            int crossAxisCount = 4;
            double aspectRatio = 1.5;
            
            if (isMobile) {
              crossAxisCount = 2;
              aspectRatio = 1.2;
            } else if (isTablet) {
              crossAxisCount = 4;
              aspectRatio = 1.3;
            } else {
              crossAxisCount = 4;
              aspectRatio = 1.5;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  'Total Revenue',
                  '₱${NumberFormat('#,###.##').format(totalRevenue)}',
                  _accentColor,
                  Icons.monetization_on_rounded,
                  '${totalOrders} orders',
                  12.5,
                ),
                _buildMetricCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Colors.blue,
                  Icons.shopping_cart_rounded,
                  'Active period',
                  8.3,
                ),
                _buildMetricCard(
                  'New Customers',
                  totalCustomers.toString(),
                  Colors.orange,
                  Icons.people_rounded,
                  'Registered',
                  5.7,
                ),
                _buildMetricCard(
                  'Low Stock Items',
                  lowStockProducts.toString(),
                  Colors.red,
                  Icons.warning_rounded,
                  '₱${NumberFormat('#,###.##').format(totalStockValue)} value',
                  -2.1,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Charts Section - FIXED: Responsive height
        Column(
          children: [
            _buildSalesTrendChart(filteredOrders),
            const SizedBox(height: 16),
            _buildInventoryChart(products),
          ],
        ),
        const SizedBox(height: 24),

        // Bottom Charts
        Column(
          children: [
            _buildCustomerGrowthChart(filteredCustomers),
            const SizedBox(height: 16),
            _buildStockMovementChart(),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activities
        _buildRecentActivities(filteredOrders),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon,
    String subtitle,
    double growthPercent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 120;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: isSmall ? 16 : 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: growthPercent >= 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: growthPercent >= 0
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        fontSize: isSmall ? 10 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmall ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmall ? 10 : 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesTrendChart(List<Map<String, dynamic>> orders) {
    final dailySales = _calculateDailySales(orders);
    final dailySalesList = dailySales.entries.toList();

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Weekly Sales Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: dailySalesList.isEmpty
                ? Center(
                    child: Text(
                      'No sales data available',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 ||
                                  value >= dailySalesList.length ||
                                  !value.isFinite) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  dailySalesList[value.toInt()].key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(
                                  '₱${value.toInt()}k',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: dailySalesList.length > 0
                          ? (dailySalesList.length - 1).toDouble()
                          : 6,
                      minY: 0,
                      maxY: dailySalesList.isEmpty
                          ? 10
                          : (dailySalesList
                                  .map((e) => e.value)
                                  .reduce((a, b) => a > b ? a : b) /
                              1000) +
                              2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailySalesList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            return FlSpot(index.toDouble(), data.value / 1000);
                          }).toList(),
                          isCurved: true,
                          color: _primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _primaryColor.withOpacity(0.3),
                                _primaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryChart(List<ProductModel> products) {
    final int inStock = products
        .where((p) => (p.stock_quantity ?? 0) > 10 && !(p.is_archived ?? false))
        .length;
    final int lowStock = products.where((p) =>
        (p.stock_quantity ?? 0) > 0 &&
        (p.stock_quantity ?? 0) <= 10 &&
        !(p.is_archived ?? false)).length;
    final int outOfStock = products
        .where((p) => (p.stock_quantity ?? 0) == 0 && !(p.is_archived ?? false))
        .length;

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Inventory Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              Icon(Icons.inventory_rounded, color: _primaryColor),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: inStock.toDouble(),
                          color: Colors.green,
                          title: '$inStock',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: lowStock.toDouble(),
                          color: Colors.orange,
                          title: '$lowStock',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: outOfStock.toDouble(),
                          color: Colors.red,
                          title: '$outOfStock',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('In Stock (>10)', Colors.green, inStock),
                      _buildLegendItem('Low Stock (1-10)', Colors.orange, lowStock),
                      _buildLegendItem('Out of Stock', Colors.red, outOfStock),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerGrowthChart(List<Map<String, dynamic>> customers) {
    final monthlyCustomers = _calculateMonthlyCustomers(customers);
    final monthlyList = monthlyCustomers.entries.toList();

    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Customer Growth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              Icon(Icons.people_rounded, color: _primaryColor),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: monthlyList.isEmpty
                ? Center(
                    child: Text(
                      'No customer data available',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: monthlyList.isEmpty
                          ? 10
                          : monthlyList
                                  .map((e) => e.value)
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble() +
                              2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 ||
                                  value >= monthlyList.length ||
                                  !value.isFinite) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  monthlyList[value.toInt()].key,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: monthlyList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data.value.toDouble(),
                              color: _primaryColor,
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockMovementChart() {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Stock Movement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              Icon(Icons.swap_vert_rounded, color: _primaryColor),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getStockInsStream(),
              builder: (context, stockInsSnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getStockOutsStream(),
                  builder: (context, stockOutsSnapshot) {
                    if (stockInsSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        stockOutsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_primaryColor),
                        ),
                      );
                    }

                    final stockIns = stockInsSnapshot.data ?? [];
                    final stockOuts = stockOutsSnapshot.data ?? [];
                    final weeklyData = _calculateWeeklyStockMovement(
                        stockIns, stockOuts);
                    final weeklyList = weeklyData.entries.toList();

                    return weeklyList.isEmpty
                        ? Center(
                            child: Text(
                              'No stock movement data',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: weeklyList.isEmpty
                                  ? 100
                                  : weeklyList
                                          .map((e) =>
                                              e.value['in']! + e.value['out']!)
                                          .reduce((a, b) => a > b ? a : b)
                                          .toDouble() +
                                      20,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 20,
                                    getTitlesWidget: (value, meta) {
                                      if (value < 0 ||
                                          value >= weeklyList.length ||
                                          !value.isFinite) {
                                        return const SizedBox();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'W${value.toInt() + 1}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: weeklyList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['in']!.toDouble(),
                                      color: Colors.green[600]!,
                                      width: 12,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        topRight: Radius.circular(2),
                                      ),
                                    ),
                                    BarChartRodData(
                                      toY: data['out']!.toDouble(),
                                      color: Colors.red[600]!,
                                      width: 12,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        topRight: Radius.circular(2),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniLegend('Stock In', Colors.green[600]!),
              _buildMiniLegend('Stock Out', Colors.red[600]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(List<Map<String, dynamic>> orders) {
    final recentOrders = orders.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentOrders.isEmpty)
            Center(
              child: Text(
                'No recent activities',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ...recentOrders.map((order) => _buildActivityItem(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Order #${order['id'].substring(0, 8)}',
                  subtitle: '₱${NumberFormat('#,###.##').format(order['total'] ?? 0)}',
                  time: (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  color: _getStatusColor(order['status'] ?? ''),
                )),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DateTime time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MM/dd, HH:mm').format(time),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'processing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Helper methods for data processing
  Map<String, double> _calculateDailySales(List<Map<String, dynamic>> orders) {
    final now = DateTime.now();
    final Map<String, double> dailySales = {};

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayKey = DateFormat('EEE').format(day);
      dailySales[dayKey] = 0.0;
    }

    for (final order in orders) {
      final status = (order['status'] ?? '').toString();
      if (status != 'delivered') continue;

      final ts = order['createdAt'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      final dayKey = DateFormat('EEE').format(date);
      final total = (order['total'] ?? 0.0) as num;

      if (dailySales.containsKey(dayKey)) {
        dailySales[dayKey] = dailySales[dayKey]! + total.toDouble();
      }
    }

    return dailySales;
  }

  Map<String, int> _calculateMonthlyCustomers(
      List<Map<String, dynamic>> customers) {
    final now = DateTime.now();
    final Map<String, int> monthlyCustomers = {};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM').format(month);
      monthlyCustomers[monthKey] = 0;
    }

    for (final customer in customers) {
      final ts = customer['created_at'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      final monthKey = DateFormat('MMM').format(date);

      if (monthlyCustomers.containsKey(monthKey)) {
        monthlyCustomers[monthKey] = monthlyCustomers[monthKey]! + 1;
      }
    }

    return monthlyCustomers;
  }

  Map<int, Map<String, int>> _calculateWeeklyStockMovement(
    List<Map<String, dynamic>> stockIns,
    List<Map<String, dynamic>> stockOuts,
  ) {
    final now = DateTime.now();
    final Map<int, Map<String, int>> weeklyData = {};

    for (int week = 0; week < 4; week++) {
      weeklyData[week] = {'in': 0, 'out': 0};
    }

    for (final stock in stockIns) {
      final ts = stock['created_at'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      final weekDiff = now.difference(date).inDays ~/ 7;

      if (weekDiff >= 0 && weekDiff < 4) {
        final quantity = (stock['quantity'] ?? 0) as num;
        weeklyData[weekDiff]!['in'] =
            weeklyData[weekDiff]!['in']! + quantity.toInt();
      }
    }

    for (final stock in stockOuts) {
      final ts = stock['created_at'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      final weekDiff = now.difference(date).inDays ~/ 7;

      if (weekDiff >= 0 && weekDiff < 4) {
        final quantity = (stock['quantity'] ?? 0) as num;
        weeklyData[weekDiff]!['out'] =
            weeklyData[weekDiff]!['out']! + quantity.toInt();
      }
    }

    return weeklyData;
  }

  // Firestore Streams
  Stream<List<ProductModel>> _getProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('is_archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !data.containsKey('product_id');
          })
          .map((doc) {
            final data = doc.data();
            return ProductModel.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> _getCustomersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('userType', whereIn: ['customer', 'user'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'created_at': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> _getStockInsStream() {
    return FirebaseFirestore.instance
        .collection('stock_ins')
        .where('is_archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'created_at': data['created_at'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> _getStockOutsStream() {
    return FirebaseFirestore.instance
        .collection('stock_outs')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'created_at': data['created_at'] ?? Timestamp.now(),
        };
      }).toList();
    });
  }
}