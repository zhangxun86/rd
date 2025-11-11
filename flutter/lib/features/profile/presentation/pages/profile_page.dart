import 'package:flutter/material.dart';
import '../../../../common/routes.dart'; // Import the routes file to access route names

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // A very light grey background
      appBar: AppBar(
        // Transparent AppBar to show the body's background
        backgroundColor: Colors.transparent,
        elevation: 0,
        // The back button is automatically added when pushed onto the navigator stack
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 24),
              _buildVipCard(),
              const SizedBox(height: 24),
              _buildMenuList(context), // Pass the context to the menu list
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the user information section (Avatar, Name, VIP status).
  Widget _buildUserInfo() {
    return const Row(
      children: [
        // User Avatar

        SizedBox(width: 16),
        // User Name and VIP Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '张凤敏',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                // ... (VIP info remains the same)
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the "Become a VIP" card.
  Widget _buildVipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A4A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VIP',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '开通会员开始屏幕共享',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Handle "Become VIP" action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[300],
              foregroundColor: const Color(0xFF6F4E00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              '立即开通',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of menu items.
  Widget _buildMenuList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      // Using `ClipRRect` to ensure the InkWell's ripple effect respects the rounded corners.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.feedback_outlined,
              text: '问题反馈',
              color: Colors.blue,
              onTap: () {
                // Navigate to the FeedbackPage when this item is tapped.
                Navigator.of(context).pushNamed(AppRoutes.feedback);
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              text: '更多设置',
              color: Colors.purple,
              onTap: () {
                // TODO: Handle tap
              },
            ),
            _buildMenuItem(
              icon: Icons.support_agent_outlined,
              text: '联系客服',
              color: Colors.green,
              onTap: () {
                // TODO: Handle tap
              },
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              text: '关于我们',
              color: Colors.orange,
              onTap: () {
                // TODO: Handle tap
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              text: '使用帮助',
              color: Colors.cyan,
              isLast: true,
              onTap: () {
                // TODO: Handle tap
              },
            ),
          ],
        ),
      ),
    );
  }

  /// A helper method to build a single menu item row.
  /// It now accepts an `onTap` callback to handle interactions.
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // Use the provided callback.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1, // Use height 1 for a thin line
                  thickness: 0.5,
                  indent: 40, // Indent from the left to align with text
                  endIndent: 0,
                )
            ],
          ),
        ),
      ),
    );
  }
}