# Multi-EasyGost一键脚本使用指南
***
## 感谢: 
1. 感谢 @ginuerzh 大佬开发的 [gost](https://github.com/ginuerzh/gost) 隧道程序 ，功能强大使用简单，想要详细了解的朋友可以查看[官方文档](https://docs.ginuerzh.xyz/gost/)
2. 感谢 @风萧萧兮易水寒 大佬的[原始脚本](https://www.fiisi.com/?p=125)
3. 感谢 @ STSDUST 提供的EasyGost脚本（已删库），此脚本是基于其进行修改增强
***
## 简介

> 项目地址及帮助文档:  
> https://github.com/KANIKIG/Multi-EasyGost
***
## 脚本

* 启动脚本  
  `wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/WuMe-sicx/Gost/v2/gost.sh && chmod +x gost.sh && ./gost.sh`  
* 再次运行本脚本只需要输入`./gost.sh`回车即可  

> 注：本分支跟随 [ginuerzh/gost](https://github.com/ginuerzh/gost) 官方最新发行版（当前 v2.12.0，安装时自动获取最新版本）。gost 2.12.0 起官方改用 tar.gz 打包，脚本已适配。

## 镜像加速（可选）

国内机器直连 GitHub 较慢时，可用 Cloudflare R2（免流出费、无需备案）做下载镜像：

1. 用 `tools/upload-r2.sh <bucket>` 把各架构的 gost 发行包与 `gost.service`/`config.json`/`gost.sh` 上传到 R2（脚本头部有一次性配置说明）。
2. 给 R2 存储桶绑定一个公开自定义域名。
3. 在 `gost.sh` 顶部把 `R2_MIRROR` 设为该域名（如 `R2_MIRROR="https://mirror.example.com"`）。

设置后安装时会询问是否走镜像，脚本自更新也会优先使用镜像；留空则始终走 GitHub。

## 功能

### 原脚本功能

- 实现了systemd及gost配置文件对gost进行管理
- 在不借助其他工具(如screen)的情况下实现多条转发规则同时生效
- 机器reboot后转发不失效
- 支持传输类型：
  - tcp+udp不加密转发
  -  relay+tls加密

### 此脚本新增功能

- 增加了传输类型选择功能
- 新支持传输类型
  - relay+ws
  - relay+wss
  - relay+mtls / relay+mws / relay+mwss（多路复用，高并发更省连接，mwss 适合 CDN 场景）
- 落地机一键创建ss/socks5/http代理 (gost内置)
- 落地机一键创建 ss over ws/mws/wss/mwss（菜单[7]，兼容 mihomo/Clash.Meta，见下方对接表）
- 支持多传输类型的多落地简单型均衡负载
- 可选 Cloudflare R2 下载镜像（见上方「镜像加速」，免流出费、无需备案）
- 简单创建或删除gost定时重启任务
- 脚本自动检查更新
- 转发CDN自选节点ip
- 支持自定义tls证书，落地可一键申请证书，中转可开启证书校验

## 客户端对接 mihomo / Clash.Meta（菜单[7] ss over ws/mws/wss/mwss）

落地机用菜单[7]创建后，客户端按下表填 `plugin: gost-plugin`，`path` 固定为 `/`：

| 落地选择 | 服务端节点 | mihomo `plugin-opts` |
|---|---|---|
| ss+ws | `ss+ws://cipher:pw@:port?path=/` | `mode: websocket, path: /` |
| ss+mws | `ss+mws://…?path=/` | `mode: websocket, path: /, mux: true` |
| ss+wss | `ss+wss://…?path=/` | `mode: websocket, path: /, tls: true` |
| ss+mwss | `ss+mwss://…?path=/` | `mode: websocket, path: /, tls: true, mux: true` |

```yaml
proxies:
  - name: gost-ss
    type: ss
    server: your.domain.com   # 套 CDN 时填 CDN 域名
    port: 443
    cipher: aes-256-gcm       # 与落地一致；AEAD_CHACHA20_POLY1305 在此写 chacha20-ietf-poly1305
    password: "your-pw"
    plugin: gost-plugin
    plugin-opts: { mode: websocket, path: /, tls: true, mux: true }  # 对应 ss+mwss
    # 用脚本内置自签证书时加 skip-cert-verify: true；自定义证书填对应域名即可
```

> gost 的 mux 用的是 xtaci/smux，与 v2ray-plugin 的 mux 不兼容，`m` 开头的务必用 `gost-plugin`（不是 `v2ray-plugin`）。

## 功能展示

![iShot2020-12-14下午05.42.23.png](https://i.loli.net/2020/12/14/q75PO6s2DMIcUKB.png)

![iShot2020-12-14下午05.42.39.png](https://i.loli.net/2020/12/14/vzpGlWmPtCrneOY.png)

![2](https://i.loli.net/2020/10/16/fBHgwStVQxc821z.png)

![3](https://i.loli.net/2020/10/16/xgZ6eVAwSzDUFjO.png)

![4](https://i.loli.net/2020/10/16/lt6uAzI5X7yYWhr.png)

![iShot2020-12-14下午05.43.46.png](https://i.loli.net/2020/12/14/YjiFTMCKs8lANbI.png)

![iShot2020-12-14下午05.43.11.png](https://i.loli.net/2020/12/14/VIcQSsoUaqpzx5T.png)
