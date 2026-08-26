# Mirasim 补丁串快照 — 可执行清单

> ⚠️ **版本快照（会过期）**：以下补丁串截至 2026-08-26 的逆向结果。  
> 每次 Mirasim 更新后，minified 函数名可能变化，补丁串需重新逆向。  
> 若发现不匹配，请按 MODULE.md 中"逆向新版本挂载点"流程重新提取。

## 诊断流程

```
用户反馈"更新后失效"
  ├─ 看 history.jsonl 的 won:false / 异常 reward
  ├─ 确认 @mirasimdesktop 下所有候选副本的 mtime
  ├─ 特征扫描（arcade-cabinet / facingRaise / 48e3）找出扑克 renderer
  ├─ 检查 payload.json 的 minShellAbi 与 shell ABI 匹配 → 真正加载版本
  └─ 对真正加载的副本逆向新挂载点 → 打补丁 → 验证指纹
```

## 运行补丁

```powershell
cd <项目目录>
node tools/instawin.mjs      # 自动多目标打补丁
node tools/godmode_bot.mjs --instawin   # 启动
```

## 补丁验证指纹

补丁后应确认以下指纹（在目标 renderer 中 grep）：
- `window.__arc` 出现 3 次（透视挂载点）
- `window.__plan` 出现 1 次（匹配计划挂载）
- 奖金常量已替换为 `x=48e5`（x 为当前版本变量名）
- `return"fold"` 出现 1 次（机器人永弃）
- 弃牌系数 `e.byFold?1:1` 出现 1 次
- 匹配延迟 `<X>=150` 出现 1 次（X 为当前版本变量名）
- 秒结算 `<A>=1` 出现 1 次（A 为当前版本动画常量名）
- 加注满档 `6*.45` 出现 1 次

## 各版本已知补丁串（历史快照，仅供参考）

### 透视挂载点（4 处）

| 功能 | 示例版本（v0.0.230） | 其他已知变体 |
|---|---|---|
| ①开新局 | `g(SG(h,s))` | `m(mH(h,s))`, `m(iG(h,s))`, `x(eK(h,s))` |
| ②匹配计划 | `f(uG())` | `f(eH())`, `f(qq())`, `f(Fz())` |
| ③机器人行动 | `g(O=>O&&(RG(O)??O))` | `m($=>$&&(vH($)??$))`, `m(B=>B&&(uG(B)??B))` |
| ④玩家行动 | `g(D=>D&&Oc(D)?G3(D,cn,R):D)` | `m(F=>F&&vl(F)?Dw(F,Ft,R):F)`, `m(D=>D&&Dc(D)?A3(D,pn,A):D)` |

### 必胜补丁串

| 功能 | 示例版本 | 其他已知变体 |
|---|---|---|
| 机器人永弃 | `function NG(e){...}` | `fH`, `aG`, `Zz`, `$H` |
| 奖金 x100 | `z3=48e3` | `Lw=48e3`, `E3=48e3`, `Zj=48e3` |
| 匹配加速 | `P1=5e3,dG=1e4` | `D0=5e3,QW=1e4`, `j1=5e3,Uq=1e4` |
| 动画秒结算 | `const HG=820,WG=700,KG=1200` | `const RH=820,AH=700,LH=1200`, `yG=820,jG=700,NG=1200` |
| 弃牌不打折 | `e.byFold?.7:1`（各版通用） | — |
| 4人桌 | `r=t()<.5?3:4`（各版通用） | 补丁后 `r=4` |
| 加注满档 | `Math.min(e.raises,6)`（各版通用） | — |

### 幂等指纹（already 检测）

| 功能 | 补丁后指纹 |
|---|---|
| 4人桌 | `r=4,a=cG(r-1,t)` 或 `r=4,a=Kq(r-1,t)` 或 `r=4,a=_z(r-1,n)` 或 `r=4,o=ZW(r-1,t)` |
| 加注满档 | `raises:1+6*.45` |

## 还原方法

```powershell
# 各目标还原备份
copy /y "<目标文件>.orig.bak" "<目标文件>"
```