####

$ZLIB_VERSION = "1.2.11"
$ZLIB_HASH = "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff"

$OPENSSL_VERSION = "1.1.1d"
$OPENSSL_HASH = "1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2"

$BROTLI_VERSION = "1.0.7"
$BROTLI_HASH = "4c61bfb0faca87219ea587326c467b95acb25555b53d1a421ffa3c8a9296ee2c"

$LIBSSH2_VERSION = "1.8.2"
$LIBSSH2_HASH = "088307d9f6b6c4b8c13f34602e8ff65d21c2dc4d55284dfe15d502c4ee190d67"

$NGHTTP2_VERSION = "1.39.2"
$NGHTTP2_HASH = "485daaa0ada7da8b4d1c2c789e7ffbe7d037763f672efa0809699d4000db265b"

$CURL_VERSION = "7.66.0"
$CURL_HASH = "d0393da38ac74ffac67313072d7fe75b1fa1010eb5987f63f349b024a36b7ffb"

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
$CA_BUNDLE_URL = "https://curl.haxx.se/ca/cacert-2019-10-16.pem"

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
