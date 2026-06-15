import '../dashboard/dashboard_filters.dart';

enum ReportVereditoFilter { all, approved, rejected }

class ReportFilters {
  const ReportFilters({
    this.period = DashboardPeriod.week,
    this.idProduto,
    this.deviceId,
    this.opSearch = '',
  });

  final DashboardPeriod period;
  final String? idProduto;
  final String? deviceId;
  final String opSearch;

  DateTime? get since => sinceForDashboardPeriod(period);

  ReportFilters copyWith({
    DashboardPeriod? period,
    String? idProduto,
    String? deviceId,
    String? opSearch,
    bool clearIdProduto = false,
    bool clearDeviceId = false,
  }) {
    return ReportFilters(
      period: period ?? this.period,
      idProduto: clearIdProduto ? null : (idProduto ?? this.idProduto),
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
      opSearch: opSearch ?? this.opSearch,
    );
  }
}
