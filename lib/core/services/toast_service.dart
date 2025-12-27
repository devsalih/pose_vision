import 'dart:ui';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pose_vision/core/constants/app_theme.dart';

enum ToastType { success, error, info, warning }

class ToastService {
  static void showSuccess(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _showToast(message, ToastType.success,
        actionLabel: actionLabel, onAction: onAction);
  }

  static void showError(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _showToast(message, ToastType.error,
        actionLabel: actionLabel, onAction: onAction);
  }

  static void showInfo(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _showToast(message, ToastType.info,
        actionLabel: actionLabel, onAction: onAction);
  }

  static void showWarning(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    _showToast(message, ToastType.warning,
        actionLabel: actionLabel, onAction: onAction);
  }

  static void _showToast(String message, ToastType type,
      {String? actionLabel, VoidCallback? onAction}) {
    BotToast.showCustomText(
      duration: const Duration(seconds: 4),
      toastBuilder: (cancelFunc) {
        return _ToastWidget(
          message: message,
          type: type,
          onClose: cancelFunc,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      },
    );
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getColor(context);
    final icon = _getIcon();

    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(flex: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 2),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FaIcon(
                              icon,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          if (actionLabel != null && onAction != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextButton(
                                onPressed: () {
                                  onAction!();
                                  onClose();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: color.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: Text(
                                  actionLabel!,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onClose,
                              borderRadius: BorderRadius.circular(50),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color:
                                      isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    switch (type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.error;
      case ToastType.info:
        return Theme.of(context).primaryColor;
      case ToastType.warning:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getIcon() {
    switch (type) {
      case ToastType.success:
        return FontAwesomeIcons.check;
      case ToastType.error:
        return FontAwesomeIcons.circleExclamation;
      case ToastType.info:
        return FontAwesomeIcons.info;
      case ToastType.warning:
        return FontAwesomeIcons.triangleExclamation;
    }
  }
}
