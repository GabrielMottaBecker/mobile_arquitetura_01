import 'package:flutter/material.dart';
import '../../auth/session/session_controller.dart';
import '../../core/routes/app_routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await SessionController.instance.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sem sessão ativa.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user.image.isNotEmpty ? NetworkImage(user.image) : null,
              child: user.image.isEmpty
                  ? const Icon(Icons.person, size: 56, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),

            Text(
              user.fullName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('@${user.username}',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),

            const SizedBox(height: 32),

            // Informações
            _InfoCard(
              items: [
                _InfoItem(Icons.email_outlined, 'E-mail', user.email),
                _InfoItem(Icons.badge_outlined, 'ID', '#${user.id}'),
              ],
            ),

            const SizedBox(height: 16),

            // Token (resumido)
            _InfoCard(
              items: [
                _InfoItem(
                  Icons.key_outlined,
                  'Access Token',
                  user.accessToken.length > 20
                      ? '${user.accessToken.substring(0, 20)}…'
                      : user.accessToken,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Sair da conta',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              ListTile(
                leading:
                    Icon(item.icon, color: const Color(0xFF6A1B9A)),
                title: Text(item.label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(item.value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}
