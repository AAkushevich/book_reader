import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/features/reader/presentation/providers/reader_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String filePath;

  const ReaderScreen({super.key, required this.filePath});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final PageController _pageController = PageController();
  bool _showControls = true;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      ref.read(readerProvider.notifier).openBook(widget.filePath, size);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(readerProvider);

    return Scaffold(
      backgroundColor: _getBackgroundColor(ref, asyncState),
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => setState(() => _showSettings = !_showSettings),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            _buildPageView(asyncState),
            if (_showSettings) _buildSettingsOverlay(asyncState),
            if (_showControls) _buildProgressIndicator(asyncState),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(WidgetRef ref, AsyncValue<ReaderState> asyncState) {
    final session = asyncState.value?.progress;
    if (session?.isDarkMode == true) return const Color(0xFF121212);
    return const Color(0xFFFDF6E3);
  }

  Color _getTextColor(AsyncValue<ReaderState> asyncState) {
    final session = asyncState.value?.progress;
    if (session?.isDarkMode == true) return Colors.grey[200]!;
    return const Color(0xFF423826);
  }

  Widget _buildPageView(AsyncValue<ReaderState> asyncState) {
    return asyncState.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Подготовка книги...'),
          ],
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Не удалось открыть книгу:\n${err.toString()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        // ✅ Ключевая проверка: не показываем UI, пока isReady != true
        if (!state.isReady) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //CircularProgressIndicator(),
                //SizedBox(height: 16),
                Text('Обработка текста...'),
              ],
            ),
          );
        }

        if (state.pages.isEmpty) {
          return const Center(
            child: Text('В книге не найден текст.\nВозможно, файл повреждён.'),
          );
        }

        return PageView.builder(
          controller: _pageController,
          itemCount: state.pages.length,
          onPageChanged: (index) => ref.read(readerProvider.notifier).goToPage(index),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: _TextPage(
                content: state.pages[index],
                fontSize: state.progress?.fontSize ?? 16.0,
                fontFamily: state.progress?.fontFamily ?? 'sans-serif',
                textColor: _getTextColor(asyncState),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsOverlay(AsyncValue<ReaderState> asyncState) {
    return Positioned(
      top: kToolbarHeight,
      right: 16,
      left: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Тёмная тема'),
                  Switch(
                    value: asyncState.value?.progress?.isDarkMode ?? false,
                    onChanged: (_) => ref.read(readerProvider.notifier).toggleTheme(),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Размер шрифта'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _changeFontSize(asyncState, -1),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _changeFontSize(asyncState, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeFontSize(AsyncValue<ReaderState> asyncState, int delta) {
    final current = asyncState.value?.progress?.fontSize ?? 16.0;
    final newSize = (current + delta).clamp(12.0, 32.0);
    final size = MediaQuery.of(context).size;
    ref.read(readerProvider.notifier).changeFontSize(newSize, size);
  }

  Widget _buildProgressIndicator(AsyncValue<ReaderState> asyncState) {
    final state = asyncState.value;
    if (state == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Стр. ${state.currentPageIndex + 1} из ${state.pages.length}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TextPage extends StatelessWidget {
  final String content;
  final double fontSize;
  final String fontFamily;
  final Color textColor;

  const _TextPage({
    required this.content,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: 1.5,
          color: textColor,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}