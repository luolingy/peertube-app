import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_exception.dart';
import '../../router/routes.dart';
import '../../state/config_controller.dart';
import '../../state/session_controller.dart';

/// Username/password login with two factor support.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _needsOtp = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<SessionController>().login(
            username: _username.text.trim(),
            password: _password.text,
            otp: _needsOtp ? _otp.text.trim() : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.home);
      }
    } on ApiException catch (error) {
      setState(() {
        _error = error.message;
        if (error.isTwoFactorRequired) _needsOtp = true;
      });
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();

    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.play_circle_fill_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '登录到 ${config.instanceName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _username,
                    autofillHints: const <String>[AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '用户名或邮箱',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty) ? '请输入用户名' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const <String>[AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (String? value) =>
                        (value == null || value.isEmpty) ? '请输入密码' : null,
                  ),
                  if (_needsOtp) ...<Widget>[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '两步验证码',
                        helperText: '请输入认证器应用中的 6 位验证码',
                        prefixIcon: Icon(Icons.security_rounded),
                      ),
                    ),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: const Text('忘记密码？'),
                  ),
                  if (config.config.signup.canRegister)
                    TextButton(
                      onPressed: () => context.push(Routes.signup),
                      child: const Text('还没有账号？立即注册'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
