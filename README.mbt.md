# moonsic

用 MoonBit 写旋律，导出 MIDI，在浏览器播放。

## v1.5 最小示例

```moonbit nocheck
///|
let lead = melody([
  n(c(4), quarter()),
  n(d(4), quarter()),
  n(e(4), quarter()),
  n(g(4), dotted(quarter())),
  r(eighth()),
  n(c(5), half()),
])

///|
let harmony = melody([major(c(3), half()), minor(a(3), half())])

///|
let song = score_with([lead, harmony], 120, four_four())

///|
let bytes = song.to_midi_bytes()
// bytes 可写入 .mid 文件
```

v1 风格的完整构造器仍然可用，但推荐用 v1.5 快捷 API。

## 浏览器播放

```bash
moon run cmd/main > web/demo-events.js  # 生成 moonsic 数据
py -m http.server 8000 -d web            # 启服务器
# 打开 http://localhost:8000，点击 Play
```

demo 优先使用 moonsic 生成的数据，无数据时回退到硬编码旋律。

## 命令行

```bash
moon run cmd/main    # 生成浏览器 demo 数据
moon test            # 50 tests
moon fmt             # 格式化
moon info            # 更新接口文件
```

## API 速览

### 音高快捷构造
| 函数 | 结果 | MIDI |
|------|------|------|
| `c(4)` | C4 | 60 |
| `d(4)` | D4 | 62 |
| `e(4)` | E4 | 64 |
| `f(4)` | F4 | 65 |
| `g(4)` | G4 | 67 |
| `a(4)` | A4 | 69 |
| `b(4)` | B4 | 71 |
| `cs(4)` | C#4 | 61 |
| `db(4)` | Db4 | 61 |
| `eb(4)` | Eb4 | 63 |
| `bb(4)` | Bb4 | 70 |
| `pitch(C, Natural, 4)` | 完整构造器 | — |
| `natural_pitch(C, 4)` | 自然音高 | 60 |

### 时值
| 函数 | 拍数 |
|------|------|
| `whole()` | 4.0 |
| `half()` | 2.0 |
| `quarter()` | 1.0 |
| `eighth()` | 0.5 |
| `sixteenth()` | 0.25 |
| `dotted(quarter())` | 1.5 |
| `dotted(half())` | 3.0 |

### 事件
| 函数 | 说明 |
|------|------|
| `n(c(4), quarter())` | 快捷音符 |
| `nv(c(4), quarter(), 64)` | 指定力度 |
| `r(half())` | 快捷休止 |
| `major(c(3), half())` | 大三和弦 C E G |
| `minor(a(3), half())` | 小三和弦 A C E |
| `ch([c(4),e(4),g(4)], quarter())` | 自定义和弦 |

### 轨道与乐谱
| 函数 | 说明 |
|------|------|
| `melody([...])` | 快捷轨道 |
| `score1(track)` | 单轨道乐谱 (120 BPM, 4/4) |
| `score_with([tracks], 120, four_four())` | 指定速度拍号 |

## 项目结构

```
core.mbt     — 核心音乐模型
runtime.mbt  — 事件运行时 + 浏览器数据导出
midi.mbt     — 频率转换 + MIDI 导出
helpers.mbt  — v1.5 作曲快捷函数
web/         — 浏览器播放 demo
cmd/main/    — CLI（生成浏览器 demo 数据）
```
