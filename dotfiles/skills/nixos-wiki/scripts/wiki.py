#!/usr/bin/env python3
"""Search retained NixOS Wiki text offline. No rendering, expansion, or execution."""

import argparse
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import quote

PACKAGE = Path(__file__).resolve().parents[1]
MAX_BYTES = 16 * 1024


def read_json(path):
    if path.is_symlink() or path.stat().st_size > 2_000_000:
        raise ValueError('Unsupported/oversize snapshot file')
    return path.read_bytes()


def load(package=PACKAGE):
    manifest = json.loads(read_json(package / 'sources.json'))
    result = {}
    for name in ['pages', 'templates']:
        filename = 'references/' + name + '.json'
        data = read_json(package / filename)
        if hashlib.sha256(data).hexdigest() != manifest['outputs'][filename]:
            raise ValueError('Snapshot hash mismatch: ' + filename)
        records = json.loads(data)
        if set(result) & set(records):
            raise ValueError('Ambiguous snapshot titles')
        result.update(records)
    return manifest, result


def search(records, query, templates=False):
    if not query.strip() or len(query) > 256:
        raise ValueError('Use a literal query between 1 and 256 characters')
    query = query.casefold()
    matches = []
    for title, record in records.items():
        if record['namespace'] != 0 and not (templates and record['namespace'] == 10):
            continue
        title_match = query in title.casefold()
        position = record['text'].casefold().find(query)
        if title_match or position >= 0:
            snippet = record['text'][max(position, 0):max(position, 0)+240].replace('\n', ' ').replace('\r', ' ')
            matches.append((not title_match, title.casefold(), title, snippet, record['revision_id']))
    return sorted(matches)[:10]


def route(records, title, follow=False):
    hops, seen = [], set()
    while True:
        if title in seen or len(seen) >= 16:
            raise ValueError('Redirect cycle/limit')
        seen.add(title)
        if title not in records:
            if not hops:
                raise ValueError('Exact title is not bundled: ' + title)
            return hops, None, title
        record = records[title]
        if not follow or not record['redirect']:
            return hops, record, None
        hops.append(record)
        title = record['redirect']['title']


def window(text, start=1, lines=200, offset=0):
    """The character offset permits progress even when one line exceeds the byte cap."""
    content = text.splitlines(keepends=True) or ['']
    if not 1 <= start <= len(content) or not 1 <= lines <= 200 or not 0 <= offset <= len(content[start-1]):
        raise ValueError('Invalid line window or character offset')
    output, count, index, column = [], 0, start-1, offset
    end = min(len(content), index+lines)
    while index < end:
        rest = content[index][column:]
        part = rest.encode()[:MAX_BYTES-count].decode('utf-8', errors='ignore')
        output.append(part)
        count += len(part.encode())
        column += len(part)
        if column < len(content[index]):
            break
        index, column = index+1, 0
        if count == MAX_BYTES:
            break
    continuation = (index+1, column) if index < len(content) else None
    return ''.join(output), continuation, len(content)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    finder = commands.add_parser('search')
    finder.add_argument('query')
    finder.add_argument('--templates', action='store_true')
    viewer = commands.add_parser('show')
    viewer.add_argument('title')
    viewer.add_argument('--follow', action='store_true')
    viewer.add_argument('--start', type=int, default=1)
    viewer.add_argument('--lines', type=int, default=200)
    viewer.add_argument('--offset', type=int, default=0, help='Character offset within the starting line')
    args = parser.parse_args()
    try:
        manifest, records = load()
        print('Retained raw wikitext; templates are not expanded.')
        print('Dump SHA-256: ' + manifest['snapshot_sha256'])
        if args.command == 'search':
            matches = search(records, args.query, args.templates)
            for _, _, title, snippet, revision in matches:
                print(f'\n{title} [revision {revision}]\nhttps://wiki.nixos.org/w/index.php?oldid={revision}\n{snippet}')
            print('\nSnippets can omit caveats; show the page before using its advice.' if matches else '\nNo bundled matches.')
            return
        hops, record, missing = route(records, args.title, args.follow)
        for hop in hops:
            target = hop['redirect']
            print(f'Redirect: {hop["title"]} [revision {hop["revision_id"]}] → {target["title"]}#{target["fragment"]}')
        if missing:
            print('Target not bundled. Live, unpinned page: https://wiki.nixos.org/wiki/' + quote(missing.replace(' ', '_'), safe=''))
            return
        print(f'{record["title"]} — revision {record["revision_id"]}, {record["timestamp"]}')
        print('https://wiki.nixos.org/w/index.php?oldid=' + str(record['revision_id']))
        body, continuation, total = window(record['text'], args.start, args.lines, args.offset)
        print(f'Window starts at line {args.start}, character {args.offset}; {total} total lines.')
        print('Earlier text omitted.' if args.start > 1 or args.offset else 'Page starts here; read notices before applying examples.')
        print('--- original wikitext ---')
        sys.stdout.write(body)
        print('\n--- end of window ---')
        if continuation:
            print(f'More text omitted. Continue this exact title with --start {continuation[0]} --offset {continuation[1]}')
        else:
            print('End of page.')
    except (ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(2, str(error) + '\n')


if __name__ == '__main__':
    main()
