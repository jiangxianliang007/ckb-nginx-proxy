## Introduce
Use nginx +lua to restrict some of the ckb methods from being requested

## List of restricted methods
```
clear_banned_addresses
set_ban
set_network_active
add_node
remove_node
remove_transaction
clear_tx_pool
```
## You need to install docker-compose and docker
```
apt install docker-compose
apt install docker
```

## clone code
```
git clone https://github.com/cryptape/ckb-nginx-proxy.git
```

## Replace the default value with your ckb rpc address, Suppose your rpc IP is 192.168.1.100
```
cd ckb-nginx-proxy

sed -i "s/DEFAULT_CKR_RPC_IP:8114/192.168.1.100:8114/" nginx.conf 

sed -i "s/rich_indexer_rpc/your rich-indexer/" nginx.conf 

Fill in the real discord webhook in nginx.conf
```

## run proxy
```
docker-compose up -d
```

## Examples
Note that http://192.168.1.100:80 needs to be changed to the IP of your proxy

get tip block hash and number

```
echo '{
    "id": 2,
    "jsonrpc": "2.0",
    "method": "get_tip_header",
    "params": []
}' \
| tr -d '\n' \
| curl -H 'content-type: application/json' -d @- \
http://192.168.1.100:80
```
result
```
{
    "jsonrpc": "2.0",
    "result": {
        "compact_target": "0x1d090fbe",
        "dao": "0xba17553fab3db84154bc4aa9f09b2600e826a2b0df99010400ed51b4686b5808",
        "epoch": "0x7080687001539",
        "extra_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "hash": "0x7a46e779a3fc2d5b55c82aad852e721b0097bf873927b9751409b1d185599ce4",
        "nonce": "0xd265e70dfd205dbbed33b29294121856",
        "number": "0x7037f2",
        "parent_hash": "0x3d105fe9ec60f138baa6623abd16af70ba1be90ad23d1943bcaa55d5f14fcb6f",
        "proposals_hash": "0x2581d1769886226a8c90ee99baf2d8696e24c7f6bb6751748ff8b4452f8006e5",
        "timestamp": "0x1847a2bfad2",
        "transactions_root": "0x28157a5962c4ae1d3e153b1d8d331e5fd3c158866287f5398ab7f7d38210dfb0",
        "version": "0x0"
    },
    "id": 2
}
```

execute clear_tx_pool

```
echo '{
    "id": 2,
    "jsonrpc": "2.0",
    "method": "clear_tx_pool",
    "params": []
}' | tr -d '\n' | curl -H 'content-type: application/json' -d @- \
http://192.168.1.100:80
```
result
```
This method Access forbidden
```
