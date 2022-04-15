#!/usr/bin/env python3
import argparse
import subprocess
import sys

parser = argparse.ArgumentParser(description='Remove docker container or image')
parser.add_argument('name', help='container or image')
args = parser.parse_args()

ret1 = subprocess.run([ 'docker', 'rm', args.name ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

if ret1.returncode == 0:
    print(ret1.stdout.decode())
    print(ret1.stderr.decode(), file=sys.stderr)
    sys.exit()

ret2 = subprocess.run([ 'docker', 'rmi', args.name ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if ret2.returncode != 0:
    print('cannot remove', file=sys.stderr)
else:
    print('removed image', file=sys.stderr)
