local json = require "cjson.safe"
local config = require "config"
local function reject(status, code, message)
    ngx.status = status
    ngx.header.content_type = "application/json"
    ngx.say(json.encode({jsonrpc = "2.0", error = {code = code, message = message}, id = json.null}))
    return ngx.exit(status)
end

local gateway_token = os.getenv("AI_RPC_TOKEN")
if not gateway_token or gateway_token == "" then
    return reject(503, -32000, "Gateway authentication is not configured")
end
if ngx.req.get_headers()["Authorization"] ~= "Bearer " .. gateway_token then
    return reject(401, -32001, "Unauthorized")
end
if ngx.req.get_method() ~= "POST" then
    ngx.header.allow = "POST"
    return reject(405, -32600, "POST required")
end
local name = ngx.var.uri:match("^/rpc/([a-z0-9%-]+)$")
local node = name and config.nodes[name]
if not node then return reject(404, -32004, "Unknown node") end
if ngx.var.args and ngx.var.args ~= "" then
    return reject(400, -32600, "Query parameters are not supported")
end
-- Do not accept compressed bodies: inspection must match the upstream payload.
local headers = ngx.req.get_headers()
if headers["Content-Encoding"] then return reject(415, -32600, "Encoded bodies are not supported") end
local content_type = headers["Content-Type"]
if type(content_type) ~= "string" or (content_type:lower():match("^%s*([^;]+)") or ""):match("^(.-)%s*$") ~= "application/json" then
    return reject(415, -32600, "application/json required")
end
ngx.req.read_body()
local body = ngx.req.get_body_data()
if not body then return reject(400, -32700, "Missing or oversized JSON body") end
local request = json.decode(body)
if type(request) ~= "table" then return reject(400, -32700, "Invalid JSON") end
-- Only single requests, with IDs. Batches and notifications are deliberately rejected.
if request.jsonrpc ~= "2.0" or type(request.method) ~= "string"
    or request.id == nil or request.id == json.null
    or (type(request.id) ~= "string" and type(request.id) ~= "number")
    or (request.params ~= nil and type(request.params) ~= "table") then
    return reject(400, -32600, "Single JSON-RPC 2.0 request with an id required")
end
if not config.methods[request.method] then
    return reject(403, -32601, "RPC method is not allowed")
end
ngx.var.fiber_upstream = node.address
ngx.var.fiber_authorization = ""
if node.token_env then
    local token = os.getenv(node.token_env)
    if not token or token == "" then return reject(503, -32000, "Node authentication is not configured") end
    ngx.var.fiber_authorization = "Bearer " .. token
end
-- Re-encode the inspected object to eliminate duplicate-key parser discrepancies.
ngx.req.set_body_data(json.encode(request))
