/// Format a [Duration] as `UTC±H` (whole-hour zones) or `UTC±H:MM`
/// (sub-hour zones such as `Asia/Kolkata` UTC+5:30, `Australia/Adelaide`
/// UTC+9:30, `Asia/Kathmandu` UTC+5:45).
///
/// `Duration.isNegative` is the single source of truth for the sign,
/// so DST-boundary instants don't produce inverted labels (e.g.
/// "UTC-12" for an offset that briefly crosses zero). `Duration.zero`
/// formats as `UTC+0` — callers who need a `UTC` short form are
/// expected to special-case it themselves.
String formatUtcOffset(Duration offset) {
  final bool negative = offset.isNegative;
  final int h = offset.inHours.abs();
  final int m = offset.inMinutes.abs() % 60;
  final String sign = negative ? '-' : '+';
  return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
}
