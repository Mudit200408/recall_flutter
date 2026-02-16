import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model_management/cancel_token.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:recall/core/configs/ai_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManagementService {
  // Singleton
  static final ModelManagementService _instance = ModelManagementService._();
  factory ModelManagementService() => _instance;
  ModelManagementService._();

  static const String _prefActiveModelId = 'active_model_id';

  // Persistent download state — survives navigation
  final Map<String, int> progressMap = {};
  final Map<String, CancelToken> cancelTokenMap = {};

  // Listeners that UI can register/unregister
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  // Check if the specific model file is already on device
  Future<bool> isModelDownloaded(AIModel model) async {
    return await FlutterGemma.isModelInstalled(model.modelFile);
  }

  // Get ID of the currently selected model
  Future<String?> getActiveModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveModelId);
  }

  // Delete the model from storage
  Future<void> deleteModel(AIModel model) async {
    await FlutterGemma.uninstallModel(model.modelFile);
    final activeId = await getActiveModelId();
    if (activeId == model.modelId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefActiveModelId);
    }
  }

  /// Cancel a specific model's download
  Future<void> cancelDownload(AIModel model) async {
    cancelTokenMap[model.modelId]?.cancel("Download Cancelled");
    progressMap.remove(model.modelId);
    cancelTokenMap.remove(model.modelId);
    _notifyListeners();

    // Also kill the native download task (flutter_gemma's CancelToken is buggy)
    try {
      final tasks = await FileDownloader().allTasks(group: 'smart_downloads');
      for (final task in tasks) {
        if (task.url.contains(model.modelFile)) {
          await FileDownloader().cancelTaskWithId(task.taskId);
          debugPrint('🛑 Cancelled native download for ${model.name}');
          break;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error cancelling native download: $e');
    }
  }

  /// Download the model and set it as active
  Future<void> activateModel(AIModel model) async {
    final token = CancelToken();
    progressMap[model.modelId] = 0;
    cancelTokenMap[model.modelId] = token;
    _notifyListeners();

    // Determine model type
    final ModelType type;
    if (model.modelType == 'gemmaIt') {
      type = ModelType.gemmaIt;
    } else if (model.modelType == 'deepSeek') {
      type = ModelType.deepSeek;
    } else if (model.modelType == 'qwen') {
      type = ModelType.qwen;
    } else {
      type = ModelType.general;
    }

    try {
      final builder = FlutterGemma.installModel(
        modelType: type,
      ).fromNetwork(model.downloadUrl);

      builder.withCancelToken(token);

      builder.withProgress((progress) {
        if (token.isCancelled) return;
        progressMap[model.modelId] = progress;
        _notifyListeners();
      });

      await builder.install();

      if (token.isCancelled) return;

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveModelId, model.modelId);

      // Clean up state
      progressMap.remove(model.modelId);
      cancelTokenMap.remove(model.modelId);
      _notifyListeners();
    } catch (e) {
      if (token.isCancelled) return;
      progressMap.remove(model.modelId);
      cancelTokenMap.remove(model.modelId);
      _notifyListeners();
      rethrow;
    }
  }

  bool isDownloading(String modelId) => progressMap.containsKey(modelId);
  int getProgress(String modelId) => progressMap[modelId] ?? 0;

  /// Ensures the selected model is actually loaded into the native engine.
  Future<void> ensureActiveModelLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_prefActiveModelId);

    if (activeId == null) return;

    try {
      final modelConfig = AIModel.availableModels.firstWhere(
        (m) => m.modelId == activeId,
      );

      final isInstalled = await FlutterGemma.isModelInstalled(
        modelConfig.modelFile,
      );

      if (isInstalled && !FlutterGemma.hasActiveModel()) {
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromNetwork(modelConfig.downloadUrl).install();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading model: $e');
    }
  }
}
