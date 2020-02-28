import sys, json;

obj = json.load( sys.stdin )

for arg in sys.argv[ 1: ] :
    if not isinstance( obj, dict ):
        break
    obj = obj[ arg ]

print( json.dumps( obj, indent=2 ) )

