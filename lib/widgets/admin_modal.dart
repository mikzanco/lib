import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';

class AdminModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const AdminModal({
    super.key,
    required this.onSuccess,
  });

  @override
  State<AdminModal> createState() => _AdminModalState();
}

class _AdminModalState extends State<AdminModal> with SingleTickerProviderStateMixin {
  String _pin = "";
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late TextEditingController _pinController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _focusNode = FocusNode();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-focus dopo l'apertura del dialogo
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (_hasError) return;
    setState(() {
      _pin = value;
    });
    if (value.length == 6) {
      _submitPin();
    }
  }

  void _submitPin() {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    if (provider.verifyPin(_pin)) {
      widget.onSuccess();
    } else {
      setState(() {
        _hasError = true;
      });
      _shakeController.forward(from: 0.0).then((_) {
        // Reset PIN e errore
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _pin = "";
              _pinController.clear();
              _hasError = false;
            });
            _focusNode.requestFocus();
          }
        });
      });
    }
  }

  Widget _buildPinBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = _pin.length > i;
        return Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: filled ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: _hasError
                  ? AppColors.error
                  : filled
                      ? AppColors.accent
                      : AppColors.borderDark,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              filled ? "●" : "",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _hasError ? AppColors.error : AppColors.accent,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header info
              const Text(
                "🔐",
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              const Text(
                "Accesso Admin",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Inserisci il PIN per gestire il torneo",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Shaking PIN boxes with tap-to-focus helper
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (ctx, child) {
                    final offset = math.sin(_shakeAnimation.value * math.pi * 4) * _shakeAnimation.value;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: _buildPinBoxes(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              SizedBox(
                height: 20,
                child: _hasError
                    ? const Text(
                        "PIN errato. Riprova.",
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 12),
              
              // Invisible 1x1 TextField to receive native keyboard inputs automatically
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    obscureText: true,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    onChanged: _onPinChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: "",
                    ),
                  ),
                ),
              ),
              
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Annulla",
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
