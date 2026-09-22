import AVFoundation
import AppKit
import SwiftUI

struct CameraPreviewView: NSViewRepresentable {
  let session: AVCaptureSession
  var faces: [DetectedFace] = []

  func makeNSView(context: Context) -> PreviewHostView {
    PreviewHostView(session: session)
  }

  func updateNSView(_ nsView: PreviewHostView, context: Context) {
    nsView.updateFaceBoxes(faces)
  }
}

final class PreviewHostView: NSView {
  private let previewLayer: AVCaptureVideoPreviewLayer
  private var boxLayers: [CAShapeLayer] = []

  init(session: AVCaptureSession) {
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    super.init(frame: .zero)
    wantsLayer = true
    layer = CALayer()
    previewLayer.videoGravity = .resizeAspectFill
    layer?.addSublayer(previewLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    previewLayer.bounds = CGRect(origin: .zero, size: bounds.size)
    previewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
    CATransaction.commit()
  }

  func updateFaceBoxes(_ faces: [DetectedFace]) {
    for layer in boxLayers {
      layer.removeFromSuperlayer()
    }
    boxLayers = faces.map { face in
      let rect = previewLayer.layerRectConverted(fromMetadataOutputRect: face.normalizedBoundingBox)
      let shape = CAShapeLayer()
      shape.path = CGPath(rect: rect, transform: nil)
      shape.strokeColor = NSColor.systemGreen.cgColor
      shape.fillColor = NSColor.clear.cgColor
      shape.lineWidth = 2
      previewLayer.addSublayer(shape)
      return shape
    }
  }
}
