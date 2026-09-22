import CoreGraphics
import Vision

enum LandmarkRegion: String, CaseIterable, Hashable {
  case leftEye, rightEye
  case leftEyebrow, rightEyebrow
  case nose, noseCrest
  case outerLips, innerLips
  case faceContour, medianLine
}

struct LandmarkPoint {
  let point: CGPoint
  let region: LandmarkRegion
  let indexInRegion: Int
}

nonisolated enum LandmarkGeometry {
  static func imagePoints(of region: VNFaceLandmarkRegion2D, imageSize: CGSize) -> [CGPoint] {
    region.pointsInImage(imageSize: imageSize).map { CGPoint(x: $0.x, y: imageSize.height - $0.y) }
  }

  static func centroid(of region: VNFaceLandmarkRegion2D, imageSize: CGSize) -> CGPoint? {
    let points = imagePoints(of: region, imageSize: imageSize)
    guard !points.isEmpty else { return nil }
    let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
    return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
  }

  static func eyeCenter(
    pupil: VNFaceLandmarkRegion2D?, eye: VNFaceLandmarkRegion2D?, imageSize: CGSize
  ) -> CGPoint? {
    if let pupil, let center = centroid(of: pupil, imageSize: imageSize) { return center }
    if let eye { return centroid(of: eye, imageSize: imageSize) }
    return nil
  }

  static func interocularDistance(from landmarks: VNFaceLandmarks2D, imageSize: CGSize) -> CGFloat?
  {
    guard
      let left = eyeCenter(
        pupil: landmarks.leftPupil, eye: landmarks.leftEye, imageSize: imageSize),
      let right = eyeCenter(
        pupil: landmarks.rightPupil, eye: landmarks.rightEye, imageSize: imageSize)
    else { return nil }
    return hypot(left.x - right.x, left.y - right.y)
  }

  private static func boundingBoxAspectRatio(of region: VNFaceLandmarkRegion2D, imageSize: CGSize)
    -> CGFloat?
  {
    let points = imagePoints(of: region, imageSize: imageSize)
    guard points.count >= 3, let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
      let minY = points.map(\.y).min(), let maxY = points.map(\.y).max()
    else { return nil }
    let width = maxX - minX
    guard width > 0 else { return nil }
    return (maxY - minY) / width
  }

  static func eyeAspectRatio(of eyeRegion: VNFaceLandmarkRegion2D, imageSize: CGSize) -> CGFloat? {
    boundingBoxAspectRatio(of: eyeRegion, imageSize: imageSize)
  }

  static func region(_ region: LandmarkRegion, of landmarks: VNFaceLandmarks2D)
    -> VNFaceLandmarkRegion2D?
  {
    switch region {
    case .leftEye: return landmarks.leftEye
    case .rightEye: return landmarks.rightEye
    case .leftEyebrow: return landmarks.leftEyebrow
    case .rightEyebrow: return landmarks.rightEyebrow
    case .nose: return landmarks.nose
    case .noseCrest: return landmarks.noseCrest
    case .outerLips: return landmarks.outerLips
    case .innerLips: return landmarks.innerLips
    case .faceContour: return landmarks.faceContour
    case .medianLine: return landmarks.medianLine
    }
  }

  static func allPoints(from landmarks: VNFaceLandmarks2D, imageSize: CGSize) -> [LandmarkPoint] {
    var result: [LandmarkPoint] = []
    for regionCase in LandmarkRegion.allCases {
      guard let vnRegion = region(regionCase, of: landmarks) else { continue }
      let points = imagePoints(of: vnRegion, imageSize: imageSize)
      for (index, point) in points.enumerated() {
        result.append(LandmarkPoint(point: point, region: regionCase, indexInRegion: index))
      }
    }
    return result
  }

  struct Homography {
    let h11, h12, h13, h21, h22, h23, h31, h32, h33: CGFloat

    func apply(_ point: CGPoint) -> CGPoint {
      let w = h31 * point.x + h32 * point.y + h33
      guard abs(w) > 1e-12 else { return point }
      return CGPoint(
        x: (h11 * point.x + h12 * point.y + h13) / w,
        y: (h21 * point.x + h22 * point.y + h23) / w
      )
    }
  }

  static func solveHomography(
    from sourcePoints: [CGPoint], to destinationPoints: [CGPoint], weights: [CGFloat]? = nil
  ) -> Homography? {
    guard sourcePoints.count == destinationPoints.count, sourcePoints.count >= 4 else { return nil }
    if let weights {
      guard weights.count == sourcePoints.count else { return nil }
    }

    guard let srcT = normalizingTransform(sourcePoints),
      let dstT = normalizingTransform(destinationPoints)
    else { return nil }

    let n = sourcePoints.count
    var ata = Array(repeating: Array(repeating: CGFloat(0), count: 8), count: 8)
    var atb = Array(repeating: CGFloat(0), count: 8)

    for i in 0..<n {
      let src = applyNormalization(sourcePoints[i], srcT)
      let dst = applyNormalization(destinationPoints[i], dstT)
      let w = (weights?[i] ?? 1).squareRoot()
      guard w > 0 else { continue }
      let x = src.x
      let y = src.y
      let u = dst.x
      let v = dst.y
      let row0: [CGFloat] = [x * w, y * w, w, 0, 0, 0, -u * x * w, -u * y * w]
      let row1: [CGFloat] = [0, 0, 0, x * w, y * w, w, -v * x * w, -v * y * w]
      let b0 = u * w
      let b1 = v * w
      accumulateNormalEquations(row0, b0, into: &ata, atb: &atb)
      accumulateNormalEquations(row1, b1, into: &ata, atb: &atb)
    }

    guard let h = solveLinearSystem(ata, atb) else { return nil }
    let hNorm = Homography(
      h11: h[0], h12: h[1], h13: h[2],
      h21: h[3], h22: h[4], h23: h[5],
      h31: h[6], h32: h[7], h33: 1
    )
    return denormalizeHomography(hNorm, source: srcT, destination: dstT)
  }

  static func solveRobustHomography(from sourcePoints: [CGPoint], to destinationPoints: [CGPoint])
    -> Homography?
  {
    guard var current = solveHomography(from: sourcePoints, to: destinationPoints) else {
      return nil
    }
    for _ in 0..<2 {
      let residuals = zip(sourcePoints, destinationPoints).map {
        hypot($1.x - current.apply($0).x, $1.y - current.apply($0).y)
      }
      let scale = max(medianValue(residuals), 1e-4)
      let cutoff = 4.685 * 1.4826 * scale
      var weights: [CGFloat] = residuals.map { r in
        let u = r / cutoff
        if u >= 1 { return 0 }
        let t = 1 - u * u
        return t * t
      }
      let inliers = weights.filter { $0 > 0 }.count
      if inliers < 6 {
        weights = Array(repeating: 1, count: sourcePoints.count)
      }
      if let refined = solveHomography(from: sourcePoints, to: destinationPoints, weights: weights)
      {
        current = refined
      }
    }
    return current
  }

  private struct SimilarityNorm {
    let scale: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
  }

  private static func normalizingTransform(_ points: [CGPoint]) -> SimilarityNorm? {
    let n = CGFloat(points.count)
    guard n > 0 else { return nil }
    let cx = points.reduce(CGFloat(0)) { $0 + $1.x } / n
    let cy = points.reduce(CGFloat(0)) { $0 + $1.y } / n
    let meanDist = points.reduce(CGFloat(0)) { $0 + hypot($1.x - cx, $1.y - cy) } / n
    guard meanDist > 1e-8 else { return nil }
    return SimilarityNorm(scale: CGFloat(2).squareRoot() / meanDist, centerX: cx, centerY: cy)
  }

  private static func applyNormalization(_ point: CGPoint, _ t: SimilarityNorm) -> CGPoint {
    CGPoint(x: t.scale * (point.x - t.centerX), y: t.scale * (point.y - t.centerY))
  }

  private static func denormalizeHomography(
    _ h: Homography, source: SimilarityNorm, destination: SimilarityNorm
  ) -> Homography {
    let s1 = source.scale
    let cx1 = source.centerX
    let cy1 = source.centerY
    let s2 = destination.scale
    let cx2 = destination.centerX
    let cy2 = destination.centerY
    let ts = (
      s1, CGFloat(0), -s1 * cx1, CGFloat(0), s1, -s1 * cy1, CGFloat(0), CGFloat(0), CGFloat(1)
    )
    let hn = (h.h11, h.h12, h.h13, h.h21, h.h22, h.h23, h.h31, h.h32, h.h33)
    let m = multiply3x3(hn, ts)
    let ti = (1 / s2, CGFloat(0), cx2, CGFloat(0), 1 / s2, cy2, CGFloat(0), CGFloat(0), CGFloat(1))
    let r = multiply3x3(ti, m)
    return Homography(
      h11: r.0, h12: r.1, h13: r.2, h21: r.3, h22: r.4, h23: r.5, h31: r.6, h32: r.7, h33: r.8)
  }

  private static func multiply3x3(
    _ a: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat),
    _ b: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
  ) -> (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) {
    (
      a.0 * b.0 + a.1 * b.3 + a.2 * b.6,
      a.0 * b.1 + a.1 * b.4 + a.2 * b.7,
      a.0 * b.2 + a.1 * b.5 + a.2 * b.8,
      a.3 * b.0 + a.4 * b.3 + a.5 * b.6,
      a.3 * b.1 + a.4 * b.4 + a.5 * b.7,
      a.3 * b.2 + a.4 * b.5 + a.5 * b.8,
      a.6 * b.0 + a.7 * b.3 + a.8 * b.6,
      a.6 * b.1 + a.7 * b.4 + a.8 * b.7,
      a.6 * b.2 + a.7 * b.5 + a.8 * b.8
    )
  }

  private static func accumulateNormalEquations(
    _ row: [CGFloat], _ b: CGFloat, into ata: inout [[CGFloat]], atb: inout [CGFloat]
  ) {
    for i in 0..<8 {
      atb[i] += row[i] * b
      for j in 0..<8 {
        ata[i][j] += row[i] * row[j]
      }
    }
  }

  static func solveLinearSystem(_ matrix: [[CGFloat]], _ rhs: [CGFloat]) -> [CGFloat]? {
    let n = rhs.count
    guard matrix.count == n, matrix.allSatisfy({ $0.count == n }) else { return nil }
    var a = matrix
    var b = rhs
    for k in 0..<n {
      var pivot = k
      var maxVal = abs(a[k][k])
      if k + 1 < n {
        for i in (k + 1)..<n {
          let v = abs(a[i][k])
          if v > maxVal {
            maxVal = v
            pivot = i
          }
        }
      }
      if maxVal < 1e-12 { return nil }
      if pivot != k {
        a.swapAt(k, pivot)
        b.swapAt(k, pivot)
      }
      let diag = a[k][k]
      if k + 1 < n {
        for i in (k + 1)..<n {
          let factor = a[i][k] / diag
          for j in k..<n {
            a[i][j] -= factor * a[k][j]
          }
          b[i] -= factor * b[k]
        }
      }
    }
    var x = [CGFloat](repeating: 0, count: n)
    for i in stride(from: n - 1, through: 0, by: -1) {
      var sum = b[i]
      if i + 1 < n {
        for j in (i + 1)..<n {
          sum -= a[i][j] * x[j]
        }
      }
      guard abs(a[i][i]) > 1e-12 else { return nil }
      x[i] = sum / a[i][i]
    }
    return x
  }

  static func medianValue(_ values: [CGFloat]) -> CGFloat {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count.isMultiple(of: 2) {
      return (sorted[mid - 1] + sorted[mid]) / 2
    }
    return sorted[mid]
  }

  static func solveSimilarityTransform(
    from sourcePoints: [CGPoint], to destinationPoints: [CGPoint]
  ) -> CGAffineTransform? {
    guard sourcePoints.count == destinationPoints.count, sourcePoints.count >= 2 else { return nil }

    let n = CGFloat(sourcePoints.count)
    let srcSum = sourcePoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
    let srcMean = CGPoint(x: srcSum.x / n, y: srcSum.y / n)
    let dstSum = destinationPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
    let dstMean = CGPoint(x: dstSum.x / n, y: dstSum.y / n)

    var numeratorReal: CGFloat = 0
    var numeratorImag: CGFloat = 0
    var denominator: CGFloat = 0
    for i in 0..<sourcePoints.count {
      let p = CGPoint(x: sourcePoints[i].x - srcMean.x, y: sourcePoints[i].y - srcMean.y)
      let q = CGPoint(x: destinationPoints[i].x - dstMean.x, y: destinationPoints[i].y - dstMean.y)
      numeratorReal += q.x * p.x + q.y * p.y
      numeratorImag += q.y * p.x - q.x * p.y
      denominator += p.x * p.x + p.y * p.y
    }
    guard denominator > 0 else { return nil }

    let sc = numeratorReal / denominator
    let ss = numeratorImag / denominator

    let a = sc
    let b = ss
    let c = -ss
    let d = sc
    let tx = dstMean.x - (a * srcMean.x + c * srcMean.y)
    let ty = dstMean.y - (b * srcMean.x + d * srcMean.y)
    return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  }
}
