import Flutter
import UIKit
import PDFKit

public class PdfStampEditorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "pdf_stamp_editor",
      binaryMessenger: registrar.messenger()
    )
    let instance = PdfStampEditorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard call.method == "stampPdf" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let pdf = args["pdf"] as? FlutterStandardTypedData,
      let payload = args["payload"] as? FlutterStandardTypedData
    else {
      result(FlutterError(code: "BAD_ARGS", message: "Missing pdf/payload", details: nil))
      return
    }

    do {
      let out = try stampWithPdfKit(pdfData: pdf.data, payload: payload.data)
      result(FlutterStandardTypedData(bytes: out))
    } catch {
      result(FlutterError(code: "STAMP_FAILED", message: "\(error)", details: nil))
    }
  }
}

// MARK: - Binary reader

private struct BinaryReader {
  let data: Data
  var i: Int = 0

  mutating func need(_ n: Int) throws {
    if i + n > data.count {
      throw NSError(domain: "payload", code: 1)
    }
  }

  mutating func u8() throws -> UInt8 {
    try need(1)
    defer { i += 1 }
    return data[i]
  }

  mutating func u32() throws -> UInt32 {
    try need(4)
    let v = data.withUnsafeBytes { $0.load(fromByteOffset: i, as: UInt32.self) }
    i += 4
    return UInt32(littleEndian: v)
  }

  mutating func f64() throws -> Double {
    try need(8)
    let v = data.withUnsafeBytes { $0.load(fromByteOffset: i, as: UInt64.self) }
    i += 8
    return Double(bitPattern: UInt64(littleEndian: v))
  }

  mutating func bytes(_ n: Int) throws -> Data {
    try need(n)
    defer { i += n }
    return data.subdata(in: i..<(i + n))
  }
}

// MARK: - Custom image annotation

final class ImageStampAnnotation: PDFAnnotation {
  let image: UIImage
  let rotationDeg: CGFloat

  init(bounds: CGRect, image: UIImage, rotationDeg: CGFloat) {
    self.image = image
    self.rotationDeg = rotationDeg
    super.init(bounds: bounds, forType: .stamp, withProperties: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(with box: PDFDisplayBox, in context: CGContext) {
    guard let cg = image.cgImage else { return }
    context.saveGState()
    if let pageBounds = page?.bounds(for: box) {
      context.translateBy(x: -pageBounds.origin.x, y: -pageBounds.origin.y)
    }
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: rotationDeg * .pi / 180.0)
    context.translateBy(x: -center.x, y: -center.y)
    context.draw(cg, in: bounds)
    context.restoreGState()
  }
}

// MARK: - PDFKit stamping

private func stampWithPdfKit(pdfData: Data, payload: Data) throws -> Data {
  guard let doc = PDFDocument(data: pdfData) else {
    throw NSError(domain: "pdf", code: 1)
  }

  var r = BinaryReader(data: payload)
  let magic = try r.u32()
  if magic != 0x4D545350 { throw NSError(domain: "payload", code: 2) }
  let ver = try r.u32()
  if ver != 1 { throw NSError(domain: "payload", code: 3) }
  let count = Int(try r.u32())

  for _ in 0..<count {
    let type = try r.u8()
    let pageIndex = Int(try r.u32())
    let cx = try r.f64()
    let cy = try r.f64()
    let w = try r.f64()
    let h = try r.f64()
    let rot = try r.f64()

    guard let page = doc.page(at: pageIndex) else { continue }

    if type == 1 {
      let pngLen = Int(try r.u32())
      let png = try r.bytes(pngLen)
      guard let img = UIImage(data: png) else { continue }
      let bounds = CGRect(x: cx - w / 2.0, y: cy - h / 2.0, width: w, height: h)
      let ann = ImageStampAnnotation(bounds: bounds, image: img, rotationDeg: CGFloat(rot))
      page.addAnnotation(ann)
    } else if type == 2 {
      let fontSize = try r.f64()
      _ = try r.u32() // argb (unused for now)
      let tlen = Int(try r.u32())
      let txt = try r.bytes(tlen)
      let s = String(data: txt, encoding: .utf8) ?? ""
      let bounds = CGRect(x: cx, y: cy, width: 1, height: 1)
      let ann = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
      ann.contents = s
      ann.font = UIFont.boldSystemFont(ofSize: CGFloat(fontSize))
      ann.color = .clear
      ann.fontColor = .red
      page.addAnnotation(ann)
    }
  }

  guard let out = doc.dataRepresentation() else {
    throw NSError(domain: "pdf", code: 4)
  }
  return out
}


