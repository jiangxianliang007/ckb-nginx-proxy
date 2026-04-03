FROM fabiocicerchia/nginx-lua:1.27.4-alpine3.21.3

LABEL maintainer="jiangxianliang007" \
      description="CKB RPC proxy with method-level access control via nginx+lua" \
      version="1.27.4"

RUN apk add gcc musl-dev coreutils \
    && luarocks install lua-cjson
