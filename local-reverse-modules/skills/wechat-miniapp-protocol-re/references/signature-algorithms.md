# 签名算法公式与验证样本

## sign 头（所有接口）
```
sign = md5( md5( url + "axjalsdjfsfa" + ts + "axjalsdjfsfa" + token ) )
```
- url = 完整 URL（含 https:// 域名/路径/query）
- ts = 秒级时间戳整数
- token = 用户 token

## req-id 头

### 普通接口
```
req-id = md5( md5( "tuyang2020" + path + "tuyang2020" + token + ts8 ) )
```
- path = URL 路径部分（不含域名），如 `/lottery/homeRecommend`
- ts8 = `str(秒时间戳)[:-2]`（百秒粒度）

### h5Urls 特殊接口
```
req-id = md5( md5( O + path + O + d + token + ts8 ) )
```
- O = `"function(a){return function(b){return c}}"`（固定串）
- d = `md5( O + 排序拼接 + O ).toUpperCase()`（大写！）
- 排序拼接：按 key 字典序拼接 `key+value`，对象/数组用 `JSON.stringify`

### d 的排序拼接规则
```python
c = {**body, 'ts': ts8, 's': O, 'f': 'json', 'v': '1.0', 't': token}
keys = sorted(k for k in c if c[k] is not None)
parts = []
for k in keys:
    val = c[k]
    if isinstance(val, (list, dict)):
        parts.append(k + json.dumps(val, ensure_ascii=False, separators=(',',':')))
    else:
        parts.append(k + str(val))
拼接 = ''.join(parts)
d = md5(O + 拼接 + O).upper()
```

### h5Urls 白名单
```
/v2/lottery/join
/api/v2/stat/userProfile
/v2/user/authCaptcha/post
/v2/user/authCaptcha/get
/v2/lotteries/getPlayingMultiple
```

## 验证样本（3/3 命中）

| 样本 | 路径 | ts | 计算 req-id | 目标 req-id | 结果 |
|------|------|-----|------------|------------|------|
| 1 | /api/v2/stat/userProfile | 1787674362 | ea547e3d96be3137c6bbe407ced52e34 | ea547e3d96be3137c6bbe407ced52e34 | ✅ |
| 2 | /api/v2/stat/userProfile | 1787674512 | 120cd697d56297ca4c1d11b71ffa103f | 120cd697d56297ca4c1d11b71ffa103f | ✅ |
| 3 | /api/v2/stat/userProfile | 1787675171 | 2f820549c8c333399faf50bcdeee6c04 | 2f820549c8c333399faf50bcdeee6c04 | ✅ |