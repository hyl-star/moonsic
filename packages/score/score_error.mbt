// ============================================================
// ScoreError — v2 Score 包统一错误类型
// ============================================================

///|
pub(all) enum ScoreError {
  InvalidId(String)
  InvalidMeasure(String)
  InvalidPart(String)
  InvalidStaff(String)
  InvalidVoice(String)
  InvalidEvent(String)
  InvalidSection(String)
  InvalidRepeat(String)
  InvalidEnding(String)
  InvalidTempo(String)
  InvalidPPQ(String)
  InvalidVelocity(String)
  InvalidChannel(String)
  InvalidProgram(String)
  InvalidNotation(String)
  InvalidLyric(String)
  InvalidClef(String)
  InvalidBarline(String)
  InvalidScorePath(String)
  UnsupportedScoreFeature(String)
}

///|
pub fn ScoreError::to_string(self : ScoreError) -> String {
  match self {
    InvalidId(msg) => "无效ID：\{msg}"
    InvalidMeasure(msg) => "无效小节：\{msg}"
    InvalidPart(msg) => "无效声部组：\{msg}"
    InvalidStaff(msg) => "无效五线谱：\{msg}"
    InvalidVoice(msg) => "无效声部：\{msg}"
    InvalidEvent(msg) => "无效事件：\{msg}"
    InvalidSection(msg) => "无效段落：\{msg}"
    InvalidRepeat(msg) => "无效反复：\{msg}"
    InvalidEnding(msg) => "无效终止：\{msg}"
    InvalidTempo(msg) => "无效速度：\{msg}"
    InvalidPPQ(msg) => "无效PPQ：\{msg}"
    InvalidVelocity(msg) => "无效力度：\{msg}"
    InvalidChannel(msg) => "无效通道：\{msg}"
    InvalidProgram(msg) => "无效乐器：\{msg}"
    InvalidNotation(msg) => "无效记号：\{msg}"
    InvalidLyric(msg) => "无效歌词：\{msg}"
    InvalidClef(msg) => "无效谱号：\{msg}"
    InvalidBarline(msg) => "无效小节线：\{msg}"
    InvalidScorePath(msg) => "无效乐谱路径：\{msg}"
    UnsupportedScoreFeature(msg) => "不支持：\{msg}"
  }
}
