import 'package:flutter/material.dart';

class VipNoticeDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const VipNoticeDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // --- 核心修改：不再使用 Dialog 组件，而是使用 Center + Material ---
    // 这样可以彻底去除系统默认弹窗的任何背景、边框或阴影
    return Center(
      child: Padding(
        // 手动控制水平间距，替代 Dialog 的 insetPadding
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Material(
          // 设置为 transparency，确保没有任何默认背景色
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 弹窗主体区域 (Stack: 蓝色背景 + 白色卡片 + 钻石图片)
              SizedBox(
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // --- 蓝色背景头部 (Blue Header) ---
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF6CA0FF), // 顶部：亮蓝
                            Color(0xFF448AFF), // 底部：深蓝
                          ],
                        ),
                      ),
                    ),

                    // --- 白色内容卡片 ---
                    Container(
                      margin: const EdgeInsets.only(top: 100), // 露出 100px 的蓝色头部
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // 仅保留阴影，不需要边框
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111111),
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 内容
                          Text(
                            message,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF555555),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // 按钮行
                          Row(
                            children: [
                              // 暂不开通按钮
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: onCancel,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      foregroundColor: const Color(0xFF666666),
                                    ),
                                    child: const Text("暂不开通", style: TextStyle(fontSize: 15)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 立即开通按钮
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: onConfirm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B7CFF),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: const Color(0xFF3B7CFF).withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    child: const Text("立即开通", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- 顶部钻石图片 ---
                    Positioned(
                      top: 0,
                      child: Image.asset(
                        'assets/images/vip_dialog_header.png',
                        width: 180,
                        height: 130,
                        fit: BoxFit.contain,
                        errorBuilder: (c,e,s) => Container(
                            width: 80, height: 80,
                            alignment: Alignment.center,
                            child: const Icon(Icons.diamond, size: 60, color: Colors.white)
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. 底部关闭按钮
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}