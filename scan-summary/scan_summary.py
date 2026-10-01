#!/usr/bin/env python3
"""Summarise a container image vulnerability scan report.

    pip install cvss
    python3 scan_summary.py examples/example-report.json
"""

import argparse
import json
from collections import Counter

from cvss import CVSS3
from cvss.exceptions import CVSSError

DEADLINES = {"P1": "1-4 hours", "P2": "24 hours", "P3": "24 - 72 hours", "P4": " < 7 days"}
TIERS = list(DEADLINES)


def cvss_score(vector):
    """CVSS v3.1 base score, or None if the vector is missing, v2 or broken."""
    try:
        return float(CVSS3(vector).base_score)
    except (CVSSError, TypeError, AttributeError):
        return None


def load(path):
    with open(path) as fh:
        report = json.load(fh)
    findings = [{
        "id": v.get("id") or "unknown",
        "package": v.get("package") or "unknown",
        "version": v.get("version") or "?",
        "severity": (v.get("severity") or "UNKNOWN").upper(),
        "fix": v.get("fix_version") or None,
        "cvss": cvss_score(v.get("vector")),
    } for v in report.get("vulnerabilities") or []]
    return report.get("image", path), findings


def enrich(findings):
    """Add outside data here later, e.g. f["epss"] from FIRST or f["kev"] from CISA.
    priority() already uses both fields when they're set."""


def priority(f, internet_facing):
    """My CVSS policy: start from the score, KEV goes straight to P1,
    and context can move a finding up one tier at most."""
    if f.get("kev"):
        return "P1", "on CISA KEV"
    if f["cvss"] is None:
        return "P2", "no usable CVSS v3 vector, unscored until someone reviews it"

    score = f["cvss"]
    start = "P1" if score >= 9 else "P2" if score >= 7 else "P3" if score >= 4 else "P4"
    reasons = []
    if (f.get("epss") or 0) >= 0.1:
        reasons.append(f"EPSS {f['epss']}")
    if internet_facing:
        reasons.append("internet-facing")

    tier = TIERS[max(TIERS.index(start) - 1, 0)] if reasons else start
    why = f"CVSS {score}"
    if tier != start:
        why += f", up from {start}: {', '.join(reasons)}"
    return tier, why


def main():
    parser = argparse.ArgumentParser(description="Summarise a container image scan report.")
    parser.add_argument("report")
    parser.add_argument("--internet-facing", action="store_true")
    args = parser.parse_args()

    image, findings = load(args.report)
    enrich(findings)
    for f in findings:
        f["priority"], f["why"] = priority(f, args.internet_facing)

    print(f"Security summary for {image}: {len(findings)} findings\n")

    print("Findings by severity")
    counts = Counter(f["severity"] for f in findings)
    for severity in ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]:
        if counts[severity]:
            print(f"  {severity:<9} {counts[severity]}")

    print("\nCan be fixed now")
    fixable = [f for f in findings if f["fix"]]
    for f in sorted(fixable, key=lambda f: f["priority"]):
        print(f"  {f['package']} {f['version']} -> {f['fix']}  ({f['id']})")
    if not fixable:
        print("  nothing has a fix yet")

    print("\nPriority")
    for f in sorted(findings, key=lambda f: (f["priority"], -(f["cvss"] or 0))):
        print(f"  {f['priority']}  fix within {DEADLINES[f['priority']]}  {f['id']}  {f['package']}")
        print(f"      {f['why']}; {'fix: ' + f['fix'] if f['fix'] else 'no fix yet, track it'}")


if __name__ == "__main__":
    main()
