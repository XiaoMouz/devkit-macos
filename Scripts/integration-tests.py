#!/usr/bin/env python3
"""Exercise the packaged worker against local fixtures; no public network service."""
import base64
import hashlib
import http.server
import json
from pathlib import Path
import socket
import socketserver
import struct
import subprocess
import sys
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKER = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'build/Build/Products/Debug/DevKit.app/Contents/Helpers/DevKitWorker'
sys.argv = sys.argv[:1]

def payload(tool, text='', options=None, secondary='', file=None):
    value = {'text': text, 'secondary': secondary}
    if file is not None: value.update(file=base64.b64encode(file).decode(), fileName='fixture.bin')
    return json.dumps({'id': tool, 'input': value, 'options': base64.b64encode(json.dumps(options or {}).encode()).decode()}).encode()

def run(tool, text='', options=None, secondary='', file=None):
    p = subprocess.run([str(WORKER)], input=payload(tool,text,options,secondary,file), capture_output=True, timeout=28)
    if p.returncode: raise AssertionError(f'{tool} worker exited {p.returncode}')
    return json.loads(p.stdout)

class HTTPHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    def log_message(self, *_): pass
    def do_GET(self):
        body = b'x' * (5 * 1024 * 1024 + 1) if self.path == '/large' else b'{"hello":"DevKit"}'
        self.send_response(200); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(body))); self.end_headers()
        try: self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError): pass
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get('Content-Length','0')))
        self.send_response(201); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)

class WebSocketHandler(socketserver.BaseRequestHandler):
    def handle(self):
        data=b''
        while b'\r\n\r\n' not in data: data+=self.request.recv(1024)
        headers=dict(line.split(': ',1) for line in data.decode().split('\r\n')[1:] if ': ' in line)
        key=next(v for k,v in headers.items() if k.lower()=='sec-websocket-key')
        accept=base64.b64encode(hashlib.sha1((key+'258EAFA5-E914-47DA-95CA-C5AB0DC85B11').encode()).digest()).decode()
        self.request.sendall(('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: '+accept+'\r\n\r\n').encode())
        def read(n):
            value=b''
            while len(value)<n:
                b=self.request.recv(n-len(value))
                if not b: raise EOFError()
                value+=b
            return value
        try:
            while True:
                op, size=read(2); masked=size&128; size &=127
                if size==126: size=struct.unpack('!H',read(2))[0]
                elif size==127: size=struct.unpack('!Q',read(8))[0]
                mask=read(4) if masked else None; message=read(size)
                if mask: message=bytes(b^mask[i%4] for i,b in enumerate(message))
                opcode=op&15
                if opcode==8: break
                opcode=10 if opcode==9 else opcode
                header=bytes([128|opcode,len(message)]) if len(message)<126 else bytes([128|opcode,126])+struct.pack('!H',len(message))
                self.request.sendall(header+message)
        except (EOFError, ConnectionResetError, BrokenPipeError): pass

class WorkerIntegration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.http=http.server.ThreadingHTTPServer(('127.0.0.1',0),HTTPHandler)
        cls.ws=socketserver.ThreadingTCPServer(('127.0.0.1',0),WebSocketHandler); cls.ws.daemon_threads=True
        for server in [cls.http, cls.ws]: threading.Thread(target=server.serve_forever,daemon=True).start()
    @classmethod
    def tearDownClass(cls):
        for server in [cls.http,cls.ws]: server.shutdown(); server.server_close()
    def test_http_get(self):
        result=run('http-client',f'http://127.0.0.1:{self.http.server_port}/',{'method':'GET','headers':'{}'})
        self.assertEqual(result['output']['text'],'{"hello":"DevKit"}')
        self.assertTrue(result['output']['rows'][0]['value'].startswith('200'))
        self.assertEqual(result['output']['artifacts'][0]['name'], 'response.json')
        self.assertEqual(base64.b64decode(result['output']['artifacts'][0]['data']), b'{"hello":"DevKit"}')
    def test_http_post_preserves_newline(self):
        result=run('http-client',f'http://127.0.0.1:{self.http.server_port}/',{'method':'POST','headers':'{"Content-Type":"text/plain"}'},'hello\n')
        self.assertEqual(result['output']['text'],'hello\n')
    def test_http_body_limit(self):
        result=run('http-client',f'http://127.0.0.1:{self.http.server_port}/large',{'method':'GET','headers':'{}'})
        self.assertIn('5 MiB',result['error']['message'])
    def test_websocket_echo(self):
        result=run('websocket',f'ws://127.0.0.1:{self.ws.server_address[1]}/',{'message':'hello 你好\n','count':1})
        self.assertEqual(result['output']['text'],'hello 你好\n')
    def test_dns_with_local_resolver(self):
        udp=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);udp.bind(('127.0.0.1',0));udp.settimeout(10)
        port=udp.getsockname()[1]
        def answer():
            try:
                query,address=udp.recvfrom(4096)
                n=12
                while query[n]: n+=query[n]+1
                n+=5
                header=query[:2]+bytes.fromhex('81800001000100000000')
                record=bytes.fromhex('c00c000100010000003c0004')+socket.inet_aton('192.0.2.42')
                udp.sendto(header+query[12:n]+record,address)
            finally: udp.close()
        threading.Thread(target=answer,daemon=True).start()
        result=run('dns','fixture.test',{'record':'A','resolver':'127.0.0.1','port':port})
        self.assertIn('192.0.2.42',result['output']['text'])
    def test_worker_bounds_pathological_regex(self):
        request=payload('regex','a'*40000+'!',{'pattern':'^(a+)+$','flags':'','operation':'match','replacement':''})
        start=time.monotonic();p=subprocess.Popen([str(WORKER)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        output,_=p.communicate(request,timeout=28)
        if p.returncode == 0:
            response=json.loads(output)
            self.assertTrue('error' in response or response.get('output',{}).get('text') == '[]')  # Optimized engines can finish normally; otherwise enforce the deadline.
        self.assertLess(time.monotonic()-start,27)
    def test_worker_kill_cancels_synchronous_work(self):
        p=subprocess.Popen([str(WORKER)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        p.stdin.write(payload('regex','a'*40000+'!',{'pattern':'^(a+)+$','flags':'','operation':'match','replacement':''}));p.stdin.close()
        time.sleep(.02);self.assertIsNone(p.poll());start=time.monotonic();p.kill();p.wait(timeout=2)
        p.stdout.close();p.stderr.close()
        self.assertLess(time.monotonic()-start,2)
    def test_json_workspace_operations(self):
        value = '{"users":[{"name":"Ada"}],"version":1}'
        for operation in ['format', 'minify', 'validate', 'tree', 'query', 'diff', 'schema', 'typescript']:
            options = {'operation': operation, 'syntax': 'jsonpath', 'path': '$.users[0].name', 'name': 'UserData'}
            secondary = '{"type":"object"}' if operation == 'schema' else '{"version":2}'
            with self.subTest(operation=operation):
                result = run('json', value, options, secondary=secondary)
                self.assertIn('output', result)
                self.assertTrue(result['output']['text'])
                if operation == 'typescript': self.assertIn('export type UserData', result['output']['text'])
    def test_qr_generation_and_image_scan(self):
        text = 'https://example.test/?q=二维码'
        options = {'operation': 'generate', 'correction': 'H', 'scale': 10}
        generated = run('qr-code', text, options)['output']['artifacts'][0]
        options['operation'] = 'scan'
        scanned = run('qr-code', options=options, file=base64.b64decode(generated['data']))
        self.assertEqual(scanned['output']['text'], text)
    def test_image_data_url_round_trip(self):
        # A standalone 1x1 RGBA PNG keeps this test independent of app artwork.
        original = base64.b64decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMwbnjWAAAEnQIa/Oqd7wAAAABJRU5ErkJggg==')
        encoded = run('data-url', options={'operation': 'encode'}, file=original)['output']['text']
        self.assertTrue(encoded.startswith('data:image/png;base64,'))
        decoded = run('data-url', encoded, {'operation': 'decode'})['output']['artifacts'][0]
        self.assertEqual(decoded['mime'], 'image/png')
        self.assertEqual(decoded['name'], 'image.png')
        self.assertEqual(base64.b64decode(decoded['data']), original)
        self.assertIn('error', run('data-url', 'hello', {'operation': 'encode'}))
        self.assertIn('error', run('data-url', 'data:text/plain;base64,aGVsbG8=', {'operation': 'decode'}))
    def test_removed_tools_are_not_executable(self):
        for tool in ['compression', 'hex-text', 'html-entities', 'string-escape', 'unicode-escape',
                     'csv', 'toml', 'xml', 'yaml', 'basic-auth', 'format-convert', 'bitwise',
                     'lorem-ipsum', 'slug', 'user-agent', 'border-radius', 'box-shadow',
                     'css-gradient', 'cubic-bezier', 'flex-grid']:
            with self.subTest(tool=tool):
                self.assertEqual(run(tool)['error']['message'], '工具不存在。')
    def test_unknown_tool_is_structured_error(self):
        self.assertIn('error',run('nonexistent'))

if __name__=='__main__': unittest.main(verbosity=2)
