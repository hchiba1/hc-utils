#!/usr/bin/env python3
import argparse
import subprocess
import threading

parser = argparse.ArgumentParser(description='')
parser.add_argument('names', nargs='*', help='repository names', default=["orthordf", "bioal", "sparqling", "pg-format", "hchiba1", "dbcls", "togodx", "togoid", "g2glab", "gdbp", "mbgd-prj", "qfo"])
parser.add_argument('-t', '--time', action='store_true', help='sort by time')
args = parser.parse_args()

out_dict = dict()

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
        out_txt, key = format_results(name, results)
        if args.time:
            out_dict[key] = out_txt
        else:
            print(out_txt)
    if args.time:
        for key in sorted(out_dict.keys(), reverse=True):
            print(out_dict[key])

def format_results(name, results):
    out_txt = f'==[ {name} ]==\n'
    lines = results[name].split('\n')
    repo_dict = dict()
    datetime_arr = []
    for line in lines:
        fields = line.split("\t")
        if len(fields) == 4:
            repo, descr, tags, datetime = line.split("\t")
            tags = convert(tags)
            priority = convert_priority(tags)
            key = f'{priority} {repo}'
            if args.time:
                key = f'{datetime} {repo}'
            datetime_arr.append(datetime)
            if args.time:
                date = datetime.replace("T", " ").replace("Z", "")
            else:
                date = datetime.split("T")[0]
            repo_dict[key] = "\t".join([f'{date}  {tags}', repo, descr])
    if args.time:
        sorted_keys = sorted(repo_dict.keys(), reverse=True)
    else:
        sorted_keys = sorted(repo_dict.keys())
    for key in sorted_keys:
        out_txt += repo_dict[key] + "\n"
    last_update = max(datetime_arr)
    return out_txt, f'{last_update} {name}'

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
