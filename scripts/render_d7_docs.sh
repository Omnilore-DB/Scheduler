#!/usr/bin/env bash
# Render every Project_Docs_D7/*.md to a polished .docx (via Pandoc) and then
# convert the .docx to .pdf (via LibreOffice headless), so the PDF reflects
# the same Word formatting. Markdown remains the source of truth.
#
# Pandoc 2.9 with `-f gfm -t docx` does not emit <w:tblGrid> on tables;
# LibreOffice then renders them with only the first column visible. We patch
# the DOCX in-place after generation to inject equal-width column grids.
#
# Requires: pandoc, libreoffice, python3.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${REPO_ROOT}/Project_Docs_D7"
PATCH_PY="${REPO_ROOT}/scripts/render_d7_docs_patch.py"

cd "$SRC_DIR"

docs=(
  README_QuickStart
  System_Overview_and_Architecture
  Setup_and_Deployment_Guide
  Operations_Runbook
  API_and_Data_Reference
  Testing_and_QA_Summary
  Security_Privacy_Accessibility_UX_Notes
  Backlog_Known_Issues_Roadmap
  ChangeLog_and_Version_History
  Demo_Video_Script_and_Checklist
  Handoff_Checklist_and_Verification_Log
  Handoff_Package_Manifest
  Stakeholder_Email_Cover_Note
)

echo "MD -> DOCX (pandoc -f gfm -t docx):"
for base in "${docs[@]}"; do
  echo "  $base"
  pandoc "$base.md" \
    --from gfm \
    --to docx \
    --resource-path . \
    --output "$base.docx"
done

echo
echo "Patching tables (inject <w:tblGrid>):"
docx_args=()
for base in "${docs[@]}"; do
  docx_args+=("$SRC_DIR/$base.docx")
done
python3 "$PATCH_PY" "${docx_args[@]}"

echo
echo "DOCX -> PDF (soffice --headless --convert-to pdf):"
soffice --headless --convert-to pdf --outdir "$SRC_DIR" "${docx_args[@]}" >/dev/null

echo
echo "Done. Project_Docs_D7 contents:"
ls -1 "$SRC_DIR" | grep -E '\.(md|docx|pdf)$' | sort
