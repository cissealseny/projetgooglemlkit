import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GenerativePage extends StatelessWidget {
  const GenerativePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Générative')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.purple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Intelligence Artificielle',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Génération de texte et de code',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Features
          Text(
            'Fonctionnalités',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _GenerativeFeatureTile(
            icon: Icons.chat,
            title: 'Chat IA',
            subtitle: 'Discuter avec Gemini ou GPT',
            color: Colors.blue,
            onTap: () => context.go('/generative/chat'),
          ),
          _GenerativeFeatureTile(
            icon: Icons.text_snippet,
            title: 'Génération de texte',
            subtitle: 'Créer du contenu automatiquement',
            color: Colors.green,
            onTap: () {},
          ),
          _GenerativeFeatureTile(
            icon: Icons.code,
            title: 'Génération de code',
            subtitle: 'Écrire du code avec l\'IA',
            color: Colors.orange,
            onTap: () {},
          ),
          _GenerativeFeatureTile(
            icon: Icons.image,
            title: 'Analyse d\'image',
            subtitle: 'Décrire le contenu d\'images',
            color: Colors.pink,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Models Info
          Text(
            'Modèles disponibles',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.g_mobiledata, color: Colors.blue),
                  ),
                  title: const Text('Google Gemini'),
                  subtitle: const Text('Modèle multimodal avancé'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.android, color: Colors.green),
                  ),
                  title: const Text('OpenAI GPT'),
                  subtitle: const Text('GPT-3.5 & GPT-4'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerativeFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GenerativeFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
