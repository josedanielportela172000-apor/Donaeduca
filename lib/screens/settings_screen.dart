import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // To access themeNotifier
import '../utils/app_theme.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kPush = 'settings_push';
  static const _kEmail = 'settings_email';
  static const _kLocation = 'settings_location';

  bool _notificationsEnabled = true;
  bool _emailUpdates = true;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_kPush) ?? true;
      _emailUpdates = prefs.getBool(_kEmail) ?? true;
      _locationEnabled = prefs.getBool(_kLocation) ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showFAQ(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preguntas frecuentes'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FaqItem(
                pregunta: '¿Cómo funciona el recibo de la donación?',
                respuesta: 'El colegio confirma en su historial cuándo recibió físicamente la donación. '
                    'La empresa donante es notificada al instante.',
              ),
              _FaqItem(
                pregunta: '¿Cómo se genera el certificado PDF?',
                respuesta: 'Cuando una donación está marcada como Completada, la empresa puede '
                    'generar el certificado desde su pestaña de Impacto.',
              ),
              _FaqItem(
                pregunta: '¿Por qué no llegan los colegios a mi ubicación?',
                respuesta: 'Verifica en tu perfil que tu dirección esté bien escrita. La app '
                    'autoadjusta la ubicación en el mapa de Cali automáticamente.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value == ThemeMode.dark || 
                   (themeNotifier.value == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Apariencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Modo Oscuro'),
                  subtitle: const Text('Cambiar la apariencia de la app'),
                  trailing: Switch(
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      setState(() {});
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_android_rounded),
                  title: const Text('Usar tema del dispositivo'),
                  trailing: Switch(
                    value: themeNotifier.value == ThemeMode.system,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      if (val) {
                        themeNotifier.value = ThemeMode.system;
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Notificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: const Text('Notificaciones Push'),
                  subtitle: const Text('Recibir alertas en el teléfono'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                      _savePreference(_kPush, val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_rounded),
                  title: const Text('Actualizaciones por Correo'),
                  subtitle: const Text('Resúmenes de donaciones semanales'),
                  trailing: Switch(
                    value: _emailUpdates,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _emailUpdates = val);
                      _savePreference(_kEmail, val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Privacidad y Seguridad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_rounded),
                  title: const Text('Compartir Ubicación'),
                  subtitle: const Text('Ayuda a encontrar colegios cercanos'),
                  trailing: Switch(
                    value: _locationEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _locationEnabled = val);
                      _savePreference(_kLocation, val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('Cambiar Contraseña'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Ayuda y Soporte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text('Contactar Soporte'),
                  subtitle: const Text('Habla con el equipo de DonaEduca'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'contacto.donaeduca@gmail.com',
                      query: 'subject=Necesito Ayuda con DonaEduca',
                    );
                    if (!await launchUrl(emailLaunchUri)) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el correo')));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Preguntas Frecuentes (FAQ)'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showFAQ(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String pregunta;
  final String respuesta;
  const _FaqItem({required this.pregunta, required this.respuesta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pregunta, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(respuesta, style: const TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }
}