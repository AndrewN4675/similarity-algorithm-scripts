# Similarity Scoring Algorithm Scripts

These scripts run the [pattern4](https://users.encs.concordia.ca/~nikolaos/pattern_detection.html) similarity-based design pattern detection algorithm across a corpus of Java projects and post-process the results into CSVs. Both Bash and PowerShell versions are provided and behave identically.

---

## Prerequisites

- **Java** (JDK 17 recommended) — required to run the similarity algorithm
- **pattern4.jar** — the similarity algorithm JAR (download [here](https://users.encs.concordia.ca/~nikolaos/pattern_detection.html))
- **Python 3** with `pandas` — required for `process_results.py`
- **unzip** (Bash only) — required by `extract_classes.sh`

---

## Configuration — `sa.config`

Before running any scripts, edit `sa.config` in the same folder as the scripts:

```
JAVA_BINARY='<path to java executable>'
JAVA_ARGS='-Xms32m -Xmx1024M'
SA_JAR='<path to pattern4.jar>'
SA_TIMEOUT=30m
SA_TIMEOUT_SIG=KILL
```

- `JAVA_BINARY` — absolute path to the `java` executable on your system
- `JAVA_ARGS` — JVM heap settings passed to every invocation
- `SA_JAR` — path to `pattern4.jar`; relative paths are resolved relative to the scripts directory
- `SA_TIMEOUT` — per-project time limit (set to `30 minutes` by default; set to empty to disable)
- `SA_TIMEOUT_SIG` — signal used to kill a timed-out process (`KILL` or `TERM`; Bash only)

---

## Scripts

**extract_classes** — Unpacks `.class` files from JAR archives. Takes a directory of per-project JAR files and extracts them into a matching per-project directory structure that the algorithm can consume.

**process_batch** — Runs the similarity algorithm across all projects. Takes the extracted classes directory and a results directory, then calls `run_similarity_algorithm` for each project sequentially. For each project, `run_similarity_algorithm` invokes pattern4 via Java and writes the results to a `PROJECT.xml` file. It also logs each project name to a `success`, `timeout`, or `failure` file depending on the outcome.

**run_similarity_algorithm** — Runs the similarity algorithm on a single project. Called internally by `process_batch`, but can also be invoked directly.

**process_results.py** — Post-processes the XML output for one project into a CSV. Parses the pattern4 XML to find all detected pattern instances, then produces a `PROJECT.csv` file with every class in the project mapped to its detected pattern (or `None` if not part of any pattern). Projects with no `.class` files produce an empty CSV and are logged to an `empty` file.

---

## How to run

Bash:

```bash
# Step 1 — extract .class files from JARs
./extract_classes.sh INPUT_JAR_DIR OUTPUT_CLASS_DIR

# Step 2 — run the similarity algorithm on all projects
./process_batch.sh OUTPUT_CLASS_DIR RESULTS_DIR

# Step 3 — post-process each project's XML into a CSV
for project in OUTPUT_CLASS_DIR/*/; do
    python process_results.py "$(basename "$project")" OUTPUT_CLASS_DIR RESULTS_DIR
done
```

or PowerShell:

```powershell
.\extract_classes.ps1 -InputJarDir INPUT_JAR_DIR -OutputClassDir OUTPUT_CLASS_DIR
.\process_batch.ps1 -InputDir OUTPUT_CLASS_DIR -ResultsDir RESULTS_DIR
# Run process_results.py per-project as above
```
