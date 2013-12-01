local file
local filename
logger = {}
------------------------------------------------------
function logger.init()
	filename = os.time()
	local path = system.pathForFile( filename, system.DocumentsDirectory )
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
function logger.getFilename()
	return filename
end
----------------------------------
