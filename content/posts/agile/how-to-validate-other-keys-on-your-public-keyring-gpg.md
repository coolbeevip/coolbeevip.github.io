---
title: "如何验证公钥环上的其他密钥 - GnuPG"
date: 2022-05-11T00:24:14+08:00
tags: []
categories: [gpg]
draft: true
---

当我成为 ASF 项目发布经理后，遵循 ASF 项目发布流程，我需要[Generate a new key](https://infra.apache.org/openpgp.html#generate-key)，然后对要发布的文件进行签名。最后要发布的文件以及签名文件发布出去

作为文件的使用人员，通常我们先校验签名，以确保这个文件有正确的来源，就想下边看起来一样

```shell
$ gpg --verify apache-servicecomb-pack-distribution-0.7.0-bin.zip.asc apache-servicecomb-pack-distribution-0.7.0-bin.zip
gpg: 签名建立于 四  5/12 10:16:58 2022 CST
gpg:               使用 RSA 密钥 F07544CB36B8E954734C22DFCEC8F20C94850063
gpg: 完好的签名，来自于 “Lei Zhang <zhanglei@apache.org>” [绝对]
```

但是有的时候验证签名你会看到 `WARNING: This key is not certified with a trusted signature!`，这表示我的公钥并没有增加到验证者的信任链中

```shell
gpg: 签名建立于 四  5/12 10:16:58 2022 CST
gpg:               使用 RSA 密钥 F07544CB36B8E954734C22DFCEC8F20C94850063
gpg: 完好的签名，来自于 “Lei Zhang <zhanglei@apache.org>” [绝对]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: (a fingerprint)
     Subkey fingerprint: (a fingerprint)
```     

如果你信任来自于 `Lei Zhang <zhanglei@apache.org>` 签名指纹 `F07544CB36B8E954734C22DFCEC8F20C94850063`，那么这个文件就是合法的。
你也可以与发布人互签建立信任关系，这样你再验证这个发布人的签名时将不会再收到警告。

## 信任密钥的所有者

如果您相信这个签名文件的发布人的的公钥确实属于该个人并且他们在您的密钥环中，您可以使用您的私钥来签署您的通信者的公钥并对其进行验证。

所以你是 Bob，你相信 Alice 的公钥确实属于 Alice，所以你用你的私钥签名。所以 Alice 的密钥对你是信任的。此外，Alice 信任的任何密钥，比如一个叫 Chris 的人也将在您的信任网络中。所以你也可以信任 Chris，因为 Alice 信任。因此 Chris 的密钥将通过可信签名进行认证

虽然这不是必须的，但是你可以与他人建立信任关系 [Validating other keys on your public keyring](https://www.gnupg.org/gph/en/manual/x334.html)

信任是主观的。例如，Blake 的密钥在 Alice 签名后对 Alice 有效，但她可能不相信 Blake 能够正确验证他签名的密钥。在那种情况下，她不会仅根据 Blake 的签名就认为 Chloe 和 Dharma 的密钥是有效的。信任网络模型通过与密钥环上的每个公钥相关联来说明您对密钥所有者的信任程度。有四个信任级别。
