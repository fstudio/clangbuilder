####

$ZLIB_VERSION = "1.2.11"
$ZLIB_HASH = "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff"

$OPENSSL_VERSION = "1.1.1i"
$OPENSSL_HASH = "e8be6a35fe41d10603c3cc635e93289ed00bf34b79671a3a4de64fcee00d5242"

$BROTLI_VERSION = "1.0.9"
$BROTLI_HASH = "5c9ca8774bd7b03e5784f26ae9e9e6d749c9da2438545077e6b3d755a06595d9"

$LIBSSH2_VERSION = "1.9.0"
$LIBSSH2_HASH = "d5fb8bd563305fd1074dda90bd053fb2d29fc4bce048d182f96eaa466dfadafd"

$NGHTTP2_VERSION = "1.41.0"
$NGHTTP2_HASH = "3d53e8bd1513a271a45b6ecda2e22fa05e9eb90fa92f7c5daf57b08c6e40cc55"

# We use tar.gz because Windows tar not support tar.xz
$CURL_VERSION = "7.74.0"
$CURL_HASH = "e56b3921eeb7a2951959c02db0912b5fcd5fdba5aca071da819e1accf338bbd7"

# Filename
$ZLIB_FILENAME = "zlib-${ZLIB_VERSION}"
$ZLIB_URL = "https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz"
#$ZLIB_URL = "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"

$OPENSSL_URL = "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
$OPENSSL_FILE = "openssl-${OPENSSL_VERSION}"

$BROTLI_URL = "https://github.com/google/brotli/archive/v${BROTLI_VERSION}.tar.gz"
$BROTLI_FILE = "brotli-${BROTLI_VERSION}"

$NGHTTP2_URL = "https://github.com/nghttp2/nghttp2/archive/v${NGHTTP2_VERSION}.tar.gz"
$NGHTTP2_FILE = "nghttp2-${NGHTTP2_VERSION}"

$LIBSSH2_URL = "https://www.libssh2.org/download/libssh2-${LIBSSH2_VERSION}.tar.gz"
$LIBSSH2_FILE = "libssh2-${LIBSSH2_VERSION}"

$CURL_URL = "https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz"
$CURL_FILE = "curl-${CURL_VERSION}"

#curl-ca-bundle
$CA_BUNDLE_URL = "https://curl.haxx.se/ca/cacert-2020-10-14.pem"

Function DumpLocal {
    $dumptext = $ZLIB_VERSION + $ZLIB_HASH + $ZLIB_FILENAME + $ZLIB_URL 
    + $OPENSSL_HASH + $OPENSSL_URL + $OPENSSL_FILE
    + $BROTLI_HASH + $BROTLI_URL + $BROTLI_FILE 
    + $NGHTTP2_HASH + $NGHTTP2_URL + $NGHTTP2_FILE 
    + $LIBSSH2_HASH + $LIBSSH2_URL + $LIBSSH2_FILE
    + $CURL_HASH + $CURL_FILE + $CURL_URL + $CA_BUNDLE_URL
    Write-Host $dumptext
}

Write-Host -ForegroundColor Cyan "zlib: $ZLIB_VERSION $ZLIB_HASH
openssl: $OPENSSL_VERSION $OPENSSL_HASH
brotli: $BROTLI_VERSION
libssh2: $LIBSSH2_VERSION
nghttp2: $NGHTTP2_VERSION
curl: $CURL_VERSION"
