/// Reads available bytes on the volume that stores imported sound copies.
abstract class StorageCapacityReader {
  Future<int> getAvailableBytes();
}
