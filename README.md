# local-llm-bench

PowerShell scripts to download [llama.cpp](https://github.com/ggml-org/llama.cpp) binaries and GGUF models from Hugging Face, and run them locally as an OpenAI-compatible server.

## Prerequisites

- Windows 10/11 (x64)
- PowerShell 7+
- AMD GPU with ROCm support **or** any GPU/CPU with Vulkan support
- Sufficient VRAM/RAM for the models you intend to run (Q8 models are large — see table below)

---

## 1. Download llama.cpp

Run `Get-LlamaCpp.ps1` to fetch the latest pre-built binaries from GitHub releases.  
Three backends are downloaded automatically:

| Backend        | Source repo                  | Use when                               |
| -------------- | ---------------------------- | -------------------------------------- |
| `rocm-stable`  | `ggml-org/llama.cpp`         | AMD GPU, stable ROCm                   |
| `rocm-preview` | `lemonade-sdk/llamacpp-rocm` | AMD GPU, latest ROCm preview (gfx1151) |
| `vulkan`       | `ggml-org/llama.cpp`         | Any GPU via Vulkan, or CPU fallback    |

```powershell
.\Get-LlamaCpp.ps1
```

Binaries are extracted to `C:\AI\bin\llamacpp\<backend>\<version>\`.  
The runner scripts always pick the **latest build** automatically.

---

## 2. Download models from Hugging Face

Use `Get-ModelFromHuggingFace.ps1` to download GGUF files.

### Parameters

| Parameter       | Required | Default        | Description                                                  |
| --------------- | -------- | -------------- | ------------------------------------------------------------ |
| `-Repo`         | Yes      | —              | Hugging Face model path, e.g. `unsloth/Qwen3.6-35B-A3B-GGUF` |
| `-Files`        | Yes      | —              | Array of filenames to download                               |
| `-Revision`     | No       | `main`         | Branch or revision                                           |
| `-OutputFolder` | No       | `C:\AI\models` | Local destination folder                                     |

### Examples

**Qwen3.6-35B-A3B (general + coding, with multimodal projector)**

```powershell
.\Get-ModelFromHuggingFace.ps1 `
    -Repo "unsloth/Qwen3.6-35B-A3B-GGUF" `
    -Files @("Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf", "mmproj-BF16.gguf") `
    -OutputFolder "C:\AI\models\unsloth\Qwen3.6-35B-A3B-GGUF"
```

**Gemma 4 26B (multimodal)**

```powershell
.\Get-ModelFromHuggingFace.ps1 `
    -Repo "unsloth/gemma-4-26B-A4B-it-GGUF" `
    -Files @("gemma-4-26B-A4B-it-UD-Q8_K_XL.gguf", "mmproj-BF16.gguf") `
    -OutputFolder "C:\AI\models\unsloth\gemma-4-26B-A4B-it-GGUF"
```

**GLM-4.7 Flash**

```powershell
.\Get-ModelFromHuggingFace.ps1 `
    -Repo "unsloth/GLM-4.7-Flash-GGUF" `
    -Files @("GLM-4.7-Flash-UD-Q8_K_XL.gguf") `
    -OutputFolder "C:\AI\models\unsloth\GLM-4.7-Flash-GGUF"
```

**GPT-OSS 20B**

```powershell
.\Get-ModelFromHuggingFace.ps1 `
    -Repo "unsloth/gpt-oss-20b-GGUF" `
    -Files @("gpt-oss-20b-UD-Q8_K_XL.gguf") `
    -OutputFolder "C:\AI\models\unsloth\gpt-oss-20b-GGUF"
```

**Nemotron-3 Nano 30B**

```powershell
.\Get-ModelFromHuggingFace.ps1 `
    -Repo "unsloth/Nemotron-3-Nano-30B-A3B-GGUF" `
    -Files @("Nemotron-3-Nano-30B-A3B-UD-Q8_K_XL.gguf") `
    -OutputFolder "C:\AI\models\unsloth\Nemotron-3-Nano-30B-A3B-GGUF"
```

**Qwen3-Coder-Next**

```powershell
.\Get-ModelFromHuggingFace.ps1 `
    -Repo "unsloth/Qwen3-Coder-Next-GGUF" `
    -Files @("Qwen3-Coder-Next-UD-Q4_K_XL.gguf") `
    -OutputFolder "C:\AI\models\unsloth\Qwen3-Coder-Next-GGUF"
```

The script supports **resuming interrupted downloads** and shows download progress.

---

## 3. Run a model

### Convenience wrappers (recommended)

Each script launches `llama-server` with tuned parameters for that model:

| Script                            | Model                   | Notes   |
| --------------------------------- | ----------------------- | ------- |
| `Run-gemma-4-26B-A4B.ps1`         | Gemma 4 26B A4B         | —       |
| `Run-gemma-4-31B.ps1`             | Gemma 4 26B A4B         | —       |
| `Run-GLM-4.7-Flash.ps1`           | GLM-4.7 Flash           | —       |
| `Run-gpt-oss-20b.ps1`             | GPT-OSS 20B             | —       |
| `Run-Nemotron-3-Nano-30B-A3B.ps1` | Nemotron-3 Nano 30B A3B | —       |
| `Run-Qwen3-Coder-Next.ps1`        | Qwen3-Coder-Next        | Coding  |
| `Run-Qwen36-35B-A3B-Coding.ps1`   | Qwen3.6-35B-A3B         | Coding  |
| `Run-Qwen36-35B-A3B-General.ps1`  | Qwen3.6-35B-A3B         | General |

All wrappers accept an optional `-ContextSize` parameter (default varies per model):

```powershell
.\Run-Qwen36-35B-A3B-General.ps1
.\Run-Qwen36-35B-A3B-General.ps1 -ContextSize 32768
```

### Generic runner (`Run-LlamaCppServer.ps1`)

For full control, call the generic runner directly:

```powershell
.\Run-LlamaCppServer.ps1 `
    -Model "unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf" `
    -Alias "my-model" `
    -Backend rocm-stable `
    -ContextSize 16384 `
    -Temperature 0.7 `
    -TopP 0.95
```

**Key parameters:**

| Parameter          | Default        | Description                                               |
| ------------------ | -------------- | --------------------------------------------------------- |
| `-Backend`         | `rocm-stable`  | `rocm-stable`, `rocm-preview`, or `vulkan`                |
| `-Version`         | latest         | Pin a specific build, e.g. `b8948`                        |
| `-Model`           | —              | Path relative to `C:\AI\models`                           |
| `-Alias`           | —              | Model alias exposed in the API                            |
| `-MmProj`          | —              | Path to multimodal projector (relative to `C:\AI\models`) |
| `-ModelsPath`      | `C:\AI\models` | Root folder for models                                    |
| `-ContextSize`     | `8192`         | Context window size in tokens                             |
| `-Temperature`     | `1.0`          | Sampling temperature                                      |
| `-TopP`            | `0.95`         | Top-p sampling                                            |
| `-TopK`            | —              | Top-k sampling                                            |
| `-MinP`            | —              | Min-p sampling                                            |
| `-PresencePenalty` | —              | Presence penalty                                          |
| `-Seed`            | —              | RNG seed for reproducibility                              |

Once running, `llama-server` exposes an **OpenAI-compatible API** at `http://localhost:8080`.

---

## Directory layout

```
C:\AI\
├── Get-LlamaCpp.ps1                  # Download llama.cpp binaries
├── Get-ModelFromHuggingFace.ps1      # Download models from Hugging Face
├── Run-LlamaCppServer.ps1            # Generic model runner
├── Run-<ModelName>.ps1               # Per-model convenience wrappers
├── bin\
│   ├── llamacpp\                     # GPU LLMs, embedding, and reranking
│   │   ├── rocm-stable\<build>\
│   │   ├── rocm-preview\<build>\
│   │   └── vulkan\<build>\
└── models\
    └── <repo>\
        └── <model-name>\
            └── *.gguf
```
