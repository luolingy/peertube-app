import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_exception.dart';
import '../../data/peertube_api.dart';
import '../../router/routes.dart';

/// Two step password recovery: request an email, then apply the token.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _link = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _sending = false;
  bool _applying = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _link.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请输入注册时使用的邮箱');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });

    try {
      await context.read<PeertubeApi>().askResetPassword(email);
      setState(() => _message = '重置邮件已发送，请检查收件箱（含垃圾邮件目录）。');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Accepts either a full reset URL or a bare token.
  ({int? userId, String? token}) _parseLink(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return (userId: null, token: null);

    final uri = Uri.tryParse(value);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      final userId = int.tryParse(uri.queryParameters['userId'] ?? '');
      final token = uri.queryParameters['resetPasswordToken'] ??
          uri.queryParameters['token'];
      return (userId: userId, token: token);
    }
    return (userId: null, token: value);
  }

  Future<void> _applyToken() async {
    final parsed = _parseLink(_link.text);
    final userId = parsed.userId;
    final token = parsed.token;

    if (userId == null || token == null || token.isEmpty) {
      setState(() => _error = '请粘贴邮件中的完整重置链接');
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = '新密码太短');
      return;
    }

    setState(() {
      _applying = true;
      _error = null;
      _message = null;
    });

    try {
      await context.read<PeertubeApi>().resetPassword(
            userId: userId,
            password: _password.text,
            resetPasswordToken: token,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已重置，请使用新密码登录')),
      );
      context.go(Routes.login);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('1. 发送重置邮件', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _sending ? null : _sendEmail,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('发送重置邮件'),
                ),
                const SizedBox(height: 28),
                Text('2. 设置新密码', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _link,
                  maxLines: 2,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: '重置链接',
                    hintText: 'https://.../reset-password?userId=..&resetPasswordToken=..',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '新密码',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _applying ? null : _applyToken,
                  child: _applying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('重置密码'),
                ),
                if (_message != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
