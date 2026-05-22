# Agent README

## Microbiome Response Interpreter Beta

This document summarizes how to use the **Microbiome Response Interpreter Beta** repository with three agent-style workflows:

1. OpenAI / ChatGPT skill-style workflow
2. Claude / Claude Code workflow
3. Gemini / Google AI Studio or Vertex AI workflow

The repository is a beta research-preview companion implementation for the associated microbiome response-geometry preprint. It is intended for exploratory inspection, demonstration, and reproducibility support only. It is **not** a clinical, diagnostic, predictive, efficacy, regulatory, production, or mechanistic tool.

---

## 1. Shared scope for all agents

All supported agents should treat the repository as a conservative response-geometry workflow. The intended tasks are:

- inspect microbiome input tables before analysis
- check whether a feature table, metadata table, and pairing map are compatible
- run documented response-geometry scripts when inputs are sufficient
- summarize paired response magnitude
- summarize directional coherence
- summarize pseudocount or zero-handling sensitivity where requested
- summarize sample-size or operating-context guidance as exploratory support
- produce cautious reader-facing interpretation text

All agents should preserve the claim boundaries in:

- `README.md`
- `SKILL.md`
- `KNOWN_LIMITATIONS.md`
- this `agent_README.md`

Agents should not use this repository to claim:

- clinical efficacy
- diagnosis
- prognosis
- prediction
- treatment effect
- pathway activity
- enzyme activity
- metabolic flux
- mechanism
- participant classification
- universal method superiority
- pseudocount invariance
- formal power calculation unless separately implemented and validated

---

## 2. Required input files

The public interface expects tabular files rather than direct `phyloseq` objects.

Required files:

```text
feature_table.tsv
metadata.tsv
pairing_map.tsv
```

Expected structure:

- `feature_table.tsv`: features by samples, with feature IDs in the first column and sample IDs as the remaining columns.
- `metadata.tsv`: one row per sample with sample ID, subject ID, group, and timepoint information.
- `pairing_map.tsv`: one row per paired comparison linking each subject's baseline and follow-up samples.

Do not pre-CLR-transform the feature table before using the bundled scripts. The workflow applies zero handling and CLR transformation internally.

Agents should report missing, inconsistent, duplicated, or incompatible fields rather than silently inventing metadata or pairings.

---

## 3. First execution check for any agent

Before applying the workflow to new user data, run the bundled toy example from the repository root.

Windows PowerShell / VS Code terminal users should use one-line commands because PowerShell does not use Unix backslash line continuations:

```powershell
mkdir -Force outputs/toy
Rscript scripts/check_inputs.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy
Rscript scripts/paired_response_geometry.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy --pseudocount 0.5 --samples_in_rows true
Rscript scripts/decision_flow_summary.R --group_geometry outputs/toy/group_geometry.tsv --outdir outputs/toy/decision_flow --endpoint_note "Toy before-after example"
```

Optional modules:

```powershell
Rscript scripts/pseudocount_sensitivity_check.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy/pseudocount --pseudocounts 0.5,1.0 --reference_pseudocount 0.5 --samples_in_rows true
Rscript scripts/coherence_power_guide.R --outdir outputs/toy/power --sample_sizes 8,12 --effect_sizes 0,0.8 --n_features 50 --n_reps 20 --n_perm 99 --seed 123
Rscript scripts/plot_summary.R --outdir outputs/toy
```

The toy feature table stores samples in rows. The explicit `--samples_in_rows true` flag avoids orientation auto-detection ambiguity in very small toy matrices.

Linux/macOS/WSL users may use shell continuations:

```bash
mkdir -p outputs/toy

Rscript scripts/check_inputs.R   --feature_table examples/toy_dataset/feature_table.tsv   --metadata examples/toy_dataset/metadata.tsv   --pairing_map examples/toy_dataset/pairing_map.tsv   --outdir outputs/toy

Rscript scripts/paired_response_geometry.R   --feature_table examples/toy_dataset/feature_table.tsv   --metadata examples/toy_dataset/metadata.tsv   --pairing_map examples/toy_dataset/pairing_map.tsv   --outdir outputs/toy   --pseudocount 0.5   --samples_in_rows true

Rscript scripts/decision_flow_summary.R   --group_geometry outputs/toy/group_geometry.tsv   --outdir outputs/toy/decision_flow   --endpoint_note "Toy before-after example"
```

Expected core outputs include:

```text
outputs/toy/group_geometry.tsv
outputs/toy/paired_vectors.tsv
outputs/toy/paired_response_geometry_summary.tsv
outputs/toy/decision_flow/decision_flow_summary.md
```

The toy dataset is artificial. Use it only to verify installation, input compatibility, and output shape.

---

## 4. OpenAI / ChatGPT skill-style workflow

### 4.1 Intended use

Use this path when the repository is packaged or loaded as an OpenAI / ChatGPT skill-style bundle.

The OpenAI-facing metadata is stored in:

```text
agents/openai.yaml
```

The main skill instructions are stored in:

```text
SKILL.md
```

The agent should read `SKILL.md` first, then consult specific references or scripts only when relevant to the task.

### 4.2 Recommended OpenAI agent prompt

```text
Use this repository as a beta research-preview companion workflow for microbiome response-geometry interpretation. First read SKILL.md, README.md, KNOWN_LIMITATIONS.md, and agent_README.md. Then run the five-minute toy vignette to verify the environment. After that, inspect my feature table, metadata, and pairing map for compatibility. If the inputs are sufficient, run the documented paired response-geometry workflow and summarize response magnitude, directional coherence, pseudocount sensitivity if requested, and claim boundaries. Keep the interpretation exploratory and do not make clinical, predictive, efficacy, diagnostic, regulatory, or mechanistic claims.
```

### 4.3 OpenAI-specific cautions

The agent should:

- use the documented script interface
- not invent new command-line arguments
- not infer missing pairings or metadata
- not expose raw datasets or local files
- not rewrite the claim boundaries as stronger claims
- report uncertainty and failed checks clearly

---

## 5. Claude / Claude Code workflow

### 5.1 Intended use

Use this path when running the repository through Claude Code or another Claude environment that supports project files and instruction references.

Claude-specific subagent instructions are stored in:

```text
agents/claude.md
```

Claude Code can use this file as a specialized instruction reference for backend geometry summaries.

### 5.2 Claude Code recommended mode

Claude Code is the preferred Claude environment for this repository because it can work with local files and execute stepwise project tasks.

Recommended setup:

```bash
# Copy the repository or skill folder into a working project directory
cp -r microbiome-response-interpreter-beta/ /path/to/workspace/
```

Then ask Claude Code to read the key files:

```text
Read SKILL.md, README.md, KNOWN_LIMITATIONS.md, agent_README.md, and agents/claude.md. Then run the five-minute toy vignette. If the toy run succeeds, audit my feature_table.tsv, metadata.tsv, and pairing_map.tsv for compatibility and run the documented response-geometry workflow.
```

### 5.3 Claude.ai sequential mode

Claude.ai may not support true parallel subagents in all contexts. In that setting, use `agents/claude.md` as a sequential instruction reference rather than as a parallel worker.

Recommended manual trigger:

```text
Use the Microbiome Response Interpreter Beta instructions. Read agents/claude.md as a sequential task guide, audit the microbiome table inputs, choose the safest documented workflow, and report response-geometry results with conservative claim boundaries.
```

### 5.4 Claude-specific cautions

The agent should:

- treat `agents/claude.md` as a scoped instruction file
- run tasks sequentially when parallel subagents are unavailable
- skip quantitative benchmarking if required dependencies or inputs are unavailable
- keep interpretation exploratory
- report missing inputs rather than filling them by assumption

---

## 6. Gemini / Google AI Studio or Vertex AI workflow

### 6.1 Intended use

Use this path when integrating the repository with Gemini through Google AI Studio, Vertex AI, or a custom Python wrapper using Gemini function calling.

Gemini integration is model-agnostic. It should wrap the documented backend scripts or a local pipeline function rather than bypassing the repository workflow.

A Gemini setup may use a configuration file such as:

```text
integrations/gemini.yaml
```

If this file is not present, create it as a local integration file and avoid committing API keys.

### 6.2 Prerequisites

Install the Google Generative AI SDK and YAML support:

```bash
pip install google-generativeai pyyaml
```

Obtain a Gemini API key through Google AI Studio or configure credentials through Vertex AI.

Do not store API keys in the repository. Use environment variables, secret managers, or local configuration outside version control.

### 6.3 Lightweight Gemini function-calling example

The following example illustrates the pattern. It is not a replacement for the documented R scripts.

```python
import os
import subprocess
import yaml
import google.generativeai as genai

with open("integrations/gemini.yaml", "r", encoding="utf-8") as file:
    config = yaml.safe_load(file)["agent_config"]

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

def run_response_geometry(feature_table: str, metadata: str, pairing_map: str, outdir: str) -> dict:
    """Run the documented paired response-geometry workflow."""
    cmd = [
        "Rscript", "scripts/paired_response_geometry.R",
        "--feature_table", feature_table,
        "--metadata", metadata,
        "--pairing_map", pairing_map,
        "--outdir", outdir,
        "--pseudocount", "0.5",
    ]
    completed = subprocess.run(cmd, check=False, capture_output=True, text=True)
    return {
        "status": "success" if completed.returncode == 0 else "failed",
        "returncode": completed.returncode,
        "stdout": completed.stdout[-4000:],
        "stderr": completed.stderr[-4000:],
        "expected_group_geometry": f"{outdir}/group_geometry.tsv",
    }

model = genai.GenerativeModel(
    model_name=config.get("model_name", "gemini-1.5-pro"),
    system_instruction=config["system_instruction"],
    tools=[run_response_geometry],
    generation_config=genai.GenerationConfig(
        temperature=config.get("temperature", 0.2)
    ),
)

response = model.generate_content(
    "Audit my standardized microbiome response-geometry inputs and run the documented backend summary if the inputs are compatible."
)

print(response.text)
```

### 6.4 Recommended Gemini system instruction

```text
You are using the Microbiome Response Interpreter Beta as a research-preview companion workflow. Follow README.md, SKILL.md, KNOWN_LIMITATIONS.md, and agent_README.md. Use only documented script interfaces. Verify input compatibility before running response-geometry summaries. Keep all interpretations exploratory. Do not make clinical, diagnostic, predictive, efficacy, regulatory, or mechanistic claims. Report missing inputs, execution failures, or metadata incompatibilities rather than filling gaps by assumption.
```

### 6.5 Gemini-specific cautions

The agent should:

- never commit or print API keys
- use environment variables for credentials
- wrap documented scripts rather than inventing a separate mathematical implementation
- report tool execution errors clearly
- avoid returning invented numerical results if script execution fails

---

## 7. Cross-agent output template

Agents may use this output structure after a successful run.

```markdown
# Response-Geometry Summary

## Input audit
- Feature table:
- Metadata:
- Pairing map:
- Pairing consistency:
- Missingness or warnings:

## Analysis settings
- Feature space:
- Endpoint:
- Pseudocount:
- CLR / Aitchison representation:
- Directional-coherence convention:
- Permutation or sensitivity settings:

## Main outputs
- Response magnitude summary:
- Directional coherence summary:
- Observed-minus-null context:
- Bootstrap / leave-one-out support if available:
- Pseudocount sensitivity if available:

## Conservative interpretation
- What the result supports:
- What the result does not support:
- Key limitations:
- Recommended follow-up checks:
```

Agents should adapt the fields to the available outputs and should not invent unavailable statistics.

---

## 8. Recommended repository placement

Keep this file at the repository root:

```text
agent_README.md
```

Suggested relevant repository files:

```text
README.md
SKILL.md
KNOWN_LIMITATIONS.md
agent_README.md
agents/openai.yaml
agents/claude.md
integrations/gemini.yaml
tutorials/five-minute-toy-vignette.md
examples/toy_dataset/
scripts/
references/
env/
```

If `integrations/gemini.yaml` is added, keep it free of credentials.

---

## 9. Release wording

Suggested public-facing description:

```text
Beta research-preview companion implementation for interpreting microbiome response magnitude and directional coherence across agent-assisted workflows.
```

Suggested short disclaimer:

```text
This repository supports exploratory response-geometry inspection only. It is not a clinical, diagnostic, predictive, efficacy, regulatory, production, or mechanistic tool.
```

---

## 10. Final checklist before public release

```text
[ ] README.md includes beta research-preview notice.
[ ] SKILL.md preserves conservative trigger and interpretation boundaries.
[ ] KNOWN_LIMITATIONS.md is present and aligned with README.md.
[ ] agents/openai.yaml contains no secrets or private paths.
[ ] agents/claude.md contains no secrets or private paths.
[ ] integrations/gemini.yaml, if present, contains no API keys.
[ ] No raw sequencing data are bundled.
[ ] No manuscript drafts, reviewer notes, or presubmission letters are bundled.
[ ] No local absolute paths are present.
[ ] Toy vignette runs successfully.
[ ] README commands match actual script arguments.
[ ] CITATION.cff has authors, version, repository URL, license, and manuscript metadata.
[ ] LICENSE is present and intended for release.
```
