import json

def compare(file1, file2):
    with open(file1, 'r') as f:
        d1 = json.load(f)
    with open(file2, 'r') as f:
        d2 = json.load(f)
    
    k1 = set(d1.keys())
    k2 = set(d2.keys())
    
    only1 = k1 - k2
    only2 = k2 - k1
    
    return only1, only2

en_file = '/Users/devmsa/Developer/pose_vision/assets/translations/en.json'
tr_file = '/Users/devmsa/Developer/pose_vision/assets/translations/tr.json'

only_en, only_tr = compare(en_file, tr_file)

print("Only in EN:", only_en)
print("Only in TR:", only_tr)
