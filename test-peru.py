import sys

if sys.stdout.encoding == 'ANSI_X3.4-1968':
    sys.stdout = open(
        sys.stdout.fileno(), mode='w', encoding='utf8', buffering=1)
    sys.stderr = open(
        sys.stderr.fileno(), mode='w', encoding='utf8', buffering=1)
        
f = open(r'kirapipenv\peru.yaml')
r = f.read()
print(r)
