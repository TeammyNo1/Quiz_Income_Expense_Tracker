import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailsScreen extends StatelessWidget {
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('transactions');

  Future<Map<DateTime, Map<String, double>>> _getIncomeExpenseData() async {
    DateTime now = DateTime.now();
    DateTime twoMonthsAgo = DateTime(now.year, now.month - 2);

    Map<DateTime, Map<String, double>> dataMap = {};

    // Fetch transactions from Firestore
    QuerySnapshot snapshot = await _transactionsCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(twoMonthsAgo))
        .orderBy('date')
        .get();

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      double amount = doc['amount'];
      String type = doc['type'];

      // Initialize the date entry if not already present
      if (!dataMap.containsKey(date)) {
        dataMap[date] = {'รายรับ': 0.0, 'รายจ่าย': 0.0};
      }

      if (type == 'รายรับ') {
        dataMap[date]!['รายรับ'] = (dataMap[date]!['รายรับ'] ?? 0) + amount;
      } else if (type == 'รายจ่าย') {
        dataMap[date]!['รายจ่าย'] = (dataMap[date]!['รายจ่าย'] ?? 0) + amount;
      }
    }

    return dataMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายรับรายจ่าย 2 เดือนย้อนหลัง'),
      ),
      body: FutureBuilder<Map<DateTime, Map<String, double>>>(
        future: _getIncomeExpenseData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          List<BarChartGroupData> barGroups = [];
          int index = 0;

          // Prepare data for the bar chart
          data.forEach((date, amounts) {
            double income = amounts['รายรับ']!;
            double expense = amounts['รายจ่าย']!;

            barGroups.add(BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: income, // Income bar
                  color: Colors.green,
                  width: 10,
                ),
                BarChartRodData(
                  toY: expense, // Expense bar
                  color: Colors.red,
                  width: 10,
                ),
              ],
              barsSpace: 4, // Space between bars
            ));
            index++;
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
                barGroups: barGroups,
              ),
            ),
          );
        },
      ),
    );
  }
}
