import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';

class FoundBook {
  final String path;
  final String name;
  final int sizeBytes;
  FoundBook({required this.path, required this.name, required this.sizeBytes});
}

class SearchState {
  final bool isLoading;
  final List<FoundBook> results;
  SearchState({required this.isLoading, required this.results});

  SearchState.initial() : isLoading = false, results = [];
  SearchState.loading() : isLoading = true, results = [];
  SearchState.data(List<FoundBook> r) : isLoading = false, results = r;
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(): super(SearchState.initial());

  Future<List<FoundBook>> startSearch() async {
    
    state = SearchState.loading();

  
    await Future.delayed(const Duration(seconds: 2));

    final List<FoundBook> found = []; 

    state = SearchState.data(found);
    return found;
  }
}

final searchControllerProvider = StateNotifierProvider<SearchController, SearchState>(
  (ref) => SearchController(),
);
