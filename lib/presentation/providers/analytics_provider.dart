import 'package:flutter/foundation.dart';
import '../../domain/use_cases/get_analytics_usecase.dart';

enum AnalyticsDatePreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  custom,
}

class AnalyticsProvider extends ChangeNotifier {
  final GetAnalyticsUseCase _getAnalyticsUseCase;

  AnalyticsProvider(this._getAnalyticsUseCase);

  AnalyticsReportData? _reportData;
  AnalyticsDatePreset _selectedPreset = AnalyticsDatePreset.last7Days;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  AnalyticsReportData? get reportData => _reportData;
  AnalyticsDatePreset get selectedPreset => _selectedPreset;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    notifyListeners();

    // Ensure start date has 00:00:00 and end date has 23:59:59
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final res = await _getAnalyticsUseCase.execute(
      startDate: start,
      endDate: end,
    );

    if (res.isSuccess) {
      _reportData = res.data;
    } else {
      _errorMessage = res.failure?.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setPreset(AnalyticsDatePreset preset) {
    _selectedPreset = preset;
    final now = DateTime.now();

    switch (preset) {
      case AnalyticsDatePreset.today:
        _startDate = now;
        _endDate = now;
        break;
      case AnalyticsDatePreset.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        _startDate = yest;
        _endDate = yest;
        break;
      case AnalyticsDatePreset.last7Days:
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
        break;
      case AnalyticsDatePreset.last30Days:
        _startDate = now.subtract(const Duration(days: 29));
        _endDate = now;
        break;
      case AnalyticsDatePreset.thisMonth:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case AnalyticsDatePreset.custom:
        break;
    }

    loadAnalytics();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _selectedPreset = AnalyticsDatePreset.custom;
    _startDate = start;
    _endDate = end;
    loadAnalytics();
  }
}
