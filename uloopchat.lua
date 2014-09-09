#!/usr/bin/env lua
--[[
uloopchat - Chat Server over lua-uloop and lua-socket 

Copyright 2014 Agustí Moll <agusti@biruji.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0


]]--

local socket = require("socket")
local uloop = require("uloop")

clients = {}
port = 9099

-- Functions 
function sendAll(msg,myip,anonymous)
	for yourip,csocket in pairs(clients) do
		if ( yourip ~= myip ) then
			if (anonymous ~= true) then
				csocket:send("[" .. myip .. "]: ")
			else 
				csocket:send(" *** ")
			end
			csocket:send(msg .. "\n")
		end
	end
end


uloop.init()

-- TCP Chat Server

local tcp = socket.tcp()
tcp:setoption("reuseaddr", true);
tcp:settimeout(0)
tcp:bind("*", port);
tcp:listen();
print("Start chat daemon.")

tcp_ev = uloop.fd_add( tcp, function(tfd, events)
-- Is new client?
	tfd:settimeout(3)
	local new_client = assert(tfd:accept())
	if new_client ~= nil then
		client_ip , port = new_client:getpeername()
		client_id = client_ip .. ":" .. port

		clients[client_id] = new_client
		print("New client from " .. client_id)
		sendAll("New client from " .. client_id, client_id,true)
		
--		Wait read event...
		uloop.fd_add(new_client, function(csocket,events)
			myip , port = csocket:getpeername()
			myid = myip .. ":" .. port

			local msg = csocket:receive()
			if msg == nil then
				csocket:close()
				clients[myid] = nil
				print("Remove client: " .. myid)
				sendAll("Close connection from ".. myid, myid,true)
			else
				sendAll(msg,myid)
			end
		end, uloop.ULOOP_READ)
	end

end, uloop.ULOOP_READ)

uloop.run()

