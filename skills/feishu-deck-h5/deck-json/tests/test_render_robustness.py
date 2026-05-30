import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


DECK_JSON = pathlib.Path(__file__).resolve().parents[1]
RENDER = DECK_JSON / "render-deck.py"
CSS = DECK_JSON.parents[0] / "assets" / "feishu-deck.css"


def _render(slides):
    deck = {
        "version": "1.0",
        "deck": {
            "title": "robustness fixtures",
            "language": "zh-only",
            "mode": "rewrite",
        },
        "slides": slides,
    }
    with tempfile.TemporaryDirectory() as td:
        deck_path = pathlib.Path(td) / "deck.json"
        out_dir = pathlib.Path(td) / "out"
        deck_path.write_text(json.dumps(deck, ensure_ascii=False), encoding="utf-8")
        proc = subprocess.run(
            [sys.executable, str(RENDER), str(deck_path), str(out_dir)],
            capture_output=True,
            text=True,
        )
        assert proc.returncode == 0, f"render failed:\n{proc.stdout}\n{proc.stderr}"
        return (out_dir / "index.html").read_text(encoding="utf-8")


class RenderRobustnessTests(unittest.TestCase):
    def test_section_title_and_lede_share_flow_container(self):
        html = _render([
            {
                "key": "long-section",
                "layout": "section",
                "data": {
                    "chapter_num": "06.",
                    "title": "这是一个足够长会换成两行的章节标题用于验证副标题避让",
                    "lede": "副标题不能压住两行标题",
                },
            }
        ])

        self.assertIn('<div class="section-copy">', html)
        self.assertLess(html.index("class=\"title title-zh\""), html.index("class=\"lede\""))
        css = CSS.read_text(encoding="utf-8")
        self.assertIn('.slide[data-layout="section"] .section-copy', css)

    def test_verdict_grid_does_not_reuse_layout_grid_class(self):
        html = _render([
            {
                "key": "verdict-blocks",
                "layout": "content",
                "variant": "blocks",
                "data": {
                    "title": "判断矩阵",
                    "lede": "嵌套 verdict-grid 不应被 content-2col .grid 误伤",
                    "body_blocks": [
                        {
                            "type": "verdict-grid",
                            "cards": [
                                {
                                    "verdict": "go",
                                    "badge": "GO",
                                    "title": "可做",
                                    "body": "条件满足",
                                },
                                {
                                    "verdict": "conditional",
                                    "badge": "WAIT",
                                    "title": "观察",
                                    "body": "需要补证据",
                                },
                            ],
                        }
                    ],
                },
            }
        ])

        self.assertIn('class="verdict-grid"', html)
        self.assertNotIn('<div class="grid" style="grid-template-columns:repeat(2, 1fr); gap: 24px">', html)

    def test_custom_end_slogan_replaces_default_slogan(self):
        html = _render([
            {
                "key": "custom-end",
                "layout": "end",
                "data": {
                    "slogan": "谢谢观看",
                },
            }
        ])

        self.assertIn("谢谢观看", html)
        self.assertIn('class="slogan"', html)
        self.assertNotIn("slogan-default", html)

    def test_default_end_slogan_still_renders_without_custom_slogan(self):
        html = _render([
            {
                "key": "default-end",
                "layout": "end",
                "data": {},
            }
        ])

        self.assertIn("slogan slogan-default", html)


if __name__ == "__main__":
    unittest.main()
