#!/usr/bin/env python3
import argparse
import subprocess
import sys

parser = argparse.ArgumentParser(description='Remove docker container or image')
parser.add_argument('name', nargs='+', help='container or image')
args = parser.parse_args()

def remove(id):
    ret1 = subprocess.run([ 'docker', 'rm', id ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if ret1.returncode == 0:
        print(f'removed container {id}', file=sys.stderr)
        return

    ret2 = subprocess.run([ 'docker', 'rmi', id ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if ret2.returncode == 0:
        print(f'removed image {id}', file=sys.stderr)
        return

    print(ret1.stderr.decode(), end='', file=sys.stderr)
    print(ret2.stderr.decode(), end='', file=sys.stderr)

for id in args.name:
    remove(id)
