#!/usr/bin/python3
import argparse
import os
import sys
import json
import re
import codecs
import urllib.parse
import subprocess
import requests

### Command-line options
argparser = argparse.ArgumentParser(
    description="SPANG is an easy-to-use command-line SPARQL client.",
    epilog="",
    add_help=True,
)
argparser.add_argument("query_file", help="SPARQL query file", nargs='?')
argparser.add_argument("-q", "--quit", help="print query and quit", action="store_true")
argparser.add_argument("-e", "--endpoint", help="SPARQL endpoint", required=True)
argparser.add_argument("-L", "--limit", type=int)
# argparser.add_argument("-S", "--subject")
# argparser.add_argument("-P", "--property")
# argparser.add_argument("-O", "--object")
args = argparser.parse_args()

endpoint = args.endpoint

if args.limit:
    sparql = 'select * {?s ?p ?o} limit ' + str(args.limit)
else:
    with open(args.query_file) as f:
        sparql = f.read()

if args.quit:
    print(sparql)
    exit(1)

headers = {
    'Accept': 'application/sparql-results+json',
}
params = (
    ('query', sparql),
)
response = requests.get(endpoint, headers=headers, params=params)
print(response.text)
