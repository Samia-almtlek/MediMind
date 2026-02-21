# Local Medical Context QA System — Documentation

## Overview

This setup implements a **local, offline, restricted-context question-answering system** using LM Studio and lightweight open-source language models.  
The system is designed to:

- Run entirely locally
- Never access the internet
- Only answer using explicitly provided context
- Minimize hallucinations
- Support medical or regulatory text processing
- Stream tokens for responsive output
- Be migration-ready for a future production server

The language model is treated strictly as a **text transformation engine**, not a knowledge authority.

---

## Architecture

[ Data Source / API / File ]
↓
Context Injection
↓
LM Studio Local Server
↓
OpenAI-Compatible API
↓
Streaming Token Output


Key separation of concerns:

- **Data acquisition**: external (API, file, database)
- **Inference**: local model via LM Studio
- **Control & safety**: prompt + decoding parameters

---

## Models Used

### Primary Model — Strict QA
- **Model**: `qwen2.5-3b-instruct`
- **Format**: GGUF
- **Quantization**: Q4_K_M (~1.9 GB)
- **Purpose**: factual extraction and bounded answering

### Secondary Model (optional)
- **Model**: `phi-3-mini-4k-instruct`
- **Purpose**: explanation and rephrasing (still context-restricted)

---

## LM Studio Configuration

### Server Mode
- Enabled
- Endpoint:
http://IP_GIVEN_BY_LM_STUDIO:1234/v1/chat/completions
- OpenAI-compatible API

### Hardware
- Threads: all physical cores
- GPU offload: maximum stable value
- Context size: ≥ 4096 tokens (recommended)

---

## Prompting Rules (Critical)

### Context Boundary

All allowed information **must** be enclosed between explicit markers:

BEGIN_CONTEXT

\<authorized text>

END_CONTEXT


Anything outside this boundary is considered unavailable to the model.

---

### System Prompt (Lock)


You may ONLY use information contained between BEGIN_CONTEXT and END_CONTEXT.
You may NOT use prior knowledge, training data, or assumptions.
If the answer is not explicitly present, respond exactly with:
"Unable to answer with certainty."
Do not paraphrase beyond the meaning of the text.
Do not add new facts.
Do not infer or guess.


This prompt enforces refusal behavior and prevents model creativity.

---

## Request Format

### JSON Payload (Streaming Enabled)

```json
{
  "model": "qwen2.5-3b-instruct", // or "phi-3-mini-4k-instruct" depending on the user setting
  "stream": true,
  "temperature": 0.1,
  "messages": [
    {
      "role": "system",
      "content": "<system prompt>"
    },
    {
      "role": "user",
      "content": "BEGIN_CONTEXT\n<context text>\nEND_CONTEXT\n\nQUESTION: <question>"
    }
  ]
}
```

## Streaming Behavior (to be added in future implementation)

Uses Server-Sent Events (SSE)

Tokens are returned incrementally

Each chunk contains partial text

Stream ends with:

data: [DONE]


!! Streaming does not affect model output quality, only delivery. !!

## Decoding Parameters (Hallucination Control)

| Parameter        | Value        |
|------------------|--------------|
| Temperature      | 0.1–0.2      |
| Top-p            | 0.9          |
| Top-k            | 40           |
| Repeat penalty   | 1.1          |
| Max tokens       | 512–1024     |

### Rules
- Never raise temperature above **0.3**
- Limit max tokens to avoid speculative continuation

---

## Context Size & Chunking

If source material is large:

- Chunk context into **1–2k token segments**
- Ask questions **per chunk**
- Aggregate results **externally**

Rule:
- Never rely on the model to reason across truncated context

---

## Safety Guarantees

This setup ensures:

- No internet access
- No hidden data retrieval
- No training data leakage
- Deterministic, auditable output
- Explicit refusal on missing information

The model cannot answer beyond what is explicitly provided.

---

## Migration Readiness (If Future Production Server is Desired)

The current system is compatible with future deployment using:

- `llama.cpp` HTTP server
- Same GGUF models
- Same prompts and parameters
- Same API contract

LM Studio is used only as a **local development runtime**.

---

## Intended Use

Approved use cases:

- Medical document QA
- Regulatory text analysis
- API-fed knowledge summarization
- Offline, privacy-preserving AI systems

Not intended for:

- Diagnosis
- Treatment decisions
- Autonomous reasoning
- Internet-based retrieval

