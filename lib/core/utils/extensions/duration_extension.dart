extension DurationExtension on Duration {
  /// Returns the duration in string format HH:MM:SS.
  /// Hours and minutes will be added only if they are available
  String toHMS() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    final twoDigitSeconds = seconds.toString().padLeft(2, '0');
    final twoDigitMinutes = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      final twoDigitHours = hours.toString().padLeft(2, '0');
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    } else if (minutes > 0) {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
    return twoDigitSeconds;
  }

  /// Returns the duration in string format HH:MM:SS.
  String formatDuration() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
