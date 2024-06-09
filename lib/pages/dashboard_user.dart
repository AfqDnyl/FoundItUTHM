import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';
import 'package:testnew/pages/announcement_page.dart';
import 'package:testnew/pages/register_item_page.dart';
import 'package:testnew/pages/view_found_item_page.dart';
import 'package:testnew/pages/view_item_page.dart';
import 'package:testnew/pages/report_lost_page.dart';
import 'package:testnew/pages/report_found_page.dart';
import 'package:testnew/pages/auction_page.dart';
import 'package:testnew/pages/report_statistics_page.dart';
import 'package:testnew/pages/profile_page.dart';
import 'package:testnew/pages/view_lost_item_page.dart';
import 'package:testnew/pages/login_page.dart';

class DashboardUser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(
        context, 
        "User Dashboard",
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage(onPressed: () {})),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: CommonBackground(
        child: GridView.count(
          crossAxisCount: 2,
          padding: EdgeInsets.all(16),
          children: [
            _buildMenuItem(context, "Announcement", Icons.announcement, AnnouncementPage()),
            _buildMenuItem(context, "Register Item", Icons.add, RegisterItemPage()),
            _buildMenuItem(context, "View Items", Icons.view_list, ViewItemsPage()),
            _buildMenuItem(context, "Report Lost", Icons.report, ReportLostPage()),
            _buildMenuItem(context, "Report Found", Icons.report_problem, ReportFoundPage()),
            _buildMenuItem(context, "Item Auction", Icons.gavel, AuctionPage()),
            _buildMenuItem(context, "Report Statistics", Icons.insert_chart, ReportStatisticsPage()),
            _buildMenuItem(context, "View Lost Items", Icons.visibility, ViewLostItemsPage()),
            _buildMenuItem(context, "View Found Items", Icons.visibility, ViewFoundItemsPage()),
            _buildMenuItem(context, "My Profile", Icons.person, ProfilePage()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50),
              Text(title, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}