import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';
import 'recipe_list_card.dart';

class RecipeHorizontalList extends StatelessWidget {
  const RecipeHorizontalList({
    required this.title,
    required this.recipes,
    super.key,
  });

  final String title;
  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return SizedBox(
                width: 240,
                child: RecipeListCard(recipe: recipe),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemCount: recipes.length,
          ),
        ),
      ],
    );
  }
}
