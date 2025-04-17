import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Name Image at Top Left (Increased Size)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Image.asset(
                'assets/app_name.png',
                height: 80, // Increased size from 50 to 80
              ),
            ),

            SizedBox(height: 20),

            // Doctors & Pills Container - 70% of screen height
            Expanded(
              flex: 7, // 70% of the screen
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Doctor Image 1 - Left
                  Expanded(
                    child: Image.asset(
                      'assets/doctor1.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Pills Container - Center
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Image.asset(
                      'assets/pills_container.png',
                      height: 150,
                    ),
                  ),
                  // Doctor Image 2 - Right
                  Expanded(
                    child: Image.asset(
                      'assets/doctor2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Login and Signup buttons with animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedHoverButton(
                    text: "Login",
                    colors: [Colors.teal[400]!, Colors.teal[700]!],
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                  AnimatedHoverButton(
                    text: "Signup",
                    colors: [Colors.purple[400]!, Colors.purple[700]!],
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 50), // Spacing before bottom edge
          ],
        ),
      ),
    );
  }
}

// Custom Animated Hover Button Widget
class AnimatedHoverButton extends StatefulWidget {
  final String text;
  final List<Color> colors;
  final VoidCallback onPressed;

  const AnimatedHoverButton({super.key, 
    required this.text,
    required this.colors,
    required this.onPressed,
  });

  @override
  _AnimatedHoverButtonState createState() => _AnimatedHoverButtonState();
}

class _AnimatedHoverButtonState extends State<AnimatedHoverButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : (_isHovered ? 1.1 : 1.0)), // Hover effect
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: widget.colors.last.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
