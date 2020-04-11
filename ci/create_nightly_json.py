import subprocess
import sys
import json
import datetime
import urllib.parse

def main():
    files_by_date = {}

    files_lines = execute_cli("b2 ls --long odin-binaries nightly").split("\n")
    for x in files_lines:
        parts = x.split(" ", 1)
        if parts[0]:
            json_str = execute_cli(f"b2 get-file-info {parts[0]}")
            data = json.loads(json_str)
            name = remove_prefix(data['fileName'], "nightly/")
            url = f"https://f001.backblazeb2.com/file/odin-binaries/nightly/{urllib.parse.quote_plus(name)}"
            sha1 = data['contentSha1']
            ts = int(data['fileInfo']['src_last_modified_millis'])
            date = datetime.datetime.fromtimestamp(ts/1000).strftime('%Y-%m-%d')
            
            if date not in files_by_date.keys():
                files_by_date[date] = []

            files_by_date[date].append({
                                            'name': name,
                                            'url': url,
                                            'sha1': sha1,
                                         })

    now = datetime.datetime.utcnow().isoformat()

    print(json.dumps({
                        'last_updated' : now,
                        'files': files_by_date
                     }, sort_keys=True, indent=4))

def remove_prefix(text, prefix):
    return text[text.startswith(prefix) and len(prefix):]

def execute_cli(command):
    sb = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    return sb.stdout.read().decode("utf-8");

if __name__ == '__main__':
    sys.exit(main())

