import '../entities/scan_log_entity.dart';

abstract class ScanLogRepository {

  Future<void> addScanLog(ScanLogEntity log);

  Future<List<ScanLogEntity>> getUserScanLogs(String userId);
}
