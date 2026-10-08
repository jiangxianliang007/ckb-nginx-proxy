FROM fabiocicerchia/nginx-lua:1.21.6-alpine3.15.1-compat

# Install a pinned source rock directly: older LuaRocks cannot load the
# current large manifests (Lua 5.1 exceeds its 65536-constant limit).
RUN apk add --no-cache gcc musl-dev coreutils \
    && luarocks --lua-version=5.1 install https://luarocks.org/lua-cjson-2.1.0.10-1.src.rock --deps-mode=none \
    && luajit -e 'package.cpath = "/usr/local/lib/lua/5.1/?.so;" .. package.cpath; assert(require("cjson.safe"))'
