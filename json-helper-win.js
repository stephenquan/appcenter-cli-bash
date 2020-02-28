
var htmlfile = WSH.CreateObject( 'htmlfile'), JSON;
htmlfile.write( '<meta http-equiv="x-ua-compatible" content="IE=9" />' );
htmlfile.close( JSON = htmlfile.parentWindow.JSON );

var txt = WScript.StdIn.ReadAll();
try
{
    var obj = JSON.parse( txt );
    var i = 0;
    while ( obj && i < WScript.arguments.length )
    {
        var arg = WScript.arguments( i );
	i++;
        obj = obj[ arg ];
    }
    WScript.Echo( JSON.stringify( obj, undefined, 2 ) );
}
catch ( err )
{
    WScript.Echo( err );
}

