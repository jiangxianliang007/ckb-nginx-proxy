# Fiber RPC proxy

NGINX + Lua filters restricted Fiber RPC methods and authenticates upstream requests using a server-side Biscuit token. Clients do not need the upstream token. This is a shared public RPC proxy, not a tenant-authenticated LSP gateway.

## Configuration

1. Enable `rpc.biscuit_public_key` on Fiber. Keep the backend RPC private and reachable only from trusted hosts.
2. Generate a dedicated least-privilege Biscuit token using the [Fiber authentication guide](https://github.com/nervosnetwork/fiber/blob/develop/docs/biscuit-auth.md). For a public read-only proxy, start with:

```
read("node");
read("graph");
```

Grant other read permissions only if their data is intended to be public. Do not use an admin, tenant, or write-capable token for this public proxy.
3. Set the upstream address in `nginx.conf` and create a local `.env` file with restrictive permissions (do not commit it):

```sh
umask 077
touch .env
chmod 600 .env
```

Set `FIBER_RPC_TOKEN=<raw Biscuit token>` in that file, without the Bearer prefix. Then run:

```sh
docker compose up -d --force-recreate
docker compose exec ckb-nginx-proxy nginx -t
```

Missing or malformed token configuration prevents NGINX startup. Fiber validates the signature, expiry and method permissions. Rotate the token by updating the local file and recreating the container. Environment variables are visible to privileged Docker operators. Do not enable debug logging or expose backend traffic to untrusted networks.

## Restricted methods

The existing denylist remains in effect for single and batch requests:

```
open_channel
accept_channel
shutdown_channel
update_channel
commitment_signed
add_tlc
remove_tlc
submit_commitment_transaction
cancel_invoice
send_payment
connect_peer
disconnect_peer
```

The denylist is not a complete authorization policy; the upstream token must enforce least privilege, including for newly introduced RPC methods.

## Verify

```sh
curl -sS http://127.0.0.1:80/ -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"node_info","params":[]}'
```

Expect a successful response with a valid token granting node read access. A client-supplied Authorization header is replaced, not forwarded. A denied method such as open_channel must return HTTP 403 even if included in a batch. Invalid, expired or insufficiently privileged upstream tokens must be rejected by Fiber.
