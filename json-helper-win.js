
var htmlfile = WSH.CreateObject( 'htmlfile'), JSON;
htmlfile.write( '<meta http-equiv="x-ua-compatible" content="IE=9" />' );
htmlfile.close( JSON = htmlfile.parentWindow.JSON );

try
{
    var txt = WScript.StdIn.ReadAll();
    var obj = JSON.parse( txt );

    var json_stringify = true;

    var i = 0;
    while ( obj && i < WScript.arguments.length )
    {
        var arg = WScript.arguments( i );
        i++;

        if ( arg === "-raw" )
        {
            json_stringify = false;
            continue;
        }

        var m = arg.match( /\[(.*)=(.*)\]/ );
        if ( m )
        {
            var key = m[ 1 ];
            var value = m[ 2 ];
            var item_i = 0;
            var found = null;
            while ( item_i < obj.length )
            {
                var item = obj[ item_i ];
                item_i++;
                if ( item[ key ] == value )
                {
                    found = item;
                    break;
                }
            }
            obj = found;
            continue;
        }

        obj = obj[ arg ];
    }

    WScript.StdOut.WriteLine( json_stringify ? JSON.stringify( obj, undefined, 2 ) : obj );
}
catch ( err )
{
    WScript.StdErr.WriteLine( err );
    WScript.StdErr.WriteLine( err.message );
}

