import 'package:flutter/material.dart';
import 'package:recall/core/configs/ai_model.dart';
import 'package:recall/core/theme/app_colors.dart';
import 'package:recall/core/utils/toast_util.dart';
import 'package:recall/features/recall/data/service/model_management_service.dart';
import 'package:recall/features/recall/presentation/pages/deck_list_page.dart';
import 'package:recall/features/recall/presentation/widgets/animated_button.dart';
import 'package:recall/features/recall/presentation/widgets/progress_bar.dart';
import 'package:recall/features/recall/presentation/widgets/square_button.dart';
import 'package:responsive_scaler/responsive_scaler.dart';
import 'package:url_launcher/url_launcher.dart';

class ModelSelectionPage extends StatefulWidget {
  final bool isSettingsMode;
  const ModelSelectionPage({super.key, this.isSettingsMode = false});

  @override
  State<ModelSelectionPage> createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  final ModelManagementService _service = ModelManagementService();
  String? _activeModelId;
  int _downloadedCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshState() async {
    final id = await _service.getActiveModelId();
    int count = 0;
    for (final model in AIModel.availableModels) {
      if (await _service.isModelDownloaded(model)) count++;
    }
    if (mounted) {
      setState(() {
        _activeModelId = id;
        _downloadedCount = count;
      });
    }
  }

  Future<void> _onActivate(AIModel model) async {
    try {
      await _service.activateModel(model);

      if (!mounted) return;

      // If the download was cancelled, activateModel returns silently.
      // Check if the model is actually downloaded before proceeding.
      final isDownloaded = await _service.isModelDownloaded(model);
      if (!isDownloaded) return;

      await _refreshState();

      if (mounted) {
        if (widget.isSettingsMode == true) {
          _goToHome();
        } else {
          ToastUtil.showNormal("Switched to ${model.name}!");
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError("Error: $e");
      }
    }
  }

  void _onCancelDownload(AIModel model) {
    _service.cancelDownload(model);
    ToastUtil.showNormal("${model.name} download cancelled");
  }

  Future<void> _onDelete(AIModel model) async {
    try {
      await _service.deleteModel(model);
      await _refreshState();
      if (mounted) {
        setState(() {});
        ToastUtil.showNormal("Model deleted from storage");
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError("Error deleting model");
      }
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeckListPage(isGuest: widget.isSettingsMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<AIModel> sortedModels = List.from(AIModel.availableModels);
    sortedModels.sort((a, b) {
      if (a.modelId == _activeModelId) return -1;
      if (b.modelId == _activeModelId) return 1;
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: widget.isSettingsMode == true
            ? null
            : Padding(
                padding: EdgeInsets.all(8.0.r),
                child: SquareButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                  color: Colors.black,
                ),
              ),
        title: Text(
          'AI BRAIN',
          style: TextStyle(
            fontSize: 22,
            fontVariations: [FontVariation.weight(900)],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: Colors.black, height: 4),
        ),
      ),
      body: ListView.builder(
        itemCount: sortedModels.length,
        itemBuilder: (context, index) {
          final model = sortedModels[index];
          final isActive = _activeModelId == model.modelId;
          final isProcessing = _service.isDownloading(model.modelId);
          final progress = _service.getProgress(model.modelId);

          return FutureBuilder<bool>(
            future: _service.isModelDownloaded(model),
            builder: (context, snapshot) {
              final isDownloaded = snapshot.data ?? false;
              return _buildModelCard(
                model,
                isActive,
                isProcessing,
                progress,
                isDownloaded,
                context,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModelCard(
    AIModel model,
    bool isActive,
    bool isProcessing,
    int progress,
    bool isDownloaded,
    BuildContext context,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.r, vertical: 12.r),
      padding: EdgeInsets.all(12.r),
      constraints: BoxConstraints(maxWidth: 200.r),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontVariations: [FontVariation.weight(900)],
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: accentColor(widget.isSettingsMode),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    "Active",
                    style: TextStyle(
                      color: Colors.black,
                      fontVariations: [FontVariation.weight(900)],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            model.description,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              splashFactory: NoSplash.splashFactory,
              overlayColor: Colors.transparent,
            ),
            onPressed: () => _launchUrl(model.readMore),
            child: Row(
              children: [
                Text(
                  "Read More",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 187, 165),
                    fontVariations: [FontVariation.weight(900)],
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12.r,
                  color: const Color.fromARGB(255, 0, 187, 165),
                ),
              ],
            ),
          ),
          Text(
            "Size: ${model.formattedSize}",
            style: TextStyle(fontVariations: [FontVariation.weight(900)]),
          ),
          SizedBox(height: 12.h),

          if (isProcessing) ...[
            Row(
              children: [
                Expanded(
                  child: ProgressBar(
                    progress: progress / 100,
                    isGuest: widget.isSettingsMode,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0.r),
                  child: SquareButton(
                    icon: Icons.close,
                    onTap: () => _onCancelDownload(model),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            Text(
              "Downloading: $progress%",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45.h,
                    child: AnimatedButton(
                      text: isDownloaded
                          ? (isActive ? "Selected" : "Switch to this")
                          : "Download",
                      onTap: isActive ? null : () => _onActivate(model),
                      color: isDownloaded
                          ? (isActive ? Colors.grey[300] : Colors.blue[100])
                          : accentColor(widget.isSettingsMode),
                      isGuest: widget.isSettingsMode,
                    ),
                  ),
                ),
                if (isDownloaded && _downloadedCount > 1) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    height: 45.h,
                    child: SquareButton(
                      icon: Icons.delete_outline,
                      onTap: () => _onDelete(model),
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ToastUtil.showError("Could not launch $url");
      }
    }
  }
}
