String formatTimeAgo(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'только что';
  if (diff.inMinutes < 60) return '${diff.inMinutes} ${_p(diff.inMinutes, 'минуту', 'минуты', 'минут')} назад';
  if (diff.inHours < 24) return '${diff.inHours} ${_p(diff.inHours, 'час', 'часа', 'часов')} назад';
  if (diff.inDays < 7) return '${diff.inDays} ${_p(diff.inDays, 'день', 'дня', 'дней')} назад';
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return '$w ${_p(w, 'неделю', 'недели', 'недель')} назад';
  }
  if (diff.inDays < 365) {
    final m = (diff.inDays / 30).floor();
    return '$m ${_p(m, 'месяц', 'месяца', 'месяцев')} назад';
  }
  final y = (diff.inDays / 365).floor();
  return '$y ${_p(y, 'год', 'года', 'лет')} назад';
}

String _p(int n, String o, String f, String m) {
  final a = n % 10, b = n % 100;
  if (a == 1 && b != 11) return o;
  if (a >= 2 && a <= 4 && (b < 10 || b >= 20)) return f;
  return m;
}