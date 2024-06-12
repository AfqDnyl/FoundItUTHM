import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';

class ReportStatisticsPage extends StatefulWidget {
  @override
  _ReportStatisticsPageState createState() => _ReportStatisticsPageState();
}

class _ReportStatisticsPageState extends State<ReportStatisticsPage> {
  String searchQuery = '';
  String selectedLocationFilter = 'All';
  String selectedItemTypeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Report Statistics'),
      body: CommonBackground(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            _buildGenerateReportButton(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
                builder: (context, lostSnapshot) {
                  if (lostSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!lostSnapshot.hasData || lostSnapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No lost items found'));
                  }

                  final lostItems = _applyFilters(lostSnapshot.data!.docs);

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('found_items').snapshots(),
                    builder: (context, foundSnapshot) {
                      if (foundSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!foundSnapshot.hasData || foundSnapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No found items found'));
                      }

                      final foundItems = _applyFilters(foundSnapshot.data!.docs);

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
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            value: selectedLocationFilter,
            items: [
              'All', 'DEWAN SULTAN IBRAHIM', 'MASJID SULTAN IBRAHIM', 'PERPUSTAKAAN TUN AMINAH',
              'FSKTM', 'FPTP', 'FPTV', 'FKAAB', 'FKEE', 'TASIK AREA', 'DEWAN F2',
              'PUSAT KESIHATAN UNIVERSITI', 'G3', 'B1', 'B7', 'B6', 'B8', 'C12', 'C11',
              'STADIUM', 'PADANG KAWAD', 'ATM UTHM', 'DEWAN PENYU', 'BADMINTON COURT',
              'KOLEJ TUN SYED NASIR', 'KOLEJ TUN FATIMAH', 'KOLEJ TUN DR ISMAIL'
            ].map((location) => DropdownMenuItem(
              value: location,
              child: Text(location),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedLocationFilter = value!;
              });
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Item Type',
              border: OutlineInputBorder(),
            ),
            value: selectedItemTypeFilter,
            items: [
              'All', 'Gadgets', 'Personal Items', 'Travel Items', 'Others', 'Documents', 'Clothing',
              'Accessories', 'Bags', 'Electronics', 'Sports Equipment', 'Books', 'Keys', 'Stationery', 'Toys'
            ].map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedItemTypeFilter = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateReportButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _generateReport,
        child: Text('Generate Report'),
      ),
    );
  }

  Future<void> _generateReport() async {
    final lostItemsSnapshot = await FirebaseFirestore.instance.collection('lost_items').get();
    final foundItemsSnapshot = await FirebaseFirestore.instance.collection('found_items').get();

    final lostItems = _applyFilters(lostItemsSnapshot.docs);
    final foundItems = _applyFilters(foundItemsSnapshot.docs);

    final itemTypeReport = _generateTopReport(lostItems + foundItems, 'itemType');
    final locationReport = _generateTopReport(lostItems + foundItems, 'lastLocation');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top 3 Item Types:'),
              ...itemTypeReport.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
              SizedBox(height: 16),
              Text('Top 3 Locations:'),
              ...locationReport.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Map<String, int> _generateTopReport(List<DocumentSnapshot> items, String field) {
    final Map<String, int> dataMap = {};
    for (var item in items) {
      final itemData = item.data() as Map<String, dynamic>?;
      String value = itemData?.containsKey(field) == true ? itemData![field] : 'Unknown';
      if (!dataMap.containsKey(value)) {
        dataMap[value] = 0;
      }
      dataMap[value] = dataMap[value]! + 1;
    }

    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(3));
  }

  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> items) {
    return items.where((item) {
      final itemData = item.data() as Map<String, dynamic>?;
      if (itemData == null) return false;

      final location = itemData['lastLocation']?.toLowerCase() ?? '';
      final itemType = itemData['itemType']?.toLowerCase() ?? '';
      final matchesSearchQuery = searchQuery.isEmpty || itemData.values.any((value) => value.toString().toLowerCase().contains(searchQuery));
      final matchesLocationFilter = selectedLocationFilter == 'All' || location == selectedLocationFilter.toLowerCase();
      final matchesItemTypeFilter = selectedItemTypeFilter == 'All' || itemType == selectedItemTypeFilter.toLowerCase();

      return matchesSearchQuery && matchesLocationFilter && matchesItemTypeFilter;
    }).toList();
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