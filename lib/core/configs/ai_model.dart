class AIModel {
  final String name;
  final String modelId;
  final String modelFile;
  final String description;
  final int sizeInBytes;
  final String commitHash;
  final String modelType;
  final String readMore;

  AIModel({
    required this.name,
    required this.modelId,
    required this.modelFile,
    required this.description,
    required this.sizeInBytes,
    required this.commitHash,
    required this.modelType,
    required this.readMore,
  });

  /// Construct Hugging face url
  /// Reference: https://github.com/google-ai-edge/gallery/blob/1a1645a72302b2f76a94744cf9b82904f4d55e91/Android/src/app/src/main/java/com/google/ai/edge/gallery/data/ModelAllowlist.kt#L51

  String get downloadUrl {
    return "https://huggingface.co/$modelId/resolve/$commitHash/$modelFile?download=true";
  }

  String get formattedSize {
    final gb = sizeInBytes / (1024 * 1024 * 1024);
    if (gb < 1) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${gb.toStringAsFixed(2)} GB';
  }

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      name: json['name'] as String,
      modelId: json['modelId'] as String,
      modelFile: json['modelFile'] as String,
      description: json['description'] as String,
      sizeInBytes: json['sizeInBytes'] as int,
      commitHash: json['commitHash'] as String,
      modelType: json['modelType'] as String,
      readMore: json['readMore'] as String,
    );
  }

  static List<AIModel> get availableModels {
    const jsonList = [
      {
        "name": "Gemma3-1B-IT",
        "modelId": "litert-community/Gemma3-1B-IT",
        "modelFile": "gemma3-1b-it-int4.litertlm",
        "description":
            "A variant of google/Gemma-3-1B-IT with 4-bit quantization ready for deployment on Android using LiteRT-LM.",
        "sizeInBytes": 584417280,
        "commitHash": "42d538a932e8d5b12e6b3b455f5572560bd60b2c",
        "modelType": "gemmaIt",
        "readMore": "https://huggingface.co/google/gemma-3-1b-it",
      },
      {
        "name": "Gemma-3n-E2B-it",
        "modelId": "google/gemma-3n-E2B-it-litert-lm",
        "modelFile": "gemma-3n-E2B-it-int4.litertlm",
        "description":
            "A variant of Gemma 3n E2B ready for deployment on Android using LiteRT-LM. It supports text, vision, and audio input, with 4096 context length.",
        "sizeInBytes": 3655827456,
        "commitHash": "ba9ca88da013b537b6ed38108be609b8db1c3a16",
        "modelType": "gemmaIt",
        "readMore": "https://huggingface.co/google/gemma-3n-E2B-it-litert-lm",
      },
      {
        "name": "Gemma-3n-E4B-it",
        "modelId": "google/gemma-3n-E4B-it-litert-lm",
        "modelFile": "gemma-3n-E4B-it-int4.litertlm",
        "description":
            "A variant of Gemma 3n E4B ready for deployment on Android using LiteRT-LM. It supports text, vision, and audio input, with 4096 context length.",
        "sizeInBytes": 4919541760,
        "commitHash": "297ed75955702dec3503e00c2c2ecbbf475300bc",
        "modelType": "gemmaIt",
        "readMore": "https://huggingface.co/google/gemma-3n-E4B-it-litert-lm",
      },

      {
        "name": "Qwen2.5-1.5B-Instruct",
        "modelId": "litert-community/Qwen2.5-1.5B-Instruct",
        "modelFile":
            "Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm",
        "description":
            "A variant of Qwen/Qwen2.5-1.5B-Instruct ready for deployment on Android using LiteRT-LM.",
        "sizeInBytes": 1597931520,
        "commitHash": "19edb84c69a0212f29a6ef17ba0d6f278b6a1614",
        "modelType": "qwen",
        "readMore":
            "https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct",
      },
      {
        "name": "Phi-4-mini-instruct",
        "modelId": "litert-community/Phi-4-mini-instruct",
        "modelFile":
            "Phi-4-mini-instruct_multi-prefill-seq_q8_ekv4096.litertlm",
        "description":
            "A variant of microsoft/Phi-4-mini-instruct ready for deployment on Android using LiteRT-LM.",
        "sizeInBytes": 3910090752,
        "commitHash": "054f4e2694a86f81a129a40596e08b8d74770a9d",
        "modelType": "general",
        "readMore":
            "https://huggingface.co/litert-community/Phi-4-mini-instruct",
      },
      {
        "name": "DeepSeek-R1-Distill-Qwen-1.5B",
        "modelId": "litert-community/DeepSeek-R1-Distill-Qwen-1.5B",
        "modelFile":
            "DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv4096.litertlm",
        "description":
            "A variant of deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B ready for deployment on Android using LiteRT-LM.",
        "sizeInBytes": 1833451520,
        "commitHash": "e34bb88632342d1f9640bad579a45134eb1cf988",
        "modelType": "deepSeek",
        "readMore":
            "https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B",
      },
    ];

    return jsonList.map((e) => AIModel.fromJson(e)).toList();
  }
}
