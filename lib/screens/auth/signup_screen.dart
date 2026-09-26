import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_exception.dart';
import '../../router/routes.dart';
import '../../state/config_controller.dart';
import '../../state/session_controller.dart';

/// Account registration, mirroring the web signup form.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _channelName = TextEditingController();
  final TextEditingController _channelDisplayName = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _displayName.dispose();
    _channelName.dispose();
    _channelDisplayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<SessionController>().register(
            username: _username.text.trim(),
            password: _password.text,
            email: _email.text.trim(),
            displayName: _displayName.text.trim().isEmpty ? null : _displayName.text.trim(),
            channelName: _channelName.text.trim().isEmpty ? null : _channelName.text.trim(),
            channelDisplayName: _channelDisplayName.text.trim().isEmpty
                ? null
                : _channelDisplayName.text.trim(),
          );

      if (!mounted) return;
      final requiresApproval = context.read<ConfigController>().config.signup.requiresApproval;

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('注册成功'),
          content: Text(
            requiresApproval
                ? '你的账号已创建，需要管理员审核通过后才能登录。'
                : '你的账号已创建，现在可以登录了。',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('好的'),
            ),
          ],
        ),
      );

      if (mounted) context.go(Routes.login);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final signup = config.config.signup;
    final minLength = config.config.passwordMinLength;

    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!signup.canRegister)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '该实例当前不允许注册新账号。',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (String? value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return '请输入用户名';
                      if (v.length < 3) return '用户名至少 3 个字符';
                      if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v)) {
                        return '只能包含字母、数字、下划线、点和连字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (String? value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return '请输入邮箱';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                        return '邮箱格式不正确';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _displayName,
                    decoration: const InputDecoration(
                      labelText: '显示名称（可选）',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: '密码',
                      helperText: '至少 $minLength 个字符',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (String? value) {
                      final v = value ?? '';
                      if (v.length < minLength) return '密码至少 $minLength 个字符';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: '确认密码',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                    validator: (String? value) =>
                        value == _password.text ? null : '两次输入的密码不一致',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '频道信息（可选）',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _channelName,
                    decoration: const InputDecoration(
                      labelText: '频道标识',
                      helperText: '用于频道链接，留空则自动创建',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _channelDisplayName,
                    decoration: const InputDecoration(
                      labelText: '频道名称',
                      prefixIcon: Icon(Icons.tv_rounded),
                    ),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _loading || !signup.canRegister ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('创建账号'),
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
