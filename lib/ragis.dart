import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class Ragistration extends StatefulWidget {
  const Ragistration({super.key});

  @override
  State<Ragistration> createState() => _RagistrationState();
}

class _RagistrationState extends State<Ragistration> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? role; // initially null
  String? category; // for provider
  bool _isLoading = false;

  final List<String> providerCategories = [
    'Plumber',
    'Electrician',
    'Handyman',
  ];

  Future<void> signUp() async {
    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    if (role == 'provider' && category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a provider category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Supabase.instance.client.auth;
      final res = await auth.signUp(
        email: emailController.text,
        password: passwordController.text,
      );
      final uid = res.user!.id;

      await Supabase.instance.client.from('users').insert({
        'id': uid,
        'role': role,
        'name': emailController.text,
        if (role == 'provider') 'category': category, // save category if provider
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully! Please check your email to verify.',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      emailController.clear();
      passwordController.clear();
      setState(() {
        role = null;
        category = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating account: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: !_isLoading,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),

            // Role Dropdown
            DropdownButton<String>(
              value: role,
              hint: const Text("Select Role"),
              onChanged: _isLoading
                  ? null
                  : (val) => setState(() {
                        role = val;
                        category = null; // reset category if role changes
                      }),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'provider', child: Text('Provider')),
              ],
            ),

            // Category Dropdown (only if role == provider)
            if (role == 'provider')
              DropdownButton<String>(
                value: category,
                hint: const Text("Select Provider Category"),
                onChanged: _isLoading
                    ? null
                    : (val) => setState(() => category = val),
                items: providerCategories
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : signUp,
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
