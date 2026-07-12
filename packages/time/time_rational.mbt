//
// 有理数 Rational — 精确的分数表示
//

///|
/// 有理数 = 分子/分母（自动约分，分母恒正）
pub(all) struct Rational {
  numerator : Int
  denominator : Int
}

///|
/// 创建有理数，分母必须 > 0，自动约分
pub fn rational(n : Int, d : Int) -> Result[Rational, TimeError] {
  if d <= 0 {
    return Err(InvalidRational("分母必须 > 0，当前：\{d}"))
  }
  let (n_red, d_red) = reduce_frac(n, d)
  Ok({ numerator: n_red, denominator: d_red })
}

///|
/// 内部：不验证、已约分的直接构造
fn rational_raw(n : Int, d : Int) -> Rational {
  let (n_red, d_red) = reduce_frac(n, d)
  { numerator: n_red, denominator: d_red }
}

///|
/// 约分（gcd，确保分母为正）
fn reduce_frac(n : Int, d : Int) -> (Int, Int) {
  let g = gcd(if n < 0 { -n } else { n }, if d < 0 { -d } else { d })
  let num = n / g
  let den = d / g
  if den < 0 {
    (-num, -den)
  } else {
    (num, den)
  }
}

///|
/// 最大公约数（欧几里得算法）
fn gcd(a : Int, b : Int) -> Int {
  let mut x = a
  let mut y = b
  while y != 0 {
    let t = y
    y = x % y
    x = t
  }
  x
}

///|
/// 有理数加法：a + b
pub fn rational_add(a : Rational, b : Rational) -> Rational {
  let n = a.numerator * b.denominator + b.numerator * a.denominator
  let d = a.denominator * b.denominator
  rational_reduce({ numerator: n, denominator: d })
}

///|
/// 有理数减法：a - b
pub fn rational_sub(a : Rational, b : Rational) -> Rational {
  let n = a.numerator * b.denominator - b.numerator * a.denominator
  let d = a.denominator * b.denominator
  rational_reduce({ numerator: n, denominator: d })
}

///|
/// 有理数乘法：a * b
pub fn rational_mul(a : Rational, b : Rational) -> Rational {
  let n = a.numerator * b.numerator
  let d = a.denominator * b.denominator
  rational_reduce({ numerator: n, denominator: d })
}

///|
/// 有理数除法：a / b（b 的分子不能为 0）
pub fn rational_div(a : Rational, b : Rational) -> Result[Rational, TimeError] {
  if b.numerator == 0 {
    return Err(InvalidRational("除数为 0"))
  }
  let n = a.numerator * b.denominator
  let d = a.denominator * b.numerator
  Ok(rational_reduce({ numerator: n, denominator: d }))
}

///|
/// 约分有理数
fn rational_reduce(r : Rational) -> Rational {
  let (n, d) = reduce_frac(r.numerator, r.denominator)
  { numerator: n, denominator: d }
}

///|
/// 判断有理数是否为整数
pub fn rational_is_integer(v : Rational) -> Bool {
  v.numerator % v.denominator == 0
}

///|
/// 有理数转为 Int（仅当为整数时成功）
pub fn rational_to_int(v : Rational) -> Result[Int, TimeError] {
  if rational_is_integer(v) {
    Ok(v.numerator / v.denominator)
  } else {
    Err(
      NonIntegralTick("有理数 \{v.numerator}/\{v.denominator} 不是整数"),
    )
  }
}

///|
/// 有理数转为 Double
pub fn rational_to_double(v : Rational) -> Double {
  v.numerator.to_double() / v.denominator.to_double()
}

///|
/// 有理数转为字符串
pub fn Rational::to_string(self : Rational) -> String {
  "\{self.numerator}/\{self.denominator}"
}
