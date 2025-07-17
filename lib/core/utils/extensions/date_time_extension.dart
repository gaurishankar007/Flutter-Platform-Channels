extension DateTimeExtension on DateTime {
  /// Gives current date time in (day year month) format.
  /// 
  /// Like 172501, 17 day, 25 year, 01 month
  String getFormattedDate() {
    DateTime now = DateTime.now();
    String day =
        now.day.toString().padLeft(2, '0'); // Ensure two digits for day
    String year = (now.year % 100)
        .toString()
        .padLeft(2, '0'); // Last two digits of the year
    String month =
        now.month.toString().padLeft(2, '0'); // Ensure two digits for month

    return "$day$year$month";
  }
}
