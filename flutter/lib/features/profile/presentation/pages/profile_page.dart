import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/routes.dart';
import '../../../../mobile/pages/home_page.dart';
import '../../../../common.dart';
import '../provider/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget implements PageShape {
  const ProfilePage({super.key});

  @override
  String get title => translate("我的");

  @override
  Widget get icon => const Icon(Icons.person_outline_rounded);

  @override
  List<Widget> get appBarActions => [];

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to fetch data after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use listen:false inside initState callbacks.
      context.read<ProfileViewModel>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          color: Colors.grey[50],
          // Add RefreshIndicator for pull-to-refresh functionality.
          child: RefreshIndicator(
            onRefresh: () => viewModel.fetchUserProfile(),
            child: CustomScrollView( // Use CustomScrollView for better scroll effects with RefreshIndicator
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfo(viewModel),
                        const SizedBox(height: 24),
                        _buildVipCard(),
                        const SizedBox(height: 24),
                        _buildMenuList(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the user information section based on the ViewModel's state.
  Widget _buildUserInfo(ProfileViewModel viewModel) {
    // Show a loading shimmer effect when data is being fetched for the first time.
    if (viewModel.state == ProfileState.loading && viewModel.userProfile == null) {
      return const _UserInfoLoadingShimmer();
    }

    // Show an error message with a retry button if the initial fetch failed.
    if (viewModel.state == ProfileState.error && viewModel.userProfile == null) {
      return SizedBox(
        height: 80, // Give it a fixed height to avoid layout jumps
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.errorMessage ?? "加载个人信息失败"),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => viewModel.fetchUserProfile(),
                child: const Text("点击重试"),
              )
            ],
          ),
        ),
      );
    }

    final profile = viewModel.userProfile;

    // If profile is still null, show the loading placeholder.
    if (profile == null) {
      return const _UserInfoLoadingShimmer();
    }

    // Display the user's profile information.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey[200],
          backgroundImage: NetworkImage(profile.avatar),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint("Failed to load user avatar: $exception");
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.nickname,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),

              if (profile.isVip)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'VIP',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '到期时间 ${profile.vipExpDate}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'VIP',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '暂未开通会员',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the "Become a VIP" card with navigation.
  Widget _buildVipCard() {
    return Builder(
        builder: (context) {
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
                    Text('VIP', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    SizedBox(height: 4),
                    Text('开通会员开始屏幕共享', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the VipPage using its named route.
                    Navigator.of(context).pushNamed(AppRoutes.vip);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[300],
                    foregroundColor: const Color(0xFF6F4E00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('立即开通', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
    );
  }

  /// Builds the list of menu items.
  Widget _buildMenuList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildMenuItem(icon: Icons.feedback_outlined, text: '问题反馈', color: Colors.blue, onTap: () => Navigator.of(context).pushNamed(AppRoutes.feedback)),
            _buildMenuItem(icon: Icons.settings_outlined, text: '更多设置', color: Colors.purple, onTap: () =>Navigator.of(context).pushNamed(AppRoutes.setting)),
            _buildMenuItem(icon: Icons.support_agent_outlined, text: '联系客服', color: Colors.green, onTap: () {}),
            _buildMenuItem(icon: Icons.info_outline, text: '关于我们', color: Colors.orange, onTap: () {}),
            _buildMenuItem(icon: Icons.help_outline, text: '使用帮助', color: Colors.cyan, isLast: true, onTap: () {}),
          ],
        ),
      ),
    );
  }

  /// A helper method to build a single menu item row.
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
        onTap: onTap,
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
                const Divider(height: 1, thickness: 0.5, indent: 40, endIndent: 0)
            ],
          ),
        ),
      ),
    );
  }
}

/// A placeholder widget with a shimmer-like animation for loading states.
class _UserInfoLoadingShimmer extends StatelessWidget {
  const _UserInfoLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(radius: 36, backgroundColor: Color(0xFFE0E0E0)),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 120, height: 22),
            SizedBox(height: 10),
            _ShimmerBox(width: 180, height: 16),
          ],
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}