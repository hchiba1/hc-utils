#!/usr/bin/env python3
import argparse
import subprocess
import sys

parser = argparse.ArgumentParser(description='Remove docker container or image')
parser.add_argument('name', help='container or image')
args = parser.parse_args()

ret1 = subprocess.run([ 'docker', 'rm', args.name ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if ret1.returncode == 0:
    print('removed container', file=sys.stderr)
    sys.exit()

ret2 = subprocess.run([ 'docker', 'rmi', args.name ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if ret2.returncode == 0:
    print('removed image', file=sys.stderr)
    sys.exit()

print('cannot remove', file=sys.stderr)
print('rm:', ret1.stdout.decode())
print('rm err:', ret1.stderr.decode(), file=sys.stderr)
print('rmi:', ret2.stdout.decode())
print('rmi err:', ret2.stderr.decode(), file=sys.stderr)
