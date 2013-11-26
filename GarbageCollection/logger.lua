local file
logger = {}
------------------------------------------------------
function logger.init()
	local path = system.pathForFile( os.time(), system.DocumentsDirectory )
    file = io.open( path, "w" )
    logger.log("GameStarted")
end
------------------------------------------------------
function logger.log(event)
    file:write( os.time()..","..event.."\n" )
    io.flush()
end
----------------------------------
function logger.close()
    io.close( file )
    file = nil
end
----------------------------------
