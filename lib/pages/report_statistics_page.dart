import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';

class ReportStatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Report Statistics'), // Use the common app bar
      body: CommonBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
          builder: (context, lostSnapshot) {
            if (lostSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!lostSnapshot.hasData || lostSnapshot.data!.docs.isEmpty) {
              return Center(child: Text('No lost items found'));
            }

            final lostItems = lostSnapshot.data!.docs;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('found_items').snapshots(),
              builder: (context, foundSnapshot) {
                if (foundSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!foundSnapshot.hasData || foundSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No found items found'));
                }

                final foundItems = foundSnapshot.data!.docs;

                return ListView(
                  children: [
                    _buildPieChart(context, 'Place where item always reported lost', lostItems, 'lastLocation'),
                    _buildPieChart(context, 'Place where item always reported found', foundItems, 'foundLocation'),
                    _buildPieChart(context, 'Found and lost items reported by type of item', lostItems + foundItems, 'itemType'),
                    _buildBarChart(context, 'Lost vs Found Items', lostItems, foundItems, ['Lost Items', 'Found Items']),
                    _buildBarChart(context, 'Claimed vs Unclaimed Found Items', foundItems, null, ['Claimed Items', 'Unclaimed Items']),
                    _buildBarChart(context, 'Found vs Unfound Lost Items', lostItems, null, ['Found Items', 'Unfound Items'], true),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, String title, List<DocumentSnapshot> items, String field) {
    final Map<String, int> dataMap = {};
    for (var item in items) {
      final itemData = item.data() as Map<String, dynamic>?;
      String value = itemData?.containsKey(field) == true ? itemData![field] : 'Unknown';
      if (!dataMap.containsKey(value)) {
        dataMap[value] = 0;
      }
      dataMap[value] = dataMap[value]! + 1;
    }

    final pieSections = dataMap.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: Colors.primaries[dataMap.keys.toList().indexOf(entry.key) % Colors.primaries.length],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: pieSections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dataMap.entries.map((entry) {
              int index = dataMap.keys.toList().indexOf(entry.key);
              return Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.primaries[index % Colors.primaries.length],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(entry.key),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, String title, List<DocumentSnapshot> lostItems, List<DocumentSnapshot>? foundItems, List<String> labels, [bool checkFound = false]) {
    final Map<String, int> dataMap = {};

    if (foundItems != null) {
      dataMap[labels[0]] = lostItems.length;
      dataMap[labels[1]] = foundItems.length;
    } else {
      int claimed = 0;
      int unclaimed = 0;
      for (var item in lostItems) {
        final itemData = item.data() as Map<String, dynamic>?;
        bool isClaimed = itemData?.containsKey('claimed') == true ? itemData!['claimed'] : false;
        bool isFound = itemData?.containsKey('hasFound') == true ? itemData!['hasFound'] : false;
        if (checkFound) {
          if (isFound) {
            claimed++;
          } else {
            unclaimed++;
          }
        } else {
          if (isClaimed) {
            claimed++;
          } else {
            unclaimed++;
          }
        }
      }
      dataMap[labels[0]] = claimed;
      dataMap[labels[1]] = unclaimed;
    }

    final barSpots = dataMap.entries.map((entry) {
      return BarChartGroupData(
        x: dataMap.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            width: 30,
            color: Colors.blue,
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: barSpots,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          dataMap.keys.toList()[value.toInt()],
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}