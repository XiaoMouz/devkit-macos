#!/usr/bin/env python3
"""Exercise the packaged worker against local fixtures; no public network service."""
import argparse
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
import tempfile
import unittest

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path, help='DevKit.app produced by Xcode Run or Archive')
args = parser.parse_args()
WORKER = args.app / 'Contents/Helpers/DevKitWorker'
CLI = args.app / 'Contents/Helpers/devkit'
if not WORKER.is_file():
    parser.error('所选 App 中没有 DevKitWorker，请传入 Xcode 构建出的 DevKit.app。')
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

class CLIIntegration(unittest.TestCase):
    def cli(self, *arguments, input=b'', executable=CLI):
        return subprocess.run([str(executable), *arguments], input=input, capture_output=True, timeout=28)

    def test_discovery_and_conditional_description(self):
        result = self.cli('list', '--format', 'json')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(json.loads(result.stdout)['tools']), 48)
        description = json.loads(self.cli('describe', 'json', '--option', 'operation=schema', '--format', 'json').stdout)['tool']
        self.assertEqual(description['inputStyle'], 'pair')
        self.assertFalse(description['network'])

    def test_human_output_is_default(self):
        listing = self.cli('list')
        self.assertEqual(listing.returncode, 0, listing.stderr)
        text = listing.stdout.decode()
        self.assertIn('编码与转换', text)
        self.assertIn('base64', text)
        self.assertNotIn('"protocolVersion"', text)
        detail = self.cli('describe', 'base64').stdout.decode()
        self.assertIn('operation', detail)
        self.assertIn('decode', detail)
        result = self.cli('run', 'base64', '--text', 'hello')
        self.assertEqual(result.stdout, b'aGVsbG8=\n')
        error = self.cli('run', 'unknown')
        self.assertEqual(error.returncode, 2)
        self.assertEqual(error.stdout, b'')
        self.assertTrue(error.stderr.decode().startswith('错误：'))

    def test_pipe_and_structured_request(self):
        original = '  你好\n"$HOME"\\\n'.encode()
        result = self.cli('run', 'base64', '--format', 'text', input=original)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, base64.b64encode(original))
        request = {'id': 'base64', 'input': {'text': result.stdout.decode()}, 'options': {'operation': 'decode'}}
        decoded = self.cli('run', '--request', '-', '--format', 'text', input=json.dumps(request).encode())
        self.assertEqual(decoded.stdout, original)

    def test_json_resources_from_symlink(self):
        with tempfile.TemporaryDirectory(prefix='devkit cli ') as folder:
            link = Path(folder) / 'devkit'
            link.symlink_to(CLI.resolve())
            result = self.cli('run', 'json', '--option', 'operation=minify', '--format', 'text',
                              input=b'{ "hello": "DevKit" }', executable=link)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, b'{"hello":"DevKit"}')

    def test_file_options_and_secondary_input(self):
        with tempfile.TemporaryDirectory() as folder:
            folder = Path(folder)
            (folder / 'a.json').write_text('{"value": 1}')
            (folder / 'schema.json').write_text('{"type":"array"}')
            (folder / 'options.json').write_text('{"operation":"schema"}')
            result = self.cli('run', 'json', '--input-file', str(folder / 'a.json'),
                              '--secondary-file', str(folder / 'schema.json'),
                              '--options-file', str(folder / 'options.json'), '--format', 'json')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout)['output']['report']['state'], 'failure')

    def test_binary_file_and_attachment(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / 'fixture.bin'
            file.write_bytes(bytes(range(256)))
            result = self.cli('run', 'file-checksum', '--file', str(file), '--format', 'text')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.decode(), hashlib.sha256(file.read_bytes()).hexdigest())
        qr = self.cli('run', 'qr-code', '--text', 'DevKit CLI', '--format', 'json')
        self.assertEqual(qr.returncode, 0, qr.stderr)
        artifact = json.loads(qr.stdout)['output']['artifacts'][0]
        self.assertTrue(base64.b64decode(artifact['data']).startswith(b'\x89PNG\r\n\x1a\n'))

    def test_errors_only_write_stderr(self):
        for arguments, status in [
            (['run', 'base64', '--option', 'padding=yes'], 2),
            (['run', 'base64', '--option', 'operation=decode', '--text', '$'], 1),
            (['run', 'http-client', '--text', 'http://127.0.0.1:1'], 2),
        ]:
            result = self.cli(*arguments, '--format', 'json')
            self.assertEqual(result.returncode, status)
            self.assertEqual(result.stdout, b'')
            self.assertIn('error', json.loads(result.stderr))

    def test_explicit_local_network_request(self):
        server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), HTTPHandler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            result = self.cli('run', 'http-client', '--text', f'http://127.0.0.1:{server.server_port}/',
                              '--allow-network', '--format', 'json')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout)['output']['text'], '{"hello":"DevKit"}')
        finally:
            server.shutdown(); server.server_close()

    def test_cli_timeout_is_structured(self):
        request = {'id': 'regex', 'input': {'text': 'a' * 40000 + '!'},
                   'options': {'pattern': '^(a+)+$', 'flags': '', 'operation': 'match'}}
        result = self.cli('run', '--request', '-', '--format', 'json', input=json.dumps(request).encode())
        if result.returncode == 0:
            self.assertEqual(json.loads(result.stdout)['output']['text'], '[]')
        else:
            self.assertEqual(result.returncode, 124, result.stderr)
            self.assertEqual(json.loads(result.stderr)['error']['code'], 'timeout')

    def test_cli_cancel_terminates_worker_connection(self):
        connected, disconnected = threading.Event(), threading.Event()
        class WaitingHandler(socketserver.BaseRequestHandler):
            def handle(self):
                self.request.settimeout(5)
                headers = b''
                while b'\r\n\r\n' not in headers:
                    headers += self.request.recv(1024)
                self.request.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\n')
                connected.set()
                try:
                    if self.request.recv(1) == b'': disconnected.set()
                except ConnectionResetError:
                    disconnected.set()
        server = socketserver.ThreadingTCPServer(('127.0.0.1', 0), WaitingHandler)
        server.daemon_threads = True
        threading.Thread(target=server.serve_forever, daemon=True).start()
        process = subprocess.Popen([str(CLI), 'run', 'http-client', '--text',
                                    f'http://127.0.0.1:{server.server_address[1]}/', '--allow-network'],
                                   stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            self.assertTrue(connected.wait(5))
            process.terminate()
            process.communicate(timeout=3)
            self.assertEqual(process.returncode, 143)
            self.assertTrue(disconnected.wait(2), 'worker connection survived CLI cancellation')
        finally:
            if process.poll() is None: process.kill(); process.communicate()
            server.shutdown(); server.server_close()

if __name__=='__main__': unittest.main(verbosity=2)
