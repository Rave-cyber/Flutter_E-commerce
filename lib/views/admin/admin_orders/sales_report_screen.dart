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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService.getAllOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allOrders = snapshot.data ?? [];
            final groupedMap = _processData(allOrders, _selectedFilter);
            final sortedData = groupedMap.values.toList();

            final totalRevenue = sortedData.fold(
                0.0, (sum, item) => sum + (item['revenue'] as double));
            final totalOrders =
                sortedData.fold(0, (sum, item) => sum + (item['count'] as int));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assessment,
                            color: Colors.blueGrey, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Sales Report',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: sortedData.isEmpty
                          ? null
                          : () => _exportReport(
                              sortedData, totalRevenue, totalOrders),
                      icon: const Icon(Icons.download),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Today', 'Week', 'Month', 'Year'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          selectedColor: Colors.blueGrey,
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter
                                ? Colors.white
                                : Colors.black,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Revenue',
                        '\$${totalRevenue.toStringAsFixed(2)}',
                        Colors.green,
                        Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Delivered Orders',
                        '$totalOrders',
                        Colors.blue,
                        Icons.shopping_bag,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (sortedData.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No delivered orders found for sales report.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Revenue Overview'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildRevenueChart(sortedData),
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Orders Overview'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildOrdersChart(sortedData),
                          ),
                          const SizedBox(height: 48), // Bottom padding
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> data) {
    // We only show last 7-10 entries to keep chart readable if many days
    // Or we can scroll. For simple impl, let's take all.
    // X-axis: index of data point

    double maxY = 0;
    for (var d in data) {
      if ((d['revenue'] as double) > maxY) maxY = d['revenue'] as double;
    }
    maxY = maxY * 1.2; // Add some headroom

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1, // Avoid div by 0
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
                  // Show date every other item to avoid overlap if crowded
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                  return const Text('0', style: TextStyle(fontSize: 10));
                if (value > maxY) return const SizedBox();
                return Text(
                  NumberFormat.compactSimpleCurrency().format(value),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value['revenue'] as double);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart(List<Map<String, dynamic>> data) {
    double maxY = 0;
    for (var d in data) {
      if ((d['count'] as int) > maxY) maxY = (d['count'] as int).toDouble();
    }
    maxY = maxY + 2; // Add some headroom

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey));
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
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['count'] as int).toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
