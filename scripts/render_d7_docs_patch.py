"""Inject <w:tblGrid> into any pandoc-gfm DOCX table that lacks one.

Pandoc 2.9 with `-f gfm` does not emit <w:tblGrid>. LibreOffice then
falls back to a single-column layout when rendering. We patch the
DOCX in-place: for every <w:tbl>, count cells in the first <w:tr>,
then emit equal-width <w:gridCol> entries summing to the page content
width (US Letter, 1" margins => 9360 DXA).
"""
from __future__ import annotations
import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

CONTENT_WIDTH_DXA = 9360

TBL_RE = re.compile(r"<w:tbl>.*?</w:tbl>", re.DOTALL)
TR_RE = re.compile(r"<w:tr[ >].*?</w:tr>", re.DOTALL)
TC_RE = re.compile(r"<w:tc[ >]")
TBLPR_RE = re.compile(r"</w:tblPr>")


def patch_table(table_xml: str) -> str:
    if "<w:tblGrid>" in table_xml:
        return table_xml
    first_row = TR_RE.search(table_xml)
    if not first_row:
        return table_xml
    cells = TC_RE.findall(first_row.group(0))
    n = len(cells)
    if n == 0:
        return table_xml
    col_w = CONTENT_WIDTH_DXA // n
    grid = "<w:tblGrid>" + ("<w:gridCol w:w=\"%d\"/>" % col_w) * n + "</w:tblGrid>"
    # Insert immediately after </w:tblPr>; pandoc always emits one.
    if TBLPR_RE.search(table_xml):
        return TBLPR_RE.sub("</w:tblPr>" + grid, table_xml, count=1)
    # Fallback: insert right after <w:tbl>
    return table_xml.replace("<w:tbl>", "<w:tbl>" + grid, 1)


def patch_document_xml(xml: str) -> tuple[str, int]:
    patched = 0

    def _sub(m):
        nonlocal patched
        new = patch_table(m.group(0))
        if new != m.group(0):
            patched += 1
        return new

    out = TBL_RE.sub(_sub, xml)
    return out, patched


def patch_docx(path: Path) -> int:
    tmp_dir = Path(tempfile.mkdtemp(prefix="docxpatch_"))
    try:
        with zipfile.ZipFile(path) as z:
            z.extractall(tmp_dir)
        doc_xml_path = tmp_dir / "word" / "document.xml"
        xml = doc_xml_path.read_text(encoding="utf-8")
        new_xml, patched = patch_document_xml(xml)
        if patched == 0:
            return 0
        doc_xml_path.write_text(new_xml, encoding="utf-8")
        out = path.with_suffix(".patched.docx")
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            for f in tmp_dir.rglob("*"):
                if f.is_file():
                    z.write(f, f.relative_to(tmp_dir))
        shutil.move(out, path)
        return patched
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main(argv):
    total = 0
    for arg in argv:
        n = patch_docx(Path(arg))
        print(f"  {arg}: patched {n} tables")
        total += n
    print(f"Total tables patched: {total}")


if __name__ == "__main__":
    main(sys.argv[1:])
