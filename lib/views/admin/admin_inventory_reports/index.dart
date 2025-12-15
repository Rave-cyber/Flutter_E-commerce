import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../layouts/admin_layout.dart';
import '../../../models/product.dart';
import '../../../models/product_variant_model.dart';
import '../../../models/stock_in_model.dart';
import '../../../models/stock_out_model.dart';
import '../../../models/stock_in_out_model.dart';
import '../../../models/brand_model.dart';
import '../../../models/category_model.dart';
import '../../../models/supplier_model.dart';
import '../../../models/warehouse_model.dart';
import '../../../services/admin/stock_in_service.dart';
import '../../../services/admin/stock_out_service.dart';
import '../../../services/admin/product_sevice.dart';
import '../../../services/admin/brand_service.dart';
import '../../../services/admin/category_service.dart';
import '../../../services/admin/supplier_service.dart';
import '../../../services/admin/warehouse_service.dart';

class AdminInventoryReports extends StatefulWidget {
  const AdminInventoryReports({Key? key}) : super(key: key);

  @override
  State<AdminInventoryReports> createState() => _AdminInventoryReportsState();
}

class _AdminInventoryReportsState extends State<AdminInventoryReports>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Services
  final StockInService _stockInService = StockInService();
  final StockOutService _stockOutService = StockOutService();
  final ProductService _productService = ProductService();
  final BrandService _brandService = BrandService();
  final CategoryService _categoryService = CategoryService();
  final SupplierService _supplierService = SupplierService();
  final WarehouseService _warehouseService = WarehouseService();

  // Controllers
  final TextEditingController _dateRangeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _selectedBrand = 'all';
  String _selectedCategory = 'all';
  String _selectedWarehouse = 'all';
  String _selectedSupplier = 'all';
  String _stockLevelFilter = 'all'; // all, low, out, normal
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateRangeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to format currency
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return formatter.format(amount);
  }

  // Helper method to format date
  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Get stock level status
  String getStockLevelStatus(int currentStock, int minThreshold) {
    if (currentStock == 0) return 'Out of Stock';
    if (currentStock <= minThreshold) return 'Low Stock';
    return 'Normal';
  }

  // Get stock level color
  Color getStockLevelColor(int currentStock, int minThreshold) {
    if (currentStock == 0) return Colors.red;
    if (currentStock <= minThreshold) return Colors.orange;
    return Colors.green;
  }

  // PDF Export functionality
  Future<void> _exportInventoryReport({
    List<ProductModel>? products,
    List<StockInModel>? stockIns,
    List<StockOutModel>? stockOuts,
    int? totalProducts,
    int? currentStock,
    int? totalStockIn,
    int? totalStockOut,
    double? totalValue,
    int? lowStockCount,
    int? outOfStockCount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Inventory Report',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 24)),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style:
                        pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Total Products',
                        style: pw.TextStyle(fontSize: 12)),
                    pw.Text('$totalProducts',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.blue700)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Current Stock', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('$currentStock',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.green700)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Value', style: pw.TextStyle(fontSize: 12)),
                    pw.Text(formatCurrency(totalValue ?? 0.0),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.purple700)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Low Stock', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('$lowStockCount',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.orange700)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Stock Movement Summary',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('Stock In', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('$totalStockIn',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColors.green700)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Stock Out', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('$totalStockOut',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColors.red700)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Net Movement', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('${(totalStockIn ?? 0) - (totalStockOut ?? 0)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColors.blue700)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Current Stock Details',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Product', 'Stock', 'Price', 'Status', 'Value'],
              data: (products ?? []).map((product) {
                final stock = product.stock_quantity ?? 0;
                final status = getStockLevelStatus(stock, 10);
                final value = stock * product.sale_price;
                return [
                  product.name,
                  stock.toString(),
                  formatCurrency(product.sale_price),
                  status,
                  formatCurrency(value),
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
            if ((outOfStockCount ?? 0) > 0) ...[
              pw.SizedBox(height: 30),
              pw.Text('Out of Stock Alert',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(
                  '⚠️ $outOfStockCount products are out of stock and require immediate attention.',
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.red700,
                      fontWeight: pw.FontWeight.bold)),
            ],
            if ((lowStockCount ?? 0) > 0) ...[
              pw.SizedBox(height: 15),
              pw.Text('Low Stock Alert',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(
                  '⚠️ $lowStockCount products have low stock levels and may need replenishment soon.',
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.orange700,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventory_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2C8610);
    final lightBg = const Color(0xFFF0F9EE).withOpacity(0.3);
    return AdminLayout(
      selectedRoute: '/admin/inventory-reports',
      title: 'Inventory Reports',
      child: Container(
        color: lightBg,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header card (consistent with SalesReport)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics,
                          color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Reports',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor inventory levels and movements',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final products =
                            await _productService.getProducts().first;
                        final stockIns =
                            await _stockInService.getStockIns().first;
                        final stockOuts =
                            await _stockOutService.getStockOuts().first;
                        final totalProducts = products.length;
                        final totalStockIn = stockIns.fold(
                            0, (sum, item) => sum + item.quantity);
                        final totalStockOut = stockOuts.fold(
                            0, (sum, item) => sum + item.quantity);
                        final currentStock = totalStockIn - totalStockOut;
                        final totalValue = stockIns.fold(0.0,
                            (sum, item) => sum + (item.quantity * item.price));
                        final lowStockCount = products
                            .where((p) => (p.stock_quantity ?? 0) <= 10)
                            .length;
                        final outOfStockCount = products
                            .where((p) => (p.stock_quantity ?? 0) == 0)
                            .length;
                        await _exportInventoryReport(
                          products: products,
                          stockIns: stockIns,
                          stockOuts: stockOuts,
                          totalProducts: totalProducts,
                          currentStock: currentStock,
                          totalStockIn: totalStockIn,
                          totalStockOut: totalStockOut,
                          totalValue: totalValue,
                          lowStockCount: lowStockCount,
                          outOfStockCount: outOfStockCount,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filters card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search',
                              prefixIcon: Icon(Icons.search, size: 18),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _dateRangeController,
                            decoration: const InputDecoration(
                              labelText: 'Date Range',
                              prefixIcon: Icon(Icons.date_range, size: 18),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            readOnly: true,
                            onTap: _selectDateRange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterDropdown(
                              'Brand',
                              _selectedBrand,
                              ['all', 'brand1', 'brand2'],
                              (v) => setState(() => _selectedBrand = v!)),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                              'Category',
                              _selectedCategory,
                              ['all', 'category1', 'category2'],
                              (v) => setState(() => _selectedCategory = v!)),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                              'Stock Level',
                              _stockLevelFilter,
                              ['all', 'normal', 'low', 'out'],
                              (v) => setState(() => _stockLevelFilter = v!)),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(
                              'Warehouse',
                              _selectedWarehouse,
                              ['all', 'warehouse1', 'warehouse2'],
                              (v) => setState(() => _selectedWarehouse = v!)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              SizedBox(
                width: double.infinity,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Overview', height: 32),
                    Tab(text: 'Stock', height: 32),
                    Tab(text: 'Movement', height: 32),
                    Tab(text: 'Alerts', height: 32),
                    Tab(text: 'FIFO', height: 32),
                    Tab(text: 'Value', height: 32),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildCurrentStockTab(),
                    _buildStockMovementTab(),
                    _buildLowStockTab(),
                    _buildFIFOStatusTab(),
                    _buildValuationTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item == 'all' ? 'All' : item.replaceAll('_', ' ').toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateRangeController.text =
            '${DateFormat('MMM dd, yyyy').format(picked.start)} - ${DateFormat('MMM dd, yyyy').format(picked.end)}';
      });
    }
  }

  // Overview Tab - Key metrics and summaries
  Widget _buildOverviewTab() {
    return StreamBuilder<List<StockInModel>>(
      stream: _stockInService.getStockIns(),
      builder: (context, stockInSnapshot) {
        return StreamBuilder<List<StockOutModel>>(
          stream: _stockOutService.getStockOuts(),
          builder: (context, stockOutSnapshot) {
            return StreamBuilder<List<ProductModel>>(
              stream: _productService.getProducts(),
              builder: (context, productSnapshot) {
                final stockInList = stockInSnapshot.data ?? [];
                final stockOutList = stockOutSnapshot.data ?? [];
                final productList = productSnapshot.data ?? [];

                // Calculate metrics
                int totalProducts = productList.length;
                int totalStockIn =
                    stockInList.fold(0, (sum, item) => sum + item.quantity);
                int totalStockOut =
                    stockOutList.fold(0, (sum, item) => sum + item.quantity);
                int currentStock = totalStockIn - totalStockOut;
                double totalValue = stockInList.fold(
                    0.0, (sum, item) => sum + (item.quantity * item.price));

                int lowStockCount = productList
                    .where((p) => (p.stock_quantity ?? 0) <= 10)
                    .length;
                int outOfStockCount = productList
                    .where((p) => (p.stock_quantity ?? 0) == 0)
                    .length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Compact Metrics Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.2,
                        children: [
                          _buildMetricCard('Products', totalProducts.toString(),
                              Icons.inventory_2, Colors.blue),
                          _buildMetricCard('Stock', currentStock.toString(),
                              Icons.warehouse, Colors.green),
                          _buildMetricCard('In', totalStockIn.toString(),
                              Icons.add_circle, Colors.orange),
                          _buildMetricCard('Out', totalStockOut.toString(),
                              Icons.remove_circle, Colors.red),
                          _buildMetricCard('Value', formatCurrency(totalValue),
                              Icons.attach_money, Colors.purple),
                          _buildMetricCard('Low', lowStockCount.toString(),
                              Icons.warning, Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Compact Recent Activity
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildRecentActivityList(stockInList, stockOutList),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(
      List<StockInModel> stockInList, List<StockOutModel> stockOutList) {
    final recentActivities = <Widget>[];

    // Add recent stock-ins
    for (var stockIn in stockInList.take(3)) {
      recentActivities.add(
        ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle, color: Colors.green, size: 16),
          title: Text(
            'Stock In: ${stockIn.product_id ?? stockIn.product_variant_id ?? "Unknown"}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          subtitle: Text(
            '${stockIn.quantity} units - ${formatDate(stockIn.created_at)}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
          trailing: Text(
            formatCurrency(stockIn.price * stockIn.quantity),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
    }

    // Add recent stock-outs
    for (var stockOut in stockOutList.take(3)) {
      recentActivities.add(
        ListTile(
          dense: true,
          leading: const Icon(Icons.remove_circle, color: Colors.red, size: 16),
          title: Text(
            'Stock Out: ${stockOut.product_id ?? stockOut.product_variant_id ?? "Unknown"}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          subtitle: Text(
            '${stockOut.quantity} units - ${formatDate(stockOut.created_at)}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
          trailing: Text(
            stockOut.reason,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: recentActivities.isEmpty
            ? [
                const ListTile(
                    title: Text('No recent activity',
                        style: TextStyle(fontSize: 12)))
              ]
            : recentActivities,
      ),
    );
  }

  // Current Stock Tab
  Widget _buildCurrentStockTab() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final stockLevel =
                        getStockLevelStatus(product.stock_quantity ?? 0, 10);
                    final stockColor =
                        getStockLevelColor(product.stock_quantity ?? 0, 10);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: stockColor.withOpacity(0.2),
                          child: Icon(Icons.inventory_2,
                              color: stockColor, size: 16),
                        ),
                        title: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          'Stock: ${product.stock_quantity ?? 0} | Price: ${formatCurrency(product.sale_price)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stockLevel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Stock Movement Tab
  Widget _buildStockMovementTab() {
    return StreamBuilder<List<StockInModel>>(
      stream: _stockInService.getStockIns(),
      builder: (context, stockInSnapshot) {
        return StreamBuilder<List<StockOutModel>>(
          stream: _stockOutService.getStockOuts(),
          builder: (context, stockOutSnapshot) {
            final stockInList = stockInSnapshot.data ?? [];
            final stockOutList = stockOutSnapshot.data ?? [];

            // Filter by date range if selected
            List<StockInModel> filteredStockIn = stockInList;
            List<StockOutModel> filteredStockOut = stockOutList;

            if (_startDate != null && _endDate != null) {
              filteredStockIn = stockInList.where((item) {
                return item.created_at != null &&
                    item.created_at!.isAfter(_startDate!) &&
                    item.created_at!
                        .isBefore(_endDate!.add(const Duration(days: 1)));
              }).toList();

              filteredStockOut = stockOutList.where((item) {
                return item.created_at != null &&
                    item.created_at!.isAfter(_startDate!) &&
                    item.created_at!
                        .isBefore(_endDate!.add(const Duration(days: 1)));
              }).toList();
            }

            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stock Movement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Compact Summary
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                const Icon(Icons.add_circle,
                                    color: Colors.green, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  filteredStockIn
                                      .fold(
                                          0, (sum, item) => sum + item.quantity)
                                      .toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text('Stock In',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                const Icon(Icons.remove_circle,
                                    color: Colors.red, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  filteredStockOut
                                      .fold(
                                          0, (sum, item) => sum + item.quantity)
                                      .toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text('Stock Out',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                const Icon(Icons.trending_up,
                                    color: Colors.blue, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  (filteredStockIn.fold(
                                              0,
                                              (sum, item) =>
                                                  sum + item.quantity) -
                                          filteredStockOut.fold(
                                              0,
                                              (sum, item) =>
                                                  sum + item.quantity))
                                      .toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text('Net',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Movement Lists
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stock In',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredStockIn.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredStockIn[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      child: ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.add,
                                            color: Colors.green, size: 16),
                                        title: Text(
                                          item.product_id ??
                                              item.product_variant_id ??
                                              'Unknown',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        subtitle: Text(
                                          formatDate(item.created_at),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 8),
                                        ),
                                        trailing: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stock Out',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredStockOut.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredStockOut[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      child: ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.remove,
                                            color: Colors.red, size: 16),
                                        title: Text(
                                          item.product_id ??
                                              item.product_variant_id ??
                                              'Unknown',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        subtitle: Text(
                                          '${item.reason} - ${formatDate(item.created_at)}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 8),
                                        ),
                                        trailing: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Low Stock Alerts Tab
  Widget _buildLowStockTab() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];
        final lowStockProducts = products.where((product) {
          final stock = product.stock_quantity ?? 0;
          return stock <= 10 && stock > 0;
        }).toList();

        final outOfStockProducts = products.where((product) {
          return (product.stock_quantity ?? 0) == 0;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stock Alerts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Alert Summary
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(Icons.error,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              outOfStockProducts.length.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            Text(
                              'Out of Stock',
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(Icons.warning,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              lowStockProducts.length.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            Text(
                              'Low Stock',
                              style: TextStyle(
                                  color: Colors.orange.shade700, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lists
              Expanded(
                child: Column(
                  children: [
                    if (outOfStockProducts.isNotEmpty) ...[
                      const Text('Out of Stock',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.builder(
                          itemCount: outOfStockProducts.length,
                          itemBuilder: (context, index) {
                            final product = outOfStockProducts[index];
                            return Card(
                              color: Colors.red.shade50,
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    product.name.substring(0, 1),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: const Text('Stock: 0 units',
                                    style: TextStyle(fontSize: 10)),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text('Restock',
                                      style: TextStyle(fontSize: 10)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (lowStockProducts.isNotEmpty) ...[
                      const Text('Low Stock',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.builder(
                          itemCount: lowStockProducts.length,
                          itemBuilder: (context, index) {
                            final product = lowStockProducts[index];
                            final stock = product.stock_quantity ?? 0;
                            return Card(
                              color: Colors.orange.shade50,
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.orange,
                                  child: Text(
                                    product.name.substring(0, 1),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text('Stock: $stock units',
                                    style: const TextStyle(fontSize: 10)),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text('Restock',
                                      style: TextStyle(fontSize: 10)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (lowStockProducts.isEmpty && outOfStockProducts.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 32, color: Colors.green),
                              const SizedBox(height: 8),
                              const Text(
                                'All products are well stocked!',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // FIFO Status Tab
  Widget _buildFIFOStatusTab() {
    return StreamBuilder<List<StockInModel>>(
      stream: _stockInService.getStockIns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stockInList = snapshot.data ?? [];
        final activeBatches =
            stockInList.where((batch) => !batch.is_archived).toList();

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FIFO Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // FIFO Statistics
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Icon(Icons.inventory,
                                color: Colors.blue, size: 16),
                            const SizedBox(height: 4),
                            Text(
                              activeBatches.length.toString(),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Active', style: TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(height: 4),
                            Text(
                              activeBatches
                                  .where((batch) =>
                                      batch.remaining_quantity ==
                                      batch.quantity)
                                  .length
                                  .toString(),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Fresh', style: TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(height: 4),
                            Text(
                              activeBatches
                                  .where(
                                      (batch) => batch.remaining_quantity == 0)
                                  .length
                                  .toString(),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Depleted',
                                style: TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Batch List
              Expanded(
                child: ListView.builder(
                  itemCount: activeBatches.length,
                  itemBuilder: (context, index) {
                    final batch = activeBatches[index];
                    final depletionPercentage =
                        ((batch.quantity - batch.remaining_quantity) /
                                batch.quantity *
                                100)
                            .round();
                    final isDepleted = batch.remaining_quantity == 0;

                    return Card(
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDepleted
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDepleted ? Colors.red : Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isDepleted ? Icons.close : Icons.check_circle,
                            color: isDepleted ? Colors.red : Colors.green,
                            size: 12,
                          ),
                        ),
                        title: Text(
                          'Batch: ${batch.id.substring(0, 6).toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product: ${batch.product_id ?? batch.product_variant_id ?? "Unknown"}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: batch.remaining_quantity /
                                        batch.quantity,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDepleted ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('$depletionPercentage%',
                                    style: const TextStyle(fontSize: 8)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          formatDate(batch.created_at),
                          style: const TextStyle(fontSize: 8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Valuation Tab
  Widget _buildValuationTab() {
    return StreamBuilder<List<StockInModel>>(
      stream: _stockInService.getStockIns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stockInList = snapshot.data ?? [];

        // Calculate valuation metrics
        double totalInventoryValue = 0;
        double averageUnitCost = 0;
        int totalUnits = 0;

        for (var batch in stockInList) {
          if (!batch.is_archived && batch.remaining_quantity > 0) {
            totalInventoryValue += batch.remaining_quantity * batch.price;
            totalUnits += batch.remaining_quantity;
          }
        }

        averageUnitCost = totalUnits > 0 ? totalInventoryValue / totalUnits : 0;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valuation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Valuation Summary Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                      'Total Value',
                      formatCurrency(totalInventoryValue),
                      Icons.attach_money,
                      Colors.green),
                  _buildMetricCard('Total Units', totalUnits.toString(),
                      Icons.inventory_2, Colors.blue),
                  _buildMetricCard('Avg Cost', formatCurrency(averageUnitCost),
                      Icons.calculate, Colors.purple),
                  _buildMetricCard(
                      'Active Batches',
                      stockInList
                          .where((batch) =>
                              !batch.is_archived &&
                              batch.remaining_quantity > 0)
                          .length
                          .toString(),
                      Icons.layers,
                      Colors.orange),
                ],
              ),
              const SizedBox(height: 8),

              // Detailed Valuation
              const Text(
                'Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  itemCount: stockInList.length,
                  itemBuilder: (context, index) {
                    final batch = stockInList[index];
                    if (batch.is_archived || batch.remaining_quantity == 0)
                      return const SizedBox.shrink();

                    return Card(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory,
                            color: Colors.blue, size: 16),
                        title: Text(
                          'Batch: ${batch.id.substring(0, 6).toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        subtitle: Text(
                            '${batch.remaining_quantity} units remaining',
                            style: const TextStyle(fontSize: 9)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency(batch.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 9),
                            ),
                            Text(
                              formatCurrency(
                                  batch.remaining_quantity * batch.price),
                              style: const TextStyle(
                                  color: Colors.green, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
