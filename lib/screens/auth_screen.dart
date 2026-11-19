import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Екран 2 — Авторизація (вхід / реєстрація / відновлення пароля).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startWithRegister = false});

  final bool startWithRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _register = widget.startWithRegister;
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!useFirebase && !_register) {
      _email.text = 'demo@fitlife.app';
      _password.text = 'demo123';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final err = _register
        ? await state.signUp(_name.text, _email.text, _password.text)
        : await state.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      final name = state.account?.getDisplayName() ?? '';
      showMessage(context, 'Вітаємо, $name!');
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Введіть email, щоб відновити пароль');
      return;
    }
    final err = await context.read<AppState>().resetPassword(email);
    if (!mounted) return;
    showMessage(context, err ?? 'Лист для відновлення пароля надіслано на $email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SquareIconButton(icon: Icons.chevron_left, tooltip: 'Назад', onPressed: () => Navigator.of(context).pop()),
                const SizedBox(height: 28),
                Text(_register ? 'Створи акаунт' : 'З поверненням!', style: AppText.display(28)),
                const SizedBox(height: 8),
                Text(_register ? 'Кілька кроків — і можна тренуватися' : 'Увійди, щоб продовжити свій прогрес',
                    style: AppText.body(15, color: AppColors.muted)),
                const SizedBox(height: 28),
                Segmented(
                  labels: const <String>['Вхід', 'Реєстрація'],
                  index: _register ? 1 : 0,
                  onChanged: (i) => setState(() {
                    _register = i == 1;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 24),
                if (_register) ...<Widget>[
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: "Ім'я"),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Введіть ім'я" : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Некоректний email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _hidden,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    suffixIcon: IconButton(
                      tooltip: _hidden ? 'Показати пароль' : 'Сховати пароль',
                      icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Щонайменше 6 символів' : null,
                ),
                if (!_register)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgot,
                      child: Text('Забули пароль?', style: AppText.body(14, color: AppColors.lime, weight: FontWeight.w600)),
                    ),
                  ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    radius: 14,
                    border: AppColors.danger,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: AppText.body(14))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(label: _register ? 'Зареєструватися' : 'Увійти', loading: _busy, onPressed: _submit),
                if (!useFirebase) ...<Widget>[
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    radius: 14,
                    child: Text(
                      'Демо-режим. Тестові акаунти:\n'
                      'demo@fitlife.app / demo123 — користувач\n'
                      'admin@fitlife.app / admin123 — адміністратор\n'
                      'content@fitlife.app / content123 — контент-менеджер\n'
                      'blocked@fitlife.app / blocked123 — заблокований',
                      style: AppText.body(13, color: AppColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
