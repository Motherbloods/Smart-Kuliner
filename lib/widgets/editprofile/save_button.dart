import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  final bool hasChanges;
  final bool isLoading;
  final VoidCallback? onPressed;

  const SaveButton({
    super.key,
    required this.hasChanges,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasChanges && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasChanges
              ? const Color(0xFF4DA8DA)
              : Colors.grey[300],
          foregroundColor: hasChanges ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: hasChanges ? 2 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save,
                    size: 20,
                    color: hasChanges ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasChanges ? 'Simpan Perubahan' : 'Tidak Ada Perubahan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
