/// Port that bundles persisted diagnostic logs into a single archive
/// and hands it off to the OS Share Sheet. Phase D-3 supplies the zip
/// + share_plus implementation; Phase D-1 only declares the surface so
/// the Application-layer [DiagnosticExportController] can be unit-tested
/// against a fake.
abstract class DiagnosticLogExporter {
  /// Bundle the current log directory into a single file (e.g. a zip)
  /// and return its absolute path. Implementations decide on the
  /// extension and naming.
  Future<String> createArchive();

  /// Hand the file at [path] to the OS Share Sheet. Returns once the
  /// share intent has been launched; success/cancellation of the
  /// downstream OS picker is not reported back (share_plus does not
  /// surface that).
  Future<void> share(String path);
}
