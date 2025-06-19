import 'package:flutter/material.dart';

class BasicInfoFormCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  final TextEditingController servingsController;
  final String? selectedCategory;
  final String? selectedDifficulty;
  final List<String> categories;
  final List<String> difficulties;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onDifficultyChanged;

  const BasicInfoFormCard({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.durationController,
    required this.servingsController,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.categories,
    required this.difficulties,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Dasar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E4A59),
              ),
            ),
            const SizedBox(height: 16),

            // Recipe Title
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Resep',
                hintText: 'Masukkan nama resep',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama resep tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Recipe Description
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Masukkan deskripsi resep',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: onCategoryChanged,
            ),

            const SizedBox(height: 16),

            // Difficulty Dropdown
            DropdownButtonFormField<String>(
              value: selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Tingkat Kesulitan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
              items: difficulties
                  .map(
                    (difficulty) => DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty),
                    ),
                  )
                  .toList(),
              onChanged: onDifficultyChanged,
            ),

            const SizedBox(height: 16),

            // Duration & Servings
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Durasi (menit)',
                      hintText: '30',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Durasi tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Porsi',
                      hintText: '2',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Porsi tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
