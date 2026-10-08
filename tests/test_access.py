import json
import unittest
from pathlib import Path
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class GatewayTests(unittest.TestCase):
    def run_request(self, body=None, node='fiber-testnet-01', auth='Bearer ai', env=None, method='POST', headers=None, args=None):
        lua = LuaRuntime(unpack_returned_tuples=True)
        null = lua.table()
        def convert(value):
            if value is None:
                return null
            if isinstance(value, (list, dict)):
                items = enumerate(value, 1) if isinstance(value, list) else value.items()
                return lua.table_from({k: convert(v) for k, v in items})
            return value
        def decode(value):
            try:
                return convert(json.loads(value))
            except ValueError:
                return None
        lua.globals().decode = decode
        lua.globals().null = null
        lua.execute('package.preload["cjson.safe"] = function() return { decode=decode, encode=function(v) return "encoded" end, null=null } end')
        lua.execute('package.preload["config"] = function() ' + (ROOT / 'lua/config.lua').read_text() + ' end')
        settings = {'AI_RPC_TOKEN': 'ai', 'FIBER_TOKYO_BISCUIT_TOKEN': 'tokyo', 'FIBER_CA_BISCUIT_TOKEN': 'ca'} if env is None else env
        lua.globals().getenv = settings.get
        lua.execute('os.getenv = getenv')
        body = '{"jsonrpc":"2.0","id":1,"method":"node_info","params":[]}' if body is None else body
        h = {'Authorization': auth, 'Content-Type': 'application/json'}
        h.update(headers or {})
        ngx = lua.table_from({
            'var': lua.table_from({'uri': '/rpc/' + node, 'args': args}),
            'header': lua.table(),
            'req': lua.table_from({'get_headers': lambda: convert(h), 'get_method': lambda: method,
                                   'read_body': lambda: None, 'get_body_data': lambda: body,
                                   'set_body_data': lambda data: None}),
            'say': lambda data: None, 'exit': lambda status: status,
        })
        lua.globals().ngx = ngx
        lua.execute((ROOT / 'lua/access.lua').read_text())
        return ngx

    def test_all_routes_and_credentials(self):
        expected = {
            'fiber-mainnet-bootnode-hk': ('43.199.24.44:8227', ''),
            'fiber-mainnet-bootnode-sgd': ('54.255.71.126:8227', ''),
            'fiber-mainnet-public-tokyo': ('54.178.252.1:8227', 'Bearer tokyo'),
            'fiber-mainnet-public-ca': ('52.52.69.223:8227', 'Bearer ca'),
            'fiber-testnet-bootnode-hk': ('16.163.7.105:8117', ''),
            'fiber-testnet-bootnode-sgd': ('54.179.226.154:8117', ''),
            'fiber-testnet-01': ('18.162.235.225:8117', ''),
            'fiber-testnet-02': ('18.163.221.211:8117', ''),
        }
        for node, (address, token) in expected.items():
            with self.subTest(node=node):
                result = self.run_request(node=node)
                self.assertIsNone(result.status)
                self.assertEqual(result.var.fiber_upstream, address)
                self.assertEqual(result.var.fiber_authorization, token)

    def test_rejections(self):
        cases = [
            ({'auth': 'Bearer wrong'}, 401), ({'env': {}}, 503),
            ({'node': 'unknown'}, 404), ({'method': 'GET'}, 405),
            ({'body': '{'}, 400), ({'body': '[]'}, 400),
            ({'body': 'null'}, 400),
            ({'body': '[{"jsonrpc":"2.0","id":1,"method":"node_info"}]'}, 400),
            ({'body': '{"jsonrpc":"2.0","method":"node_info"}'}, 400),
            ({'body': '{"jsonrpc":"2.0","id":1,"method":"send_payment"}'}, 403),
            ({'body': '{"jsonrpc":"2.0","id":1,"method":"future_method"}'}, 403),
            ({'headers': {'Content-Encoding': 'gzip'}}, 415),
            ({'headers': {'Content-Type': 'text/plain'}}, 415),
            ({'headers': {'Content-Type': 'application/jsonp'}}, 415),
            ({'args': 'x=1'}, 400),
            ({'node': 'fiber-mainnet-public-ca', 'env': {'AI_RPC_TOKEN': 'ai'}}, 503),
        ]
        for kwargs, status in cases:
            with self.subTest(kwargs=kwargs):
                result = self.run_request(**kwargs)
                self.assertEqual(result.status, status)


if __name__ == '__main__':
    unittest.main()
