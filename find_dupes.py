
import json
from collections import Counter

def find_duplicates(data, path=""):
    if isinstance(data, list):
        # JSON standard doesn't disallow duplicates in lists per se, but usually lists contain values
        # We are looking for duplicate keys in objects
        for i, item in enumerate(data):
            find_duplicates(item, f"{path}[{i}]")
    elif isinstance(data, dict):
        # In Python, loading json into dict ALREADY de-duplicates (wins last one).
        # We need to parse manually or use object_pairs_hook.
        pass

def detect_dupes(pairs):
    keys = [k for k, v in pairs]
    counts = Counter(keys)
    dupes = [k for k, v in counts.items() if v > 1]
    if dupes:
        print(f"Duplicates found: {dupes}")
    return dict(pairs)

with open('assets/translations/ru.json', 'r') as f:
    try:
        json.load(f, object_pairs_hook=detect_dupes)
    except Exception as e:
        print(e)
