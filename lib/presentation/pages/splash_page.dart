import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/session/session_controller.dart';
import '../../core/routes/app_routes.dart';

/// Tela inicial que verifica se já existe token salvo.
/// Se sim, tenta revalidar com /auth/me e vai para produtos.
/// Se não, redireciona para o login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800)); // animação mínima

    final savedToken = await SessionController.instance.getSavedToken();

    if (!mounted) return;

    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        final authService = AuthService();
        final user = await authService.getCurrentUser(savedToken);
        await SessionController.instance.login(user);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.products);
        return;
      } catch (_) {
        // Token expirado — limpa e vai para login
        await SessionController.instance.logout();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A1B9A), Color(0xFF1565C0)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'ShopApp',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
