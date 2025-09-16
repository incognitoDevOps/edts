import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BackButtonHandler extends StatelessWidget {
  final Widget child;
  final String? parentRoute;
  final bool showExitConfirmation;

  const BackButtonHandler({
    super.key,
    required this.child,
    this.parentRoute,
    this.showExitConfirmation = false,
  });

  Future<bool> _onWillPop(BuildContext context) async {
    if (showExitConfirmation) {
      // Show toast first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Are you sure you want to exit?"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Then show dialog
      final shouldExit = await _showExitConfirmation(context) ?? false;
      if (shouldExit) {
        SystemNavigator.pop(); // Exit the app
        return true;
      }
      return false;
    }

    if (context.canPop()) {
      context.pop();
      return false;
    } else if (parentRoute != null) {
      context.go(parentRoute!);
      return false;
    } else {
      context.go('/');
      return false;
    }
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: child,
    );
  }
}