"""Compatibility entrypoint: current product acceptance lives in web_revision3."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('web_revision3.py')),run_name='__main__')
