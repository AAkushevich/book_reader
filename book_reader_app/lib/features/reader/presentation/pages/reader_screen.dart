import 'package:book_reader_app/core/theme/app_fonts.dart';
import 'package:book_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:book_reader_app/features/reader/presentation/pages/table_of_contents_screen.dart';
import 'package:book_reader_app/features/reader/presentation/widgets/page_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_reader_app/features/reader/presentation/providers/reader_provider.dart';
import 'package:book_reader_app/core/theme/reader_themes.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String filePath;
  final String bookTitle;
  final String bookAuthor;

  const ReaderScreen({
    super.key,
    required this.filePath,
    required this.bookTitle,
    required this.bookAuthor,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> with WidgetsBindingObserver {
  PageController? _pageController;
  bool _showControls = false;
  int _selectedTab = 1;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final textScaler = MediaQuery.of(context).textScaler;
      ref.read(readerProvider.notifier).openBook(
        widget.filePath,
        widget.bookTitle,
        widget.bookAuthor,
        size,
        textScaler,
      );
    });
  }

  @override
  void dispose() {
    _saveProgressOnExit();
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();
    super.dispose();
  }

  void _saveProgressOnExit() {
    final currentState = ref.read(readerProvider).value;
    if (currentState != null && currentState.progress != null) {
      ref.read(readerProvider.notifier).goToPage(currentState.currentPageIndex);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveProgressOnExit();
    }
  }

  ReaderThemeData _getCurrentTheme(AsyncValue<ReaderState> asyncState) {
    final themeIndex = asyncState.value?.progress?.themeIndex ?? 1;
    return ReaderThemeData.getByIndex(themeIndex);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(readerProvider);
    final theme = _getCurrentTheme(asyncState);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _showControls ? _buildAppBar(theme) : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_showControls) {
                setState(() => _showControls = false);
              }
            },
            child: Stack(
              children: [
                _buildPageView(asyncState, theme),
                _buildProgressIndicator(asyncState, theme),
              ],
            ),
          ),
          if (_showControls) _buildBottomPanel(asyncState, theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ReaderThemeData theme) {
    final iconColor = theme.textColor.withOpacity(0.85);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: iconColor, size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildPageView(AsyncValue<ReaderState> asyncState, ReaderThemeData theme) {
    return asyncState.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.accentColor),
            const SizedBox(height: 16),
            Text('Подготовка книги...', style: TextStyle(color: theme.textColor)),
          ],
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.accentColor),
              const SizedBox(height: 16),
              Text(
                'Не удалось открыть книгу:\n${err.toString()}',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textColor),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        if (!state.isReady) {
          return Center(
            child: Text('Обработка текста...', style: TextStyle(color: theme.textColor)),
          );
        }

        if (state.pages.isEmpty) {
          return Center(
            child: Text('В книге не найден текст.', style: TextStyle(color: theme.textColor)),
          );
        }

        _pageController ??= PageController(initialPage: state.currentPageIndex);

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth - 40;
            final contentHeight = constraints.maxHeight - 60;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(contentSizeProvider.notifier).update(Size(contentWidth, contentHeight));
            });

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: state.pages.length,
                  onPageChanged: (index) => ref.read(readerProvider.notifier).goToPage(index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: CustomPaint(
                        painter: PagePainter(state.pages[index], theme.textColor),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
                // Тройная зона тапов
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (state.currentPageIndex > 0) {
                              _pageController?.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => setState(() => _showControls = !_showControls),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (state.currentPageIndex < state.pages.length - 1) {
                              _pageController?.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomPanel(AsyncValue<ReaderState> asyncState, ReaderThemeData theme) {
    final state = asyncState.value;
    if (state == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? const Color(0xFF252547) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              color: _selectedTab == 0 ? const Color(0xFF6C63FF) : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'СОДЕРЖАНИЕ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.w400,
                                color: _selectedTab == 0 ? const Color(0xFF6C63FF) : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? const Color(0xFF252547) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              color: _selectedTab == 1 ? const Color(0xFF6C63FF) : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'НАСТРОЙКИ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.w400,
                                color: _selectedTab == 1 ? const Color(0xFF6C63FF) : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2A4A)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedTab == 0
                  ? _buildContentTab(state, theme)
                  : _buildSettingsTab(state, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab(ReaderState state, ReaderThemeData theme) {
    final totalPages = state.pages.length;
    final currentPage = state.currentPageIndex + 1;
    final progressPercent = totalPages > 0 ? ((currentPage / totalPages) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.bookTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.bookAuthor,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: true,
                      barrierColor: const Color(0xFF1A1A2E),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return TableOfContentsScreen(
                          bookTitle: state.bookTitle,
                          bookAuthor: state.bookAuthor,
                          chapters: state.chapters,
                          currentPageIndex: state.currentPageIndex,
                          pages: state.pages,
                          onChapterTap: (pageIndex) {
                            Navigator.pop(context);
                            _pageController?.jumpToPage(pageIndex);
                            ref.read(readerProvider.notifier).goToPage(pageIndex);
                          },
                        );
                      },
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252547),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.list, color: Color(0xFF6C63FF), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Оглавление',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalPages > 0 ? currentPage / totalPages : 0,
              backgroundColor: const Color(0xFF2A2A4A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4081)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontFamily: AppFonts.comfortaa,
                ),
              ),
              Text(
                '$currentPage из $totalPages',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(ReaderState state, ReaderThemeData theme) {
    final currentThemeIndex = state.progress?.themeIndex ?? 1;
    final currentFontIndex = state.progress?.fontIndex ?? 0;
    final fontName = ReadingProgress.getFontName(currentFontIndex);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeCircle(Colors.white, currentThemeIndex == 0, 0),
              _buildThemeCircle(const Color(0xFFF4ECD8), currentThemeIndex == 1, 1),
              _buildThemeCircle(const Color(0xFF2C2C2C), currentThemeIndex == 2, 2),
              _buildThemeCircle(Colors.black, currentThemeIndex == 3, 3),
            ],
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () {
              final nextFontIndex = (currentFontIndex + 1) % 3;
              ref.read(readerProvider.notifier).changeFont(
                nextFontIndex,
                MediaQuery.of(context).size,
              );
            },
            child: Text(
              fontName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentFontIndex ? const Color(0xFF6C63FF) : Colors.grey,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildSettingButton(
                  icon: Icons.text_fields,
                  label: 'Размер',
                  onTap: () => _showFontSizeDialog(state),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingButton(
                  icon: Icons.border_all,
                  label: 'Поля',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingButton(
                  icon: Icons.format_line_spacing,
                  label: 'Строки',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeCircle(Color color, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        ref.read(readerProvider.notifier).changeTheme(
          index,
          MediaQuery.of(context).size,
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.black, size: 24)
            : null,
      ),
    );
  }

  Widget _buildSettingButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF252547),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(ReaderState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Размер шрифта', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.progress?.fontSize.round() ?? 16}',
              style: const TextStyle(color: Colors.white, fontSize: 32),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    final current = state.progress?.fontSize ?? 16.0;
                    final newSize = (current - 1).clamp(12.0, 32.0);
                    ref.read(readerProvider.notifier).changeFontSize(
                      newSize,
                      MediaQuery.of(context).size,
                    );
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    final current = state.progress?.fontSize ?? 16.0;
                    final newSize = (current + 1).clamp(12.0, 32.0);
                    ref.read(readerProvider.notifier).changeFontSize(
                      newSize,
                      MediaQuery.of(context).size,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(AsyncValue<ReaderState> asyncState, ReaderThemeData theme) {
    final state = asyncState.value;

    if (state == null || !state.isReady || state.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalPages = state.pages.length;
    final currentPage = state.currentPageIndex + 1;

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => ref.read(readerProvider.notifier).toggleProgressFormat(),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              state.showProgressAsPercent
                  ? '${((currentPage / totalPages) * 100).round()}%'
                  : '$currentPage из $totalPages',
              style: TextStyle(
                color: theme.textColor.withOpacity(0.6),
                fontSize: 12,
                fontFamily: AppFonts.comfortaa,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}