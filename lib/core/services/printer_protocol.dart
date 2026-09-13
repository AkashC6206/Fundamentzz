abstract class PrinterProtocol {
  /// Converts the given text/commands into the raw bytes understood by the printer.
  Future<List<int>> encodeText(String text, {int size = 1, bool bold = false});
  
  /// Generates the raw bytes for printing an image (e.g. logo).
  Future<List<int>> encodeImage(List<int> imageBytes);
  
  /// Generates the raw bytes to cut the paper (if supported).
  List<int> encodeCutPaper();
  
  /// Generates the raw bytes to open the cash drawer.
  List<int> encodeOpenDrawer();
  
  /// Generates raw bytes to feed paper.
  List<int> encodeFeed(int lines);
}
