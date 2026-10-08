-- Explicit node registry; callers cannot choose arbitrary upstream URLs.
return {
    methods = {
        node_info = true, list_peers = true, list_channels = true,
        graph_nodes = true, graph_channels = true,
        get_invoice = true, parse_invoice = true, get_payment = true,
    },
    nodes = {
        ["fiber-mainnet-bootnode-hk"] = { address = "43.199.24.44:8227" },
        ["fiber-mainnet-bootnode-sgd"] = { address = "54.255.71.126:8227" },
        ["fiber-mainnet-public-tokyo"] = { address = "54.178.252.1:8227", token_env = "FIBER_TOKYO_BISCUIT_TOKEN" },
        ["fiber-mainnet-public-ca"] = { address = "52.52.69.223:8227", token_env = "FIBER_CA_BISCUIT_TOKEN" },
        ["fiber-testnet-bootnode-hk"] = { address = "16.163.7.105:8117" },
        ["fiber-testnet-bootnode-sgd"] = { address = "54.179.226.154:8117" },
        ["fiber-testnet-01"] = { address = "18.162.235.225:8117" },
        ["fiber-testnet-02"] = { address = "18.163.221.211:8117" },
    },
}
