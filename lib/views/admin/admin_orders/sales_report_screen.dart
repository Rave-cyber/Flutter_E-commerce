import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../firestore_service.dart';
import '../../../layouts/admin_layout.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String _selectedFilter = 'Week';

  // Modern Green Theme Colors
  final Color _primaryColor = const Color(0xFF2C8610);
  final Color _primaryLight = const Color(0xFFF0F9EE);
  final Color _accentColor = const Color(0xFF4CAF50);
  final Color _cardBackground = Colors.white;

  // Process orders to group by day/hour/month
  Map<String, Map<String, dynamic>> _processData(
      List<Map<String, dynamic>> orders, String filter) {
    final Map<String, Map<String, dynamic>> grouped = {};
    final now = DateTime.now();

    for (final o in orders) {
      final status = (o['status'] ?? '').toString();
      if (status != 'delivered') continue;

      final ts = o['createdAt'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      bool include = false;
      String groupKey = '';
      DateTime groupDate = date;

      // 1. Filter Logic
      if (filter == 'Today') {
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          include = true;
          // Group by Hour: "HH:00"
          groupKey = DateFormat('HH:00').format(date);
          groupDate = DateTime(date.year, date.month, date.day, date.hour);
        }
      } else if (filter == 'Week') {
        final startOfWeek = now.subtract(const Duration(days: 7));
        if (date.isAfter(startOfWeek)) {
          include = true;
          groupKey = DateFormat('yyyy-MM-dd').format(date);
          groupDate = DateTime(date.year, date.month, date.day);
        }
      } else if (filter == 'Month') {
        final startOfMonth = now.subtract(const Duration(days: 30));
        if (date.isAfter(startOfMonth)) {
          include = true;
          groupKey = DateFormat('yyyy-MM-dd').format(date);
          groupDate = DateTime(date.year, date.month, date.day);
        }
      } else if (filter == 'Year') {
        if (date.year == now.year) {
          include = true;
          // Group by Month: "yyyy-MM"
          groupKey = DateFormat('yyyy-MM').format(date);
          groupDate = DateTime(date.year, date.month);
        }
      }

      if (!include) continue;

      // 2. Grouping Logic
      final total = (o['total'] ?? 0.0) as num;

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = {
          'revenue': 0.0,
          'count': 0,
          'date': groupDate,
        };
      }

      grouped[groupKey]!['revenue'] =
          (grouped[groupKey]!['revenue'] as double) + total.toDouble();
      grouped[groupKey]!['count'] = (grouped[groupKey]!['count'] as int) + 1;
    }

    // Sort by date
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Future<void> _exportReport(
    List<Map<String, dynamic>> processedData,
    double totalRevenue,
    int totalOrders,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Sales Report',
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
                    pw.Text('Total Revenue', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('\$${totalRevenue.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.green700)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Total Orders', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('$totalOrders',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.blue700)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Daily Breakdown',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Date', 'Orders', 'Revenue'],
              data: processedData.map((e) {
                return [
                  DateFormat('yyyy-MM-dd').format(e['date'] as DateTime),
                  e['count'].toString(),
                  '\$${(e['revenue'] as double).toStringAsFixed(2)}',
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
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/sales-report',
      child: Container(
        color: _primaryLight.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.getAllOrders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2C8610)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final allOrders = snapshot.data ?? [];
              final groupedMap = _processData(allOrders, _selectedFilter);
              final sortedData = groupedMap.values.toList();

              final totalRevenue = sortedData.fold(
                  0.0, (sum, item) => sum + (item['revenue'] as double));
              final totalOrders = sortedData.fold(
                  0, (sum, item) => sum + (item['count'] as int));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
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
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assessment,
                              color: _primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sales Report',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your sales performance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: sortedData.isEmpty
                              ? null
                              : () => _exportReport(
                                  sortedData, totalRevenue, totalOrders),
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            shadowColor: _primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Buttons - Made responsive
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
                          'Time Period',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // FIXED: Wrap filter chips in Expanded/Flexible to prevent overflow
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                ['Today', 'Week', 'Month', 'Year'].length,
                            itemBuilder: (context, index) {
                              final filter =
                                  ['Today', 'Week', 'Month', 'Year'][index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(filter),
                                  selected: _selectedFilter == filter,
                                  selectedColor: _primaryColor,
                                  backgroundColor: _primaryLight,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _selectedFilter == filter
                                        ? Colors.white
                                        : _primaryColor,
                                  ),
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedFilter = filter;
                                      });
                                    }
                                  },
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: _selectedFilter == filter
                                          ? _primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards - Responsive Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 4 : 2,
                        childAspectRatio: isWide ? 2.0 : 1.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildSummaryCard(
                            'Total Revenue',
                            '\$${totalRevenue.toStringAsFixed(2)}',
                            _accentColor,
                            Icons.attach_money_rounded,
                          ),
                          _buildSummaryCard(
                            'Delivered Orders',
                            '$totalOrders',
                            Colors.orange,
                            Icons.shopping_bag_rounded,
                          ),
                          _buildSummaryCard(
                            'Average Order',
                            '\$${(totalRevenue / (totalOrders == 0 ? 1 : totalOrders)).toStringAsFixed(2)}',
                            Colors.purple,
                            Icons.trending_up_rounded,
                          ),
                          _buildSummaryCard(
                            'Time Period',
                            _selectedFilter,
                            Colors.blue,
                            Icons.calendar_today_rounded,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Charts Section - Flexible with scroll
                  if (sortedData.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No sales data available',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Delivered orders will appear here',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Revenue Chart
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 16),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Revenue Overview',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _selectedFilter,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 300,
                                    child: _buildRevenueChart(sortedData),
                                  ),
                                ],
                              ),
                            ),

                            // Orders Chart
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 16),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Orders Overview',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.shopping_cart_rounded,
                                          color: _primaryColor),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 300,
                                    child: _buildOrdersChart(sortedData),
                                  ),
                                ],
                              ),
                            ),

                            // Data Table Section
                            if (sortedData.isNotEmpty)
                              Container(
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
                                    Text(
                                      'Detailed Data',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // FIXED: Use SingleChildScrollView for horizontal scrolling
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columnSpacing: 32,
                                        dataRowMinHeight: 40,
                                        dataRowMaxHeight: 60,
                                        headingTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _primaryColor,
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Orders')),
                                          DataColumn(
                                              label: Text('Revenue'),
                                              numeric: true),
                                        ],
                                        rows: sortedData.map((data) {
                                          final date = data['date'] as DateTime;
                                          String dateFormat = 'MMM dd';
                                          if (_selectedFilter == 'Today') {
                                            dateFormat = 'HH:mm';
                                          } else if (_selectedFilter ==
                                              'Year') {
                                            dateFormat = 'MMM yyyy';
                                          }
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(
                                                  DateFormat(dateFormat)
                                                      .format(date))),
                                              DataCell(Text(
                                                  data['count'].toString())),
                                              DataCell(
                                                Text(
                                                  '\$${(data['revenue'] as double).toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _accentColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No revenue data',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    double maxY = 0;
    for (var d in data) {
      if ((d['revenue'] as double) > maxY) maxY = d['revenue'] as double;
    }
    maxY = maxY * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  if (data.length > 10 && index % 2 != 0)
                    return const SizedBox();
                  final date = data[index]['date'] as DateTime;
                  String dateFormat = 'MM/dd';
                  if (_selectedFilter == 'Today') dateFormat = 'HH:mm';
                  if (_selectedFilter == 'Year') dateFormat = 'MMM';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat(dateFormat).format(date),
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0)
                  return const Text('0',
                      style: TextStyle(fontSize: 10, color: Colors.grey));
                if (value > maxY) return const SizedBox();
                return Text(
                  NumberFormat.compactSimpleCurrency().format(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: _primaryColor,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '\$${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value['revenue'] as double);
            }).toList(),
            isCurved: true,
            color: _primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
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
            shadow: Shadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No orders data',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    double maxY = 0;
    for (var d in data) {
      if ((d['count'] as int) > maxY) maxY = (d['count'] as int).toDouble();
    }
    maxY = maxY + 2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: _primaryColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  if (data.length > 10 && index % 2 != 0)
                    return const SizedBox();
                  final date = data[index]['date'] as DateTime;
                  String dateFormat = 'MM/dd';
                  if (_selectedFilter == 'Today') dateFormat = 'HH:mm';
                  if (_selectedFilter == 'Year') dateFormat = 'MMM';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat(dateFormat).format(date),
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return Text(value.toInt().toString(),
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600));
                }
                return const SizedBox();
              },
              interval: 1,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['count'] as int).toDouble(),
                color: _primaryColor,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _primaryColor.withOpacity(0.7),
                    _primaryColor,
                  ],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
