import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testnew/pages/dashboard_admin.dart';
import 'package:testnew/pages/dashboard_user.dart';
import 'package:testnew/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onPressed;

  LoginPage({required this.onPressed});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user!.emailVerified || userCredential.user!.email == 'afiq@admin.com') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login successful!')));

        if (userCredential.user!.email == 'afiq@admin.com') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardAdmin()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardUser()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please verify your email to log in.')));
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Login'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/lost_found_new_logo.png',
                  height: 150,
                ),
                SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 32),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage(onPressed: widget.onPressed)),
                    );
                  },
                  child: Text('Don\'t have an account? Register here.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
