import 'package:flutter/material.dart';
import 'package:smart/models/recipe.dart';

class RecipeStepsAndIngredientsCard extends StatelessWidget {
  final TabController tabController;
  final TextEditingController ingredientController;
  final TextEditingController stepController;
  final List<String> ingredients;
  final List<CookingStep> steps;
  final VoidCallback onAddIngredient;
  final ValueChanged<int> onRemoveIngredient;
  final VoidCallback onAddStep;
  final ValueChanged<int> onRemoveStep;

  const RecipeStepsAndIngredientsCard({
    super.key,
    required this.tabController,
    required this.ingredientController,
    required this.stepController,
    required this.ingredients,
    required this.steps,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onAddStep,
    required this.onRemoveStep,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: 'Bahan'),
                Tab(text: 'Langkah'),
              ],
              labelColor: const Color(0xFF4DA8DA),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4DA8DA),
            ),
          ),

          // Tab Views
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: tabController,
              children: [
                // Ingredients Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ingredientController,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan bahan',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => onAddIngredient(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: onAddIngredient,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4DA8DA),
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ingredients.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada bahan yang ditambahkan',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: ingredients.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF4DA8DA,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(ingredients[index]),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            onRemoveIngredient(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Steps Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stepController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan langkah memasak',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => onAddStep(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: onAddStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4DA8DA),
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: steps.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada langkah yang ditambahkan',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: steps.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF4DA8DA,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(steps[index].instruction),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => onRemoveStep(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
