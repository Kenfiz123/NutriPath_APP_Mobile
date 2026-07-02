import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/prompt_dialog.dart';
import '../widgets/question_answer_dialog.dart';
import '../widgets/recipe_details_sheet.dart';
import '../widgets/recipe_horizontal_list.dart';
import '../widgets/recipe_list_card.dart';

class FullRecipesScreen extends ConsumerStatefulWidget {
  const FullRecipesScreen({super.key});

  @override
  ConsumerState<FullRecipesScreen> createState() => _FullRecipesScreenState();
}

class _FullRecipesScreenState extends ConsumerState<FullRecipesScreen> {
  final _search = TextEditingController();
  String _tag = 'Tất cả';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arg = (search: _search.text.trim(), tag: _tag);
    final asyncRecipes = ref.watch(fullRecipesProvider(arg));
    final asyncSaved = ref.watch(personalizedRecipesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(fullRecipesProvider(arg));
        ref.invalidate(personalizedRecipesProvider);
      },
      child: asyncRecipes.when(
        loading: () => const LoadingPanel(),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.invalidate(fullRecipesProvider(arg)),
            ),
          ],
        ),
        data: (data) {
          final tags = ['Tất cả', ...data.tags];
          return NutriPage(
            children: [
              SectionHeader(
                title: 'Công thức',
                subtitle: 'Tìm món theo tag, calo và tạo gợi ý cá nhân hóa.',
                action: IconButton.filledTonal(
                  tooltip: 'AI cá nhân hóa',
                  onPressed: () => _generatePersonalized(context),
                  icon: const Icon(Icons.auto_awesome),
                ),
              ),
              NutriCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Tìm món hoặc nguyên liệu',
                      ),
                      onSubmitted: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          return ChoiceChip(
                            label: Text(tag),
                            selected: tag == _tag,
                            onSelected: (_) {
                              setState(() {
                                _tag = tag;
                              });
                            },
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: tags.length,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.access?.recipeLimit != null)
                LockedPanel(
                  title:
                      'Giới hạn công thức ${data.access!.tier.toUpperCase()}',
                  message:
                      'Nâng cấp để xem thêm công thức và dùng AI cá nhân hóa.',
                ),
              asyncSaved.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (saved) {
                  if (saved.isEmpty) return const SizedBox.shrink();
                  return RecipeHorizontalList(
                    title: 'Đã cá nhân hóa',
                    recipes: saved,
                  );
                },
              ),
              const SectionHeader(title: 'Thư viện món ăn'),
              if (data.recipes.isEmpty)
                const EmptyState(
                  title: 'Chưa có công thức phù hợp',
                  message: 'Thử bỏ bớt bộ lọc hoặc tìm nguyên liệu khác.',
                  icon: Icons.menu_book_outlined,
                )
              else
                for (final recipe in data.recipes)
                  RecipeListCard(recipe: recipe),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generatePersonalized(BuildContext context) async {
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) => const PromptDialog(
        title: 'AI cá nhân hóa công thức',
        label: 'Bạn muốn món như thế nào?',
        hint: 'Ví dụ: bữa tối ít carb, giàu protein, nấu dưới 20 phút',
      ),
    );
    if (prompt == null || prompt.trim().isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      var result = await api.generatePersonalizedRecipe({'prompt': prompt});
      final questions = jsonMapList(result['questions']);
      if (asString(result['status']) == 'needs_questions' &&
          questions.isNotEmpty &&
          context.mounted) {
        final answers = await showDialog<JsonMap>(
          context: context,
          builder: (context) => QuestionAnswerDialog(questions: questions),
        );
        if (answers == null) return;
        result = await api.generatePersonalizedRecipe({
          'prompt': prompt,
          'answers': answers,
        });
      }
      final recipe = Recipe.fromJson(result['recipe']);
      ref.invalidate(personalizedRecipesProvider);
      if (context.mounted) {
        showSnack(context, 'Đã tạo công thức cá nhân hóa.');
        await showRecipeDetails(context, recipe);
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}
