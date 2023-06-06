#!/usr/bin/env python3
import sys
import argparse
from classes.FtpCli import FtpCli

parser = argparse.ArgumentParser(description='submit FTP command')
parser.add_argument('path', help='file path on the server')
parser.add_argument('--list', action='store_true', help='LIST')
parser.add_argument('--ls', action='store_true', help='ls')
parser.add_argument('-v', '--verbose', action='store_true', help='verbose')
args = parser.parse_args()

path = args.path.replace('ftp://', '')
pos = path.find('/')
server = path[0:pos]
path = path[pos:]

if args.verbose:
    print(f'server: {server}', file=sys.stderr)
    print(f'path: {path}', file=sys.stderr)

cli = FtpCli(server)

if args.list:
    print(cli.ftp.retrlines(f'LIST {path}'), file=sys.stderr)
elif args.ls:
    list = cli.ftp.nlst(path)
    print("\n".join(list))

cli.ftp.close()
