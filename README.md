# Fiber RPC gateway for AI log analysis

An Nginx/Lua gateway for eight Fiber nodes. Based on the `fiber-proxy` branch.
Only explicitly allowlisted JSON-RPC methods are forwarded.

## Deployment

```bash
cp .env.example .env
chmod 600 .env
# Fill in a strong AI_RPC_TOKEN and the two node-specific Biscuit tokens.
docker compose up -d --build
docker compose exec fiber-rpc-gateway nginx -t
```

The service publishes port 80 on all IPv4 interfaces (`0.0.0.0:80:80`).
A domain pointing to the server can reach the gateway over HTTP when the server
security group/firewall allows inbound TCP port 80. Use Cloudflare Tunnel or a
TLS reverse proxy for HTTPS access, and restrict inbound access as appropriate. Each Fiber security group should allow its RPC port only
from the gateway server's outbound IP.

Do not commit `.env`, private keys or tokens. Restart the container after changing
`.env`; environment variables are loaded at container creation time.

## Calling the gateway

Call `POST /rpc/<node-name>` with `Authorization: Bearer <AI_RPC_TOKEN>`.

```bash
curl https://<gateway-domain>/rpc/fiber-mainnet-public-tokyo \
  -H "Authorization: Bearer ${AI_RPC_TOKEN}" \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"node_info","params":[]}'
```

The AI token is replaced before forwarding. Nodes without Biscuit receive no
Authorization header. Tokyo and California receive their own configured Biscuit
token; Fiber verifies it using the node's existing `biscuit_public_key`. The
gateway neither needs the public key nor signs tokens.

Generate each Biscuit token with the corresponding node's private key outside
this repository. Suggested read permissions (add an expiry as appropriate):

```datalog
read("node");
read("peers");
read("channels");
read("graph");
read("invoices");
read("payments");
```

See [Fiber Biscuit documentation](https://github.com/nervosnetwork/fiber/blob/develop/docs/biscuit-auth.md).
Invalid, expired or insufficiently privileged Biscuit tokens are rejected by Fiber.
Upstream RPC responses, including authorization failures, are passed through.

## Default method whitelist

Edit `lua/config.lua` to change this list; restart/reload Nginx after editing.

- `node_info`
- `list_peers`
- `list_channels`
- `graph_nodes`
- `graph_channels`
- `get_invoice`
- `parse_invoice`
- `get_payment`

Write methods and unknown/new methods are denied by default. `build_router` is
excluded to keep the initial diagnostic interface small. Method availability and
parameters depend on the Fiber version running on each node.

Only a single JSON-RPC 2.0 request with a string or numeric ID is accepted.
Batches, notifications, malformed JSON, encoded bodies and query parameters are
rejected. The inspected JSON is re-encoded before forwarding to prevent duplicate
key interpretation differences. Request bodies and credentials are not logged.

Defaults: 256 KiB body limit, 5 requests/second/IP with burst 10, 5 concurrent
requests/IP, 5 second connect timeout and 30 second upstream read/send timeout.
Behind a tunnel, the IP limits may be shared by all clients. Nginx timeouts measure
inactivity, not total execution duration. Gateway-to-node traffic uses HTTP as
provided; use private networking or an encrypted tunnel if transport encryption
is required.

## Validation

```bash
python -m pip install lupa
python -m unittest discover -s tests -v
```

The unit suite executes the Lua access handler with a mocked Nginx API. For real
container validation, run `nginx -t` above and test allowed/denied requests after
supplying credentials. No production node calls are needed for unit tests.
