import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go('/login');
          }
        },
        child: ListView(
          children: [
            // Profile Section
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            _getInitials(state.user?.username ?? 'U'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.user?.username ?? 'Utilisateur',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (state.user?.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            state.user!.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const _SectionHeader(title: 'Compte'),
            _SettingsTile(
              icon: Icons.person,
              title: 'Profil',
              subtitle: 'Modifier vos informations',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.lock,
              title: 'Sécurité',
              subtitle: 'Mot de passe et authentification',
              onTap: () {},
            ),

            const _SectionHeader(title: 'Application'),
            _SettingsTile(
              icon: Icons.palette,
              title: 'Thème',
              subtitle: 'Apparence de l\'application',
              trailing: const _ThemeToggle(),
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'Langue',
              subtitle: 'Français',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Gérer les notifications',
              onTap: () {},
            ),

            const _SectionHeader(title: 'API'),
            _SettingsTile(
              icon: Icons.cloud,
              title: 'Serveur API',
              subtitle: 'http://localhost:8000',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.key,
              title: 'Clés API',
              subtitle: 'Configurer Google AI, OpenAI',
              onTap: () {},
            ),

            const _SectionHeader(title: 'À propos'),
            _SettingsTile(
              icon: Icons.info,
              title: 'Version',
              subtitle: '1.0.0',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description,
              title: 'Licences',
              subtitle: 'Licences open source',
              onTap: () {
                showLicensePage(context: context);
              },
            ),
            _SettingsTile(
              icon: Icons.privacy_tip,
              title: 'Confidentialité',
              subtitle: 'Politique de confidentialité',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ThemeToggle extends StatefulWidget {
  const _ThemeToggle();

  @override
  State<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<_ThemeToggle> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _isDark,
      onChanged: (value) {
        setState(() {
          _isDark = value;
        });
        // TODO: Implement theme switching
      },
    );
  }
}
