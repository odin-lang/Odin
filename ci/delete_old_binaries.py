import subprocess
import sys
import json
import datetime
import urllib.parse
import sys

def main():
    files_by_date = {}
    bucket = sys.argv[1]
    days_to_keep = int(sys.argv[2])
    print(f"Looking for binaries to delete older than {days_to_keep} days")

    files_lines = execute_cli(f"b2 ls --long --versions {bucket} nightly").split("\n")
    for x in files_lines:
        parts = [y for y in x.split(' ') if y]

        if parts and parts[0]:
            date = datetime.datetime.strptime(parts[2], '%Y-%m-%d').replace(hour=0, minute=0, second=0, microsecond=0)
            now = datetime.datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
            delta = now - date

            if delta.days > days_to_keep:
                print(f'Deleting {parts[5]}')
                execute_cli(f'b2 delete-file-version {parts[0]}')


def execute_cli(command):
    sb = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    return sb.stdout.read().decode("utf-8");

if __name__ == '__main__':
    sys.exit(main())

