sigstore

## cosign


在 macOS 安装 cosign, 其他安装方式参见[more](https://docs.sigstore.dev/cosign/installation/)

```shell
brew install cosign
```

查看 cosign 版本


```shell
% cosign -version
WARNING: the -version flag is deprecated and will be removed in a future release. Please use the version subcommand instead.
  ______   ______        _______. __    _______ .__   __.
 /      | /  __  \      /       ||  |  /  _____||  \ |  |
|  ,----'|  |  |  |    |   (----`|  | |  |  __  |   \|  |
|  |     |  |  |  |     \   \    |  | |  | |_ | |  . `  |
|  `----.|  `--'  | .----)   |   |  | |  |__| | |  |\   |
 \______| \______/  |_______/    |__|  \______| |__| \__|
cosign: A tool for Container Signing, Verification and Storage in an OCI registry.

GitVersion:    1.10.1
GitCommit:     a39ce91fadc582e0efce3321744a79ccd3c8b39c
GitTreeState:  "clean"
BuildDate:     2022-08-04T16:59:14Z
GoVersion:     go1.18.5
Compiler:      gc
Platform:      darwin/arm64
````

生成一个 keypair (password:18610099300)

```shell
$ cosign generate-key-pair
Enter password for private key:
Enter password for private key again:
Private key written to cosign.key
Public key written to cosign.pub
```

