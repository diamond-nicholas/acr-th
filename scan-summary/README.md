# scan-summary

Reads a container image scan report and prints a security summary: findings by severity, what can be fixed now, and a P1 to P4 priority for each finding.

```
pip install cvss
python3 scan_summary.py examples/example-report.json
python3 scan_summary.py examples/example-report.json --internet-facing
```

The report only has the CVSS vector, so the score comes from the `cvss` library. Priority follows my CVSS approach: start from the score, anything on CISA KEV is P1, and a high EPSS or an internet-facing service moves it up one tier. No fix means it's tracked, not dropped. No usable vector means it's unscored and sits at P2 until someone looks at it.

EPSS and KEV aren't in the report, so there's an `enrich()` function to plug them in. `priority()` already uses them.

`examples/edge-cases.json` has a v2 vector, a broken vector, a missing fix and a missing severity.
