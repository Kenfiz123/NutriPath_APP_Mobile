import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets.dart';
import '../widgets/recipe_details_sheet.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecipes = ref.watch(recipesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(recipesProvider.future),
      child: asyncRecipes.when(
        loading: () => const LoadingPanel(),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.refresh(recipesProvider),
            ),
          ],
        ),
        data: (recipeCollection) {
          final recipes = recipeCollection.recipes;
          return NutriPage(
            children: [
              const SectionHeader(
                title: 'Khám phá công thức',
                subtitle: 'Hàng ngàn món ăn healthy từ chuyên gia.',
              ),
              for (final r in recipes)
                NutriCard(
                  onTap: () => showRecipeDetails(context, r),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${r.calories.round()} kcal • ${r.timeMinutes} phút',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.slate300,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
