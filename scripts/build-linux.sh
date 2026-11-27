
#!/usr/bin/env bash

set -euo pipefail

ROOT="$(pwd)"
PACKAGE="nginx-${NGINX_VERSION}-ntlm-linux-x64"
TARGET="$ROOT/dist/$PACKAGE"

echo "========================================"
echo "Building NGINX for Ubuntu x64"
echo "NGINX: $NGINX_VERSION"
echo "NTLM: $NTLM_COMMIT"
echo "========================================"

# 1. Update NGINX version and checksum

COMMON="$ROOT/ntlm-module/utils/build_common.sh"

sed -i \
    "s/^NGINX_VERSION=.*/NGINX_VERSION=${NGINX_VERSION}/" \
    "$COMMON"

sed -i \
    "s/^NGINX_SHA256=.*/NGINX_SHA256=${NGINX_SHA256}/" \
    "$COMMON"

# 2. Download NGINX and dependencies

bash ntlm-module/utils/build_linux_download.sh

# 3. Configure NGINX

bash ntlm-module/utils/build_linux_configure.sh

# 4. Compile NGINX

cd "$ROOT/nginx-$NGINX_VERSION"

make -j"$(nproc)"

# 5. Verify binary

./objs/nginx -V

file objs/nginx

ldd objs/nginx

# 6. Prepare deployment directory

mkdir -p "$TARGET"
mkdir -p "$TARGET/logs"
mkdir -p "$TARGET/temp"
mkdir -p "$TARGET/licenses"

cp objs/nginx "$TARGET/nginx"
cp -r conf "$TARGET/"
cp -r html "$TARGET/"

cp LICENSE "$TARGET/licenses/nginx.txt"

cp "$ROOT/configs/ntlm-test.conf" \
   "$TARGET/conf/ntlm-test.conf"

find "$ROOT/ntlm-module" -maxdepth 1 -type f \
    \( -iname 'LICENSE*' -o -iname 'COPYING*' \) \
    -exec cp {} "$TARGET/licenses/" \;

chmod +x "$TARGET/nginx"

# 7. Test NTLM module

cd "$TARGET"

./nginx -p "$TARGET/" -t \
    -c conf/ntlm-test.conf

# 8. Save build information

{
    echo "NGINX_VERSION=$NGINX_VERSION"
    echo "NGINX_SHA256=$NGINX_SHA256"
    echo "NTLM_COMMIT=$NTLM_COMMIT"
    echo "PLATFORM=Linux"
    echo "ARCHITECTURE=x64"
    echo "BUILD_DATE=$(date -u +%FT%TZ)"
    echo
    cat /etc/os-release
    echo
    ./nginx -V 2>&1
    echo
    ldd ./nginx
    echo
    grep -E '^(PCRE2|OPENSSL|ZLIB)_VERSION=' "$COMMON"
} > build-info.txt

# 9. Create archive

cd "$ROOT/dist"

tar -czf "$PACKAGE.tar.gz" "$PACKAGE"

# 10. Generate SHA256

sha256sum "$PACKAGE.tar.gz" \
    > "$PACKAGE.tar.gz.sha256"

echo "========================================"
echo "LINUX BUILD SUCCESSFUL"
echo "========================================"

ls -lh "$PACKAGE.tar.gz"
cat "$PACKAGE.tar.gz.sha256"
