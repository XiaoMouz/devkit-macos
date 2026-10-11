# 已使用的大样本生成说明

> 归档说明：本文件保留验收结论。截图、日志、采样和中间产物已移至仓库外；“归档”路径相对于原报告所在目录。详见[资料管理说明](../../../README.md)。

以下仅记录实际验收样本的构造，不是待执行测试用例，也不会构建或启动 DevKit。

- exact-5m.txt：ASCII a 重复 5,242,880 次；over-5m.txt 再增加 1 字节。
- exact-32m.bin：ASCII a 重复 33,554,432 次；over-limit-33m.bin 为 33 MiB。
- large-minify.js：i 从 0 到 29,999，每行是 function synthetic_i(value) { const extra = i; return value + extra; }，其中 i 替换为十进制索引；行间 LF，末尾无 LF。实测 2,347,779 字节。
- dataurl-max.png / dataurl-over.png：以本目录 one-pixel.png 为基础，在末尾 IEND 块前插入一个合法 tEXt 块。payload 为 ASCII pad + NUL + 若干 ASCII a；写入 4 字节大端 payload 长度、tEXt 类型、payload、类型加 payload 的 CRC32。完整文件长度分别为 3,932,142 / 3,932,143。标准 Base64 加 data:image/png;base64, 头后分别为 5,242,878 / 5,242,882 字节。
- multi-qr-fixture.png：由同目录 multi-qr-fixture.swift 独立生成两个合成 QR，内容为 DevKit multi QR alpha 和 DevKit multi QR beta 中文。脚本只生成测试图片，不链接 DevKit 或启动 App。真实扫描在 DevKit UI 中执行。
- oriented-6.jpg：在 UI 导出的合成 JPEG 中移除原 APP1，再插入 EXIF TIFF：Orientation=6、ImageDescription=DevKit synthetic metadata。实际由图片信息 UI 确认该标签，然后保存去元数据 PNG 并重新导入检查。

文件字节数和 SHA-256 以 fixture-manifest.json / fixture-manifest-resumed.json 为准。大文件未重复放入仓库；完整 Data URL 导出在本地 /tmp/devkit-acceptance-fixtures/expanded-dataurl-max.txt，已独立解码并逐字节比对。
