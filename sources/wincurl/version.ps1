####

$ZLIB_VERSION = "1.2.11"
$ZLIB_HASH = "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff"

$OPENSSL_VERSION = "1.1.1"
$OPENSSL_HASH = "2836875a0f89c03d0fdf483941512613a50cfb421d6fd94b9f41d7279d586a3d"

$BROTLI_VERSION = "1.0.5"
$BROTLI_HASH = "3d5bedd48edb909fe3b87cb99f7d139b987ef6f1616b7e22d74e928270a2fd20"

$LIBSSH2_VERSION = "1.8.0"
$LIBSSH2_HASH = "39f34e2f6835f4b992cafe8625073a88e5a28ba78f83e8099610a7b3af4676d4"

$NGHTTP2_VERSION = "1.34.0"
$NGHTTP2_HASH = "8889399ddd38aa0405f6e84f1c050a292286089441686b8a9c5e937de4f5b61d"

$CURL_VERSION = "7.61.1"
$CURL_HASH = "eaa812e9a871ea10dbe8e1d3f8f12a64a8e3e62aeab18cb23742e2f1727458ae"

# Filename
$ZLIB_FILENAME = "zlib-${ZLIB_VERSION}"
$ZLIB_URL = "https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz"
#$ZLIB_URL = "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"

$OPENSSL_URL = "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
$OPENSSL_FILE = "openssl-${OPENSSL_VERSION}"

$BROTLI_URL = "https://github.com/google/brotli/archive/v${BROTLI_VERSION}.tar.gz"
$BROTLI_FILE = "brotli-${BROTLI_VERSION}"

$NGHTTP2_URL = "https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz"
$NGHTTP2_FILE = "nghttp2-${NGHTTP2_VERSION}"

$LIBSSH2_URL = "https://www.libssh2.org/download/libssh2-${LIBSSH2_VERSION}.tar.gz"
$LIBSSH2_FILE = "libssh2-${LIBSSH2_VERSION}"

$CURL_URL = "https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz"
$CURL_FILE = "curl-${CURL_VERSION}"

#curl-ca-bundle
$CA_BUNDLE_URL = "https://curl.haxx.se/ca/cacert-2018-10-17.pem"


Write-Host -ForegroundColor Cyan "zlib: $ZLIB_VERSION $ZLIB_HASH
openssl: $OPENSSL_VERSION $OPENSSL_HASH
brotli: $BROTLI_VERSION
libssh2: $LIBSSH2_VERSION
nghttp2: $NGHTTP2_VERSION
curl: $CURL_VERSION"