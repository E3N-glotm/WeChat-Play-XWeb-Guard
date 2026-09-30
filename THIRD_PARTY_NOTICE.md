# Third-party binary notice

WeChat Play XWeb Guard v1.2.0 includes an XWeb 1160289 static runtime snapshot
in its release package so recovery works immediately after installation.

The bundled snapshot is stored in the repository through Git LFS:

`module/assets/core_1160289.tar`

SHA256:

`09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619`

The archive contains only the following static runtime entries:

```text
apk/base.apk
extracted_xwalkcore/
extracted_xwalkcore/dummy.dat
extracted_xwalkcore/libxwebcore.so
extracted_xwalkcore/libWXAMSDK.so
extracted_xwalkcore/libffmpeg.so
extracted_xwalkcore/media_player_extension.apk
extracted_xwalkcore/filelist.config
extracted_xwalkcore/reslist.config
zip/base.zip
```

It does not contain WeChat chats, account records, cookies, browsing history,
WebView profile data, FCM credentials, or the `MicroMsg` directory.

The repository maintainer, E3N, has stated that they hold authorization to
publicly redistribute these XWeb binary files. Their inclusion does not imply
affiliation with or endorsement by Tencent, WeChat, Google, or Xiaomi.
