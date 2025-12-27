import json
import re
import os

def find_tr_keys(directory):
    keys = set()
    tr_pattern = re.compile(r"['\"]([a-zA-Z0-9_]+)['\"]\s*\.tr\(\)")
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    content = f.read()
                    matches = tr_pattern.findall(content)
                    for match in matches:
                        keys.add(match)
    return keys

project_dir = '/Users/devmsa/Developer/pose_vision/lib'
used_keys = sorted(list(find_tr_keys(project_dir)))
print("Found keys count:", len(used_keys))
for k in used_keys:
    print(k)
