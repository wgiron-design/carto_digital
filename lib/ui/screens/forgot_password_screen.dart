import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    await auth.forgotPassword(
      _usernameController.text,
      _emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: const Color(0xFF1E1E1E),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: authController.successMessage != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            size: 64,
                            color: Color(0xFF81C784),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Solicitud Procesada',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            authController.successMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              authController.clearMessages();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                            ),
                            child: const Text('Volver al Login'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.lock_reset,
                              size: 48,
                              color: Color(0xFF4FC3F7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Recuperar Contraseña',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingrese su nombre de usuario y correo electrónico registrados. El sistema verificará la coincidencia exacta de ambos datos.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[400],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (authController.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[900]?.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[400]!),
                                ),
                                child: Text(
                                  authController.errorMessage!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Campo Username
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4FC3F7)),
                                filled: true,
                                fillColor: const Color(0xFF2C2C2C),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese su nombre de usuario';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4FC3F7)),
                                filled: true,
                                fillColor: const Color(0xFF2C2C2C),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese su correo electrónico';
                                }
                                final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                                if (!emailRegExp.hasMatch(value.trim())) {
                                  return 'Ingrese un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Botón Enviar
                            ElevatedButton(
                              onPressed: authController.isLoading ? null : _submitForgotPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: authController.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Enviar Enlace de Recuperación',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            TextButton(
                              onPressed: () {
                                authController.clearMessages();
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Cancelar y Volver',
                                style: TextStyle(color: Color(0xFF4FC3F7)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
