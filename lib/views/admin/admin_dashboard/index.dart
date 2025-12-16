import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../layouts/admin_layout.dart';
import '../../../models/product.dart';
import '../../../models/order_model.dart';
import '../../../models/customer_model.dart';
import '../../../models/stock_in_model.dart';
import '../../../models/stock_out_model.dart';
import '../../../services/admin/order_service.dart';
import '../../../services/admin/customer_service.dart';
import '../../../services/admin/product_sevice.dart';
import '../../../services/admin/stock_in_service.dart';
import '../../../services/admin/stock_out_service.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DateTime selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime selectedEndDate = DateTime.now();
  String selectedPeriod = 'Last 30 days';

  // Service instances
  final OrderService _orderService = OrderService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final StockInService _stockInService = StockInService();
  final StockOutService _stockOutService = StockOutService();

  // Real-time streams for live data
  late Stream<List<OrderModel>> _ordersStream;
  late Stream<List<OrderModel>> _deliveredOrdersStream;
  late Stream<List<CustomerModel>> _customersStream;
  late Stream<List<StockInModel>> _stockInsStream;
  late Stream<List<StockOutModel>> _stockOutsStream;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _ordersStream = _orderService.streamOrdersByDateRange(
      selectedStartDate,
      selectedEndDate,
    );

    _deliveredOrdersStream = _orderService.streamDeliveredOrdersByDateRange(
      selectedStartDate,
      selectedEndDate,
    );

    _customersStream = _customerService.streamCustomersByDateRange(
      selectedStartDate,
      selectedEndDate,
    );

    _stockInsStream = _stockInService.getStockIns();
    _stockOutsStream = _stockOutService.getStockOuts();
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
      // Reinitialize streams with new date range
      _initializeStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/dashboard',
      child: RefreshIndicator(
        onRefresh: () async {
          // Refresh streams by reinitializing them
          setState(() {
            _initializeStreams();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Date Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back! Here\'s your business summary.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showDateRangePicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedPeriod,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.green[600],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Key Metrics Cards with Real-time Data
              _buildRealTimeMetrics(),

              const SizedBox(height: 24),

              // Charts Section with Real-time Data
              Column(
                children: [
                  _buildRealTimeSalesChart(),
                  const SizedBox(height: 16),
                  _buildRealTimeInventoryChart(),
                ],
              ),
              const SizedBox(height: 24),

              // Bottom Charts
              Column(
                children: [
                  _buildRealTimeCustomerGrowthChart(),
                  const SizedBox(height: 16),
                  _buildStockMovementChart(),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Activities with Real-time Data
              _buildRealTimeRecentActivities(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeMetrics() {
    return Column(
      children: [
        // Total Revenue
        StreamBuilder<List<OrderModel>>(
          stream: _deliveredOrdersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMetricCard(
                'Total Revenue',
                'Error',
                Icons.monetization_on,
                Colors.red,
                'Failed to load',
              );
            }

            if (!snapshot.hasData) {
              return _buildMetricCard(
                'Total Revenue',
                '...',
                Icons.monetization_on,
                Colors.green,
                'Loading...',
              );
            }

            final orders = snapshot.data!;
            final totalRevenue = orders.fold<double>(
              0.0,
              (sum, order) => sum + order.total,
            );

            return _buildMetricCard(
              'Total Revenue',
              '₱${NumberFormat('#,###.##').format(totalRevenue)}',
              Icons.monetization_on,
              Colors.green,
              '${orders.length} orders',
            );
          },
        ),
        const SizedBox(height: 16),

        // Total Orders
        StreamBuilder<List<OrderModel>>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMetricCard(
                'Total Orders',
                'Error',
                Icons.shopping_cart,
                Colors.red,
                'Failed to load',
              );
            }

            if (!snapshot.hasData) {
              return _buildMetricCard(
                'Total Orders',
                '...',
                Icons.shopping_cart,
                Colors.blue,
                'Loading...',
              );
            }

            final orders = snapshot.data!;

            return _buildMetricCard(
              'Total Orders',
              orders.length.toString(),
              Icons.shopping_cart,
              Colors.blue,
              'Active period',
            );
          },
        ),
        const SizedBox(height: 16),

        // New Customers
        StreamBuilder<List<CustomerModel>>(
          stream: _customersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMetricCard(
                'New Customers',
                'Error',
                Icons.people,
                Colors.red,
                'Failed to load',
              );
            }

            if (!snapshot.hasData) {
              return _buildMetricCard(
                'New Customers',
                '...',
                Icons.people,
                Colors.orange,
                'Loading...',
              );
            }

            final customers = snapshot.data!;

            return _buildMetricCard(
              'New Customers',
              customers.length.toString(),
              Icons.people,
              Colors.orange,
              'Registered',
            );
          },
        ),
        const SizedBox(height: 16),

        // Low Stock Items (products are static, so no stream needed)
        StreamBuilder<List<ProductModel>>(
          stream: _productService.getProducts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMetricCard(
                'Low Stock Items',
                'Error',
                Icons.warning,
                Colors.red,
                'Failed to load',
              );
            }

            if (!snapshot.hasData) {
              return _buildMetricCard(
                'Low Stock Items',
                '...',
                Icons.warning,
                Colors.red,
                'Loading...',
              );
            }

            final products = snapshot.data!;
            final lowStockProducts = products
                .where((product) => (product.stock_quantity ?? 0) <= 10)
                .length;
            final totalStockValue = products.fold<double>(
                0.0,
                (sum, product) =>
                    sum + (product.sale_price * (product.stock_quantity ?? 0)));

            return _buildMetricCard(
              'Low Stock Items',
              lowStockProducts.toString(),
              Icons.warning,
              Colors.red,
              '₱${NumberFormat('#,###').format(totalStockValue)} total value',
            );
          },
        ),
      ],
    );
  }

  Widget _buildRealTimeSalesChart() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sales Trend (Real-time)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: _deliveredOrdersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading sales data'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final orders = snapshot.data!;
                  final spots = _getSalesChartData(orders);

                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                '7d ago',
                                '6d',
                                '5d',
                                '4d',
                                '3d',
                                '2d',
                                'Today'
                              ];
                              if (value.toInt() >= 0 && value.toInt() < 7) {
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₱${(value / 1000).toInt()}k',
                                style: const TextStyle(fontSize: 12),
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
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.green[600],
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.green.withOpacity(0.3),
                                Colors.green.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getSalesChartData(List<OrderModel> orders) {
    Map<String, double> dailyRevenue = {};

    for (OrderModel order in orders) {
      if (order.createdAt != null) {
        final dateKey =
            '${order.createdAt!.year}-${order.createdAt!.month.toString().padLeft(2, '0')}-${order.createdAt!.day.toString().padLeft(2, '0')}';
        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + order.total;
      }
    }

    // Convert to chart spots (last 7 days)
    List<FlSpot> spots = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      spots.add(FlSpot(
          (6 - i).toDouble(), (dailyRevenue[dateKey] ?? 0.0).toDouble()));
    }

    return spots;
  }

  Widget _buildRealTimeInventoryChart() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Inventory Status (Real-time)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading inventory data'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final products = snapshot.data!;
                  final int inStock = products
                      .where((p) => (p.stock_quantity ?? 0) > 10)
                      .length;
                  final int lowStock = products
                      .where((p) =>
                          (p.stock_quantity ?? 0) > 0 &&
                          (p.stock_quantity ?? 0) <= 10)
                      .length;
                  final int outOfStock = products
                      .where((p) => (p.stock_quantity ?? 0) == 0)
                      .length;

                  return PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: inStock.toDouble(),
                          color: Colors.green,
                          title: '$inStock',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: lowStock.toDouble(),
                          color: Colors.orange,
                          title: '$lowStock',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: outOfStock.toDouble(),
                          color: Colors.red,
                          title: '$outOfStock',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<ProductModel>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final products = snapshot.data!;
                final int inStock =
                    products.where((p) => (p.stock_quantity ?? 0) > 10).length;
                final int lowStock = products
                    .where((p) =>
                        (p.stock_quantity ?? 0) > 0 &&
                        (p.stock_quantity ?? 0) <= 10)
                    .length;
                final int outOfStock =
                    products.where((p) => (p.stock_quantity ?? 0) == 0).length;

                return Column(
                  children: [
                    _buildLegendItem('In Stock', Colors.green, inStock),
                    _buildLegendItem('Low Stock', Colors.orange, lowStock),
                    _buildLegendItem('Out of Stock', Colors.red, outOfStock),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeCustomerGrowthChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Customer Growth (Real-time)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: _customersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading customer data'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final customers = snapshot.data!;
                  final groups = _getCustomerGrowthData(customers);

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          (customers.length * 1.2).clamp(10.0, double.infinity),
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
                            getTitlesWidget: (value, meta) {
                              const months = [
                                '5mo',
                                '4mo',
                                '3mo',
                                '2mo',
                                '1mo',
                                'Now'
                              ];
                              if (value.toInt() >= 0 && value.toInt() < 6) {
                                return Text(
                                  months[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('');
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
                      barGroups: groups,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getCustomerGrowthData(
      List<CustomerModel> customers) {
    Map<String, int> monthlyCustomers = {};

    for (CustomerModel customer in customers) {
      if (customer.created_at != null) {
        final monthKey =
            '${customer.created_at!.year}-${customer.created_at!.month.toString().padLeft(2, '0')}';
        monthlyCustomers[monthKey] = (monthlyCustomers[monthKey] ?? 0) + 1;
      }
    }

    // Convert to bar chart data (last 6 months)
    List<BarChartGroupData> groups = [];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime.now();
      date.subtract(Duration(days: 30 * i));
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      groups.add(
        BarChartGroupData(
          x: 5 - i,
          barRods: [
            BarChartRodData(
              toY: (monthlyCustomers[monthKey] ?? 0).toDouble(),
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Widget _buildStockMovementChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_vert, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Stock Movement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
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
                        getTitlesWidget: (value, meta) {
                          const weeks = ['W1', 'W2', 'W3', 'W4'];
                          if (value.toInt() >= 0 && value.toInt() < 4) {
                            return Text(
                              weeks[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 50,
                          color: Colors.green[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                        BarChartRodData(
                          toY: 30,
                          color: Colors.red[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 70,
                          color: Colors.green[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                        BarChartRodData(
                          toY: 25,
                          color: Colors.red[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 40,
                          color: Colors.green[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                        BarChartRodData(
                          toY: 35,
                          color: Colors.red[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: 60,
                          color: Colors.green[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                        BarChartRodData(
                          toY: 20,
                          color: Colors.red[600],
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
      ),
    );
  }

  Widget _buildRealTimeRecentActivities() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activities (Real-time)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<OrderModel>>(
              stream: _ordersStream,
              builder: (context, ordersSnapshot) {
                return StreamBuilder<List<StockInModel>>(
                  stream: _stockInsStream,
                  builder: (context, stockInsSnapshot) {
                    return StreamBuilder<List<StockOutModel>>(
                      stream: _stockOutsStream,
                      builder: (context, stockOutsSnapshot) {
                        if (ordersSnapshot.hasError ||
                            stockInsSnapshot.hasError ||
                            stockOutsSnapshot.hasError) {
                          return const Center(
                            child: Text('Error loading activities'),
                          );
                        }

                        if (!ordersSnapshot.hasData ||
                            !stockInsSnapshot.hasData ||
                            !stockOutsSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        List<Widget> activities = [];
                        final orders = ordersSnapshot.data!;
                        final stockIns = stockInsSnapshot.data!;
                        final stockOuts = stockOutsSnapshot.data!;

                        // Add recent orders
                        activities.addAll(orders
                            .take(5)
                            .map((order) => _buildActivityItem(
                                  Icons.shopping_cart,
                                  'New order placed',
                                  'Order #${order.id}',
                                  order.createdAt ?? DateTime.now(),
                                  Colors.blue,
                                ))
                            .toList());

                        // Add recent stock ins
                        activities.addAll(stockIns
                            .take(3)
                            .map((stock) => _buildActivityItem(
                                  Icons.add_circle,
                                  'Stock added',
                                  '${stock.quantity} units received',
                                  stock.created_at ?? DateTime.now(),
                                  Colors.green,
                                ))
                            .toList());

                        // Add recent stock outs
                        activities.addAll(stockOuts
                            .take(3)
                            .map((stock) => _buildActivityItem(
                                  Icons.remove_circle,
                                  'Stock deducted',
                                  '${stock.quantity} units removed',
                                  stock.created_at ?? DateTime.now(),
                                  Colors.orange,
                                ))
                            .toList());

                        // Take only first 8 activities and sort by date
                        activities = activities.take(8).toList();

                        if (activities.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No recent activities',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return Column(children: activities);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            '$label: $count',
            style: const TextStyle(fontSize: 12),
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

  Widget _buildActivityItem(IconData icon, String title, String subtitle,
      DateTime time, Color color) {
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
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
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
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd, HH:mm').format(time),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
