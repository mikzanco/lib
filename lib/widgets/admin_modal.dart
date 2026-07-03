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

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleKeyPress(String key) {
    if (_hasError) return; // Disattiva tastierino durante l'errore

    setState(() {
      if (key == "⌫") {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_pin.length < 6) {
        _pin += key;
        if (_pin.length == 6) {
          // Auto-submit
          Future.delayed(const Duration(milliseconds: 150), () {
            _submitPin();
          });
        }
      }
    });
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
              _hasError = false;
            });
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
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _hasError ? AppColors.error : AppColors.accent,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypadButton(String label) {
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDelete = label == "⌫";

    return GestureDetector(
      onTap: () => _handleKeyPress(label),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderDark.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDelete ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: isDelete ? AppColors.textTertiary : AppColors.white,
            ),
          ),
        ),
      ),
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
              
              // Shaking PIN boxes
              AnimatedBuilder(
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
              
              // Grid Keypad (Row/Column based for absolute responsiveness and zero overflow)
              SizedBox(
                height: 230,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildKeypadButton("1")),
                          Expanded(child: _buildKeypadButton("2")),
                          Expanded(child: _buildKeypadButton("3")),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildKeypadButton("4")),
                          Expanded(child: _buildKeypadButton("5")),
                          Expanded(child: _buildKeypadButton("6")),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildKeypadButton("7")),
                          Expanded(child: _buildKeypadButton("8")),
                          Expanded(child: _buildKeypadButton("9")),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox.shrink()),
                          Expanded(child: _buildKeypadButton("0")),
                          Expanded(child: _buildKeypadButton("⌫")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
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
