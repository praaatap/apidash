import 'package:apidash_core/apidash_core.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:genai/consts.dart';
import 'ai_model_selector_dialog.dart';

class AIModelSelectorButton extends StatelessWidget {
  final AIRequestModel? aiRequestModel;
  final bool readonly;
  final Function(AIRequestModel)? onModelUpdated;
  final bool useRootNavigator;
  final VoidCallback? onDialogOpen;
  final VoidCallback? onDialogClose;

  const AIModelSelectorButton({
    super.key,
    this.aiRequestModel,
    this.readonly = false,
    this.onModelUpdated,
    this.useRootNavigator = true,
    this.onDialogOpen,
    this.onDialogClose,
  });

  String _getModelName(AIRequestModel? requestModel) {
    if (requestModel == null || requestModel.model == null) {
      return 'Select Model';
    }
    final provider = requestModel.modelApiProvider;
    if (provider == null) return requestModel.model!;

    final providerModels = kAvailableModels.map[provider]?.models;
    if (providerModels == null) return requestModel.model!;

    for (final m in providerModels) {
      if (m.id == requestModel.model) {
        return m.name ?? requestModel.model!;
      }
    }
    return requestModel.model!;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: readonly
          ? null
          : () async {
              onDialogOpen?.call();
              final newAIRequestModel = await showDialog<AIRequestModel>(
                context: context,
                useRootNavigator: useRootNavigator,
                builder: (context) {
                  return AlertDialog(
                    scrollable: true,
                    content: AIModelSelectorDialog(
                      aiRequestModel: aiRequestModel,
                    ),
                    contentPadding: kP10,
                  );
                },
              );
              onDialogClose?.call();
              if (newAIRequestModel == null) return;
              onModelUpdated?.call(newAIRequestModel);
            },
      child: Text(
        _getModelName(aiRequestModel),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
