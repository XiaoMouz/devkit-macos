"""Read literal translation keys without compiling or executing source code."""
import ast
from pathlib import Path
import re
import textwrap


def swift_literal(source, start):
    quote = '"""' if source.startswith('"""', start) else '"'
    pos = start + len(quote)
    parts, literal, arguments = [], '', 0
    while pos < len(source):
        if source.startswith(quote, pos):
            parts.append(literal)
            key = ''.join(parts)
            if quote == '"""':
                key = textwrap.dedent(key).strip('\n')
            return pos + len(quote), key
        if source.startswith('\\(', pos):
            parts.append(literal + '{' + str(arguments) + '}')
            literal = ''
            arguments += 1
            pos += 2
            depth = 1
            while depth:
                if source[pos] == '"':
                    pos, _ = swift_literal(source, pos)
                    continue
                if source[pos] == '(':
                    depth += 1
                elif source[pos] == ')':
                    depth -= 1
                pos += 1
            continue
        if source[pos] == '\\':
            escapes = {'n': '\n', 't': '\t', 'r': '\r', '"': '"', '\\': '\\', '0': '\0'}
            literal += escapes.get(source[pos + 1], '\\' + source[pos + 1])
            pos += 2
        else:
            literal += source[pos]
            pos += 1
    raise ValueError('Unterminated Swift translation literal')


def source_keys(root):
    for path in sorted([*root.glob('DevKit/**/*.swift'), *root.glob('Sources/**/*.swift')]):
        source = path.read_text()
        for match in re.finditer(r'L10n\.tr\(\s*(?=")', source):
            _, key = swift_literal(source, match.end())
            yield path, key
    paths = [*root.glob('Sources/DevKitCore/Tools/*/Engine.mjs'), *root.glob('Vendor/*.mjs')]
    for path in sorted(paths):
        source = path.read_text()
        for match in re.finditer(r'\btr\(\s*("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')', source):
            yield path, ast.literal_eval(match.group(1))
