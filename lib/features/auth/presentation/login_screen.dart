import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/email_domain.dart';
import '../../../core/utils/otp_limiter.dart';
import '../../../core/utils/password_validator.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _group = TextEditingController();
  final _faculty = TextEditingController();
  final _course = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _otpLimiter = OtpLimiter();

  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;
  bool _consentPrivacy = false;
  bool _consentTos = false;
  bool _otpSent = false;
  String? _error;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _group.dispose();
    _faculty.dispose();
    _course.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String get _phoneE164 {
    var raw = _phone.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (raw.startsWith('8') && raw.length == 11) {
      raw = '+7${raw.substring(1)}';
    } else if (raw.startsWith('7') && raw.length == 11) {
      raw = '+$raw';
    } else if (!raw.startsWith('+')) {
      raw = '+7$raw';
    }
    return raw;
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegister && (!_consentPrivacy || !_consentTos)) {
      setState(() => _error = AppRu.acceptConsents);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);
    try {
      if (_isRegister) {
        final result = await repo.signUp(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _fullName.text.trim(),
          groupName: _group.text.trim(),
          facultyName: _faculty.text.trim(),
          course: int.tryParse(_course.text.trim()),
        );
        if (!mounted) return;
        if (result.session == null) {
          setState(() {
            _isRegister = false;
            _error = AppRu.confirmEmailThenSignIn;
          });
          return;
        }
      } else {
        await repo.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (mounted) context.go('/dashboard');
    } catch (e) {
      final raw = e.toString();
      final friendly = raw.contains('over_email_send_rate_limit') ||
              raw.contains('email rate limit')
          ? AppRu.emailRateLimit
          : raw.contains('row-level security')
              ? AppRu.profileRlsBlocked
              : raw.contains('Database error saving new user') ||
                      raw.contains('unexpected_failure')
                  ? AppRu.databaseErrorSavingUser
                  : raw.contains('invalid_credentials') ||
                          raw.contains('Invalid login credentials')
                      ? AppRu.invalidCredentialsHint
                      : raw.contains('email_not_confirmed')
                          ? AppRu.emailNotConfirmedHint
                          : raw;
      setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendEmail() async {
    final email = _email.text.trim();
    if (EmailDomain.validate(email) != null) {
      setState(() => _error = AppRu.invalidEmail);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).resendSignupEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppRu.confirmEmailResent)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '${AppRu.confirmEmailResendFailed}: $e');
    }
  }

  Future<void> _sendOtp() async {
    if (_otpLimiter.isLocked) {
      setState(() => _error = AppRu.otpLocked);
      return;
    }
    if (!_otpLimiter.canResend) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shownCode =
          await ref.read(authRepositoryProvider).sendPhoneOtp(_phoneE164);
      _otpLimiter.markSent();
      setState(() => _otpSent = true);
      _startTicker();
      if (!mounted) return;
      if (shownCode != null && shownCode.isNotEmpty) {
        _otp.text = shownCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppRu.otpDevCodeShown}: $shownCode'),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppRu.otpSmsSent)),
        );
      }
    } catch (e) {
      setState(() => _error = '$e\n${AppRu.mockPhoneHint}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTicker() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _tick++);
      return _otpSent && !_otpLimiter.canResend;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpLimiter.isLocked) {
      setState(() => _error = AppRu.otpLocked);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyPhoneOtp(
            phoneE164: _phoneE164,
            token: _otp.text.trim(),
          );
      _otpLimiter.registerAttempt(success: true);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      _otpLimiter.registerAttempt(success: false);
      setState(() => _error = _otpLimiter.isLocked ? AppRu.otpLocked : '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    final emailErr = EmailDomain.validate(email);
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppRu.resetSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppRu.resetFailed}: $e')),
      );
    }
  }

  void _showSsoStub() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppRu.ssoButton),
        content: const Text(AppRu.ssoStubBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppRu.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable — triggers rebuild for OTP cooldown
    final _ = _tick;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.eco_rounded, size: 56, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      AppRu.appTitle,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? AppRu.authSubtitleRegister
                          : AppRu.authSubtitleLogin,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabs,
                              labelColor: AppColors.accentDeep,
                              tabs: const [
                                Tab(text: AppRu.emailTab),
                                Tab(text: AppRu.phoneTab),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_tabs.index == 0) _emailForm() else _phoneForm(),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _showSsoStub,
                              icon: const Icon(Icons.school_outlined),
                              label: const Text(AppRu.ssoButton),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isRegister) ...[
            TextFormField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: AppRu.fullName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppRu.requiredField : null,
            ),
            TextFormField(
              controller: _group,
              decoration: const InputDecoration(labelText: AppRu.groupName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppRu.requiredField : null,
            ),
            TextFormField(
              controller: _faculty,
              decoration: const InputDecoration(labelText: AppRu.facultyName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppRu.requiredField : null,
            ),
            TextFormField(
              controller: _course,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: AppRu.course),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 6) return AppRu.requiredField;
                return null;
              },
            ),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: AppRu.email),
            validator: (v) => EmailDomain.validate(v ?? ''),
          ),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: AppRu.password,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => PasswordValidator.validate(v ?? ''),
          ),
          if (_isRegister) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consentPrivacy,
              onChanged: (v) => setState(() => _consentPrivacy = v ?? false),
              title: const Text(AppRu.consentPrivacy, style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consentTos,
              onChanged: (v) => setState(() => _consentTos = v ?? false),
              title: const Text(AppRu.consentTos, style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgot,
              child: const Text(AppRu.forgotPassword),
            ),
          ),
          FilledButton(
            onPressed: _loading ? null : _submitEmail,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.accentDeep,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isRegister ? AppRu.createAccount : AppRu.signIn),
          ),
          TextButton(
            onPressed: () => setState(() {
              _isRegister = !_isRegister;
              _error = null;
            }),
            child: Text(
              _isRegister ? AppRu.alreadyHaveAccount : AppRu.newHere,
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _resendEmail,
            child: const Text(AppRu.resendConfirmEmail),
          ),
        ],
      ),
    );
  }

  Widget _phoneForm() {
    final remaining = _otpLimiter.resendRemaining.inSeconds;
    return Column(
      children: [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: AppRu.phone,
            prefixText: '+7 ',
            hintText: '9001234567',
          ),
        ),
        if (_otpSent) ...[
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: AppRu.otpCode),
          ),
          FilledButton(
            onPressed: _loading ? null : _verifyOtp,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text(AppRu.verifyOtp),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: (_loading || !_otpLimiter.canResend || _otpLimiter.isLocked)
              ? null
              : _sendOtp,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
          ),
          child: Text(
            _otpLimiter.canResend
                ? AppRu.sendOtp
                : '${AppRu.otpResendIn} ${remaining}с',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppRu.mockPhoneHint,
          style: TextStyle(fontSize: 11, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
