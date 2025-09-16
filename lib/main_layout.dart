// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moderntr/services/products_service.dart';
import 'package:moderntr/widgets/back_button_handler.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/wishlist');
        break;
      case 2:
        try {
          final hasStore = await ProductService().hasStore();
          if (hasStore) {
            context.go('/create-product');
          } else {
            if (!mounted) return;

            // Show a toast-like message (Snackbar)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You don’t have a store yet. Let’s create one first!"),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            );

            // Wait briefly to let the user see the message before navigating
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) context.go('/create-store');
          }
        } catch (e) {
          debugPrint('Error checking store status: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not verify your store status")),
          );
        }
        break;
      case 3:
        context.go('/chats');
        break;
      case 4:
        context.go('/account');
        break;
    }
  }

  void _onSearchSubmitted(String query) {
    context.go('/search-results?q=${Uri.encodeQueryComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6C1910),
          elevation: 0,
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                      suffixIcon: Icon(Icons.mic, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.campaign, color: Colors.white),
                onPressed: () {
                  context.go('/my-ads');
                },
              ),
            ],
          ),
        ),
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
      );
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF6C1910),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.favorite), label: 'Wishlist'),
            BottomNavigationBarItem(
              icon: AnimatedSellButton(
                isSelected: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              label: 'Sell',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.message), label: 'Messages'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

/// A custom animated widget for the Sell button that pulsates when not selected.
class AnimatedSellButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const AnimatedSellButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _AnimatedSellButtonState createState() => _AnimatedSellButtonState();
}

class _AnimatedSellButtonState extends State<AnimatedSellButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Start pulsating if not selected.
    if (!widget.isSelected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSellButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selection state changes, update animation accordingly.
    if (widget.isSelected) {
      _controller.stop();
      _controller.value = 1.0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orangeAccent,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.add_box, color: Colors.white),
        ),
      ),
    );
  }
}
