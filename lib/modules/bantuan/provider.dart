import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model.dart';
import 'service.dart';

class HelpCenterState {
  const HelpCenterState({this.query = '', this.categoryId});

  final String query;
  final String? categoryId;

  HelpCenterState copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
  }) => HelpCenterState(
    query: query ?? this.query,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
  );
}

class HelpCenterNotifier extends Notifier<HelpCenterState> {
  @override
  HelpCenterState build() => const HelpCenterState();

  void setQuery(String value) => state = state.copyWith(query: value);

  void toggleCategory(String categoryId) {
    final current = state.categoryId;
    state = current == categoryId
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryId: categoryId);
  }
}

final helpCenterProvider =
    NotifierProvider<HelpCenterNotifier, HelpCenterState>(
      HelpCenterNotifier.new,
    );

final filteredFaqsProvider = Provider<List<FaqItem>>((ref) {
  final filter = ref.watch(helpCenterProvider);
  final normalized = filter.query.trim().toLowerCase();
  return helpFaqs
      .where((item) {
        final matchCategory =
            filter.categoryId == null || item.categoryId == filter.categoryId;
        final matchQuery =
            normalized.isEmpty ||
            item.question.toLowerCase().contains(normalized) ||
            item.answer.toLowerCase().contains(normalized);
        return matchCategory && matchQuery;
      })
      .toList(growable: false);
});
