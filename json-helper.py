import sys, json, re;

obj = json.load( sys.stdin )
json_dumps = True

i = 1

while i < len( sys.argv ):

    arg = sys.argv[ i ]
    i += 1

    m = re.match( r"^\[(.*)=(.*)\]$", arg )
    if m:
        key = m.group( 1 )
        value = m.group( 2 )
        found = None
        for item in obj:
            if item[ key ] == value:
                found = item
                break
        obj = found
        continue

    if arg == "-raw":
        json_dumps = False
        continue

    obj = obj[ arg ]

print( json.dumps( obj, indent=2 ) if json_dumps else obj )

