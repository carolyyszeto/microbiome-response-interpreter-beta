# Input Data Structure

Use this reference when a user asks what files the skill expects, whether `phyloseq` is supported, or how to prepare a dataset for paired response-geometry analysis.

## Preferred geometry-ready bundle

A minimal paired bundle contains three tabular files.

1. `feature_table.tsv`
   - Rows are samples and columns are microbial features.
   - First column should be `sample_id`.
   - Values should be non-negative counts or count-like abundances.
   - Do not CLR-transform before passing to scripts that perform CLR internally.
   - Avoid percentages that have already been rounded to a small number of decimals.

2. `metadata.tsv`
   - Must include `sample_id`.
   - For paired analysis, include `subject_id`, `timepoint`, and optionally `group`.
   - Timepoint labels should be clean, for example `Before` and `After`.
   - Keep one row per sample.

3. `pairing_map.tsv`
   - Preferred for paired response analysis because it removes ambiguity.
   - Required columns: `subject_id`, `before_sample_id`, `after_sample_id`.
   - Recommended column: `group`.

## Supported file forms

The scripts support matrix-style TSV/CSV tables and some RDS matrices or distance objects. The most reliable public-facing format is TSV.

## `phyloseq` support

The current package does not directly accept a `phyloseq` object as the main public interface. Export a feature table and sample metadata first.

Recommended R pattern:

```r
feature_table <- as.data.frame(t(as(otu_table(ps), "matrix")))
feature_table <- cbind(sample_id = rownames(feature_table), feature_table)
metadata <- as.data.frame(sample_data(ps))
metadata <- cbind(sample_id = rownames(metadata), metadata)
write.table(feature_table, "feature_table.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
write.table(metadata, "metadata.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
```

Check orientation after export. The feature table should have samples in rows and features in columns.

## Transformation expectations

- Let the skill scripts add the pseudocount and perform CLR transformation when raw count-like data are provided.
- Use the same feature filter across endpoints when trajectories are compared directly.
- Record prevalence filters, endpoint rules, pseudocount values, and sample inclusion rules in the run notes.

## Minimum metadata for stronger interpretation

- Paired response geometry requires linked before/after samples.
- Group comparison requires a group or arm label.
- Endpoint-caveated functional-context analyses should report endpoint definitions separately for each feature space.
