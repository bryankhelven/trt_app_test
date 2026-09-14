"""Serve a built Web app on localhost:8878 with storage isolation headers."""
import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory='build/web',**kwargs)
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy','same-origin')
        self.send_header('Cross-Origin-Embedder-Policy','require-corp')
        self.send_header('Cache-Control','no-cache')
        super().end_headers()
parser=argparse.ArgumentParser()
parser.add_argument('--port',type=int,default=8878)
args=parser.parse_args()
ThreadingHTTPServer(('127.0.0.1',args.port),Handler).serve_forever()
