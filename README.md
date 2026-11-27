
# NGINX NTLM Builder

Automated builds of NGINX Stable with
Securepoint nginx-ntlm-modulev2.

## Supported platforms

- Ubuntu Linux x64
- Windows x64

## Features

- Latest NGINX Stable detection
- Custom NGINX version
- Custom NTLM branch, tag or commit
- Static NTLM module
- OpenSSL, PCRE2 and Zlib
- Source checksum verification
- Configuration validation
- SHA256 release checksums
- Automated GitHub Releases

## How to build

1. Open the Actions tab.
2. Select Build NGINX NTLM.
3. Click Run workflow.
4. Select the target platform.
5. Select NGINX version and NTLM ref.
6. Click Run workflow.
7. Download packages from Releases or Artifacts.

## Build outputs

- nginx-VERSION-ntlm-linux-x64.tar.gz
- nginx-VERSION-ntlm-windows-x64.zip
- SHA256 checksum files

## Upstream projects

- https://nginx.org/
- https://github.com/Securepoint/nginx-ntlm-modulev2

## Disclaimer

This is an unofficial build automation project.
Test authentication and session isolation before
production deployment.
