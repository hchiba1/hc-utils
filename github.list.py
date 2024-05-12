#!/usr/bin/env python3
import argparse
import subprocess
import threading

parser = argparse.ArgumentParser(description='')
parser.add_argument('names', nargs='*', help='repository names', default=["orthordf", "bioal", "sparqling", "hchiba1", "dbcls", "togodx", "togoid", "g2glab", "gdbp", "mbgd-prj", "qfo"])
parser.add_argument('-t', '--time', action='store_true', help='sort by time')
args = parser.parse_args()

def repo_list(name, results):
    ret = subprocess.run(f'gh repo list {name} -L1000', shell=True, stdout=subprocess.PIPE)
    if ret.returncode == 0:
        results[name] = ret.stdout.decode()

def main():
    results = dict()
    threads = []
    for name in args.names:
        threads.append(threading.Thread(target=repo_list, args=(name, results)))
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    for name in args.names:
        print_results(name, results)

def print_results(name, results):
    print(f'==[ {name} ]==')
    lines = results[name].split('\n')
    out = dict()
    for line in lines:
        fields = line.split("\t")
        if len(fields) == 4:
            repo, descr, tags, datetime = line.split("\t")
            tags = convert(tags)
            priority = convert_priority(tags)
            key = f'{priority} {repo}'
            if args.time:
                key = f'{datetime} {repo}'
            datetime = datetime.split("T")[0]
            out[key] = "\t".join([f'{datetime}  {tags}', repo, descr])
    for key in sorted(out.keys()):
        print(out[key])
    print()

def convert_priority(tags):
    priority = ""
    if tags == "public":
        priority = "1"
    if tags == "public, fork":
        priority = "z"
    else:
        priority = tags.replace(", fork", " fork")
    if tags == "public, archived":
        priority = "archived"
    else:
        priority = tags.replace(", archived", " archived")
    return priority
    
def convert(tags):
    if tags == "public":
        tags = ""
    if tags == "public, fork":
        tags = "fork"
    else:
        tags = tags.replace(", fork", " fork")
    if tags == "public, archived":
        tags = "archived"
    else:
        tags = tags.replace(", archived", " archived")
    if tags:
        tags = "[" + tags + "]"
    return tags

if __name__ == '__main__':
    main()
