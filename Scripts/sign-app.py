#!/usr/bin/env python3
"""Sign DevKit with a real developer identity when available; label previews honestly."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def identities(output):
    candidates = []
    for fingerprint, name in re.findall(r'^\s*\d+\)\s+([A-Fa-f0-9]{40})\s+"([^"]+)"', output, re.M):
        if name.startswith(('Apple Development:', 'Mac Developer:', 'Developer ID Application:')):
            candidates.append((fingerprint, name))
    return candidates


def choose_identity(candidates, requested=None, required=False):
    if requested == '-':
        if required:
            raise ValueError('Spotlight 构建不能使用临时签名，请配置 Apple 开发证书。')
        return '-'
    if requested:
        matches = [fingerprint for fingerprint, name in candidates
                   if fingerprint.lower() == requested.lower() or name == requested]
        if len(matches) != 1:
            raise ValueError('指定的 DEVKIT_SIGNING_IDENTITY 不是唯一可用的 Apple 开发签名，请用 security find-identity -v -p codesigning 检查。')
        return matches[0]
    if len(candidates) == 1:
        return candidates[0][0]
    if len(candidates) > 1:
        raise ValueError('存在多个开发签名，请用 DEVKIT_SIGNING_IDENTITY 指定证书 SHA-1，避免选错团队。')
    if required:
        raise ValueError('本机没有可用的 Apple 开发签名。请在 Xcode → Settings → Accounts 配置开发团队与 Apple Development 证书，再运行本命令。')
    return '-'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['check', 'sign'])
    parser.add_argument('app', nargs='?', type=Path)
    args = parser.parse_args()
    result = subprocess.run(['security', 'find-identity', '-v', '-p', 'codesigning'],
                            check=True, capture_output=True, text=True)
    identity = choose_identity(identities(result.stdout), os.environ.get('DEVKIT_SIGNING_IDENTITY'),
                               os.environ.get('DEVKIT_REQUIRE_SPOTLIGHT') == '1')
    report = {'signature': 'ad-hoc' if identity == '-' else 'developer', 'identity': identity}
    if identity == '-':
        print('注意：构建为临时签名预览版。工具箱可运行，但本机 Spotlight 的系统调用要求开发者团队签名。', file=sys.stderr)
    if args.command == 'sign':
        if args.app is None:
            parser.error('sign requires an app path')
        # Sign inside-out. Do not overwrite an available developer identity with '-'.
        for target in [args.app / 'Contents/Helpers/DevKitWorker', args.app]:
            subprocess.run(['codesign', '--force', '--sign', identity,
                            '--preserve-metadata=entitlements,flags', str(target)], check=True)
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(args.app)], check=True)
        info = subprocess.run(['codesign', '-dvv', str(args.app)], check=True, capture_output=True, text=True)
        match = re.search(r'^TeamIdentifier=(.+)$', info.stderr, re.M)
        team = match.group(1) if match and match.group(1) != 'not set' else None
        if identity != '-' and not team:
            raise ValueError('签名后没有有效 TeamIdentifier，不能把这个构建交付为 Spotlight 可运行版本。')
        report['teamIdentifier'] = team
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, subprocess.CalledProcessError) as error:
        print(f'签名失败：{error}', file=sys.stderr)
        sys.exit(1)
