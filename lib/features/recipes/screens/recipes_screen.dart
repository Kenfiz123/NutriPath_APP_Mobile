import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/recipe_details_sheet.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});
  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecipeCollection>(
      future: ref.read(apiClientProvider).getRecipes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPanel();
        final recipes = snapshot.data!.recipes;
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
    );
  }
}
