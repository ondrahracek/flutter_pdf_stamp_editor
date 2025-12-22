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

    // Validate input data
    guard !pdf.data.isEmpty else {
      result(FlutterError(code: "BAD_ARGS", message: "PDF data is empty", details: nil))
      return
    }
    guard !payload.data.isEmpty else {
      result(FlutterError(code: "BAD_ARGS", message: "Payload data is empty", details: nil))
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
    guard n >= 0 else {
      throw NSError(domain: "payload", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid byte count: \(n)"])
    }
    if i + n > data.count {
      throw NSError(domain: "payload", code: 1, userInfo: [NSLocalizedDescriptionKey: "Payload truncated at offset \(i), need \(n) bytes, have \(data.count - i)"])
    }
  }

  mutating func u8() throws -> UInt8 {
    try need(1)
    defer { i += 1 }
    return data[i]
  }

  mutating func u32() throws -> UInt32 {
    try need(4)
    // Fix alignment issue: extract bytes first, then load from aligned buffer
    let bytes = data.subdata(in: i..<(i + 4))
    i += 4
    return bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
  }

  mutating func f64() throws -> Double {
    try need(8)
    // Fix alignment issue: extract bytes first, then load from aligned buffer
    let bytes = data.subdata(in: i..<(i + 8))
    i += 8
    let bits = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
    return Double(bitPattern: bits)
  }

  mutating func bytes(_ n: Int) throws -> Data {
    // Validate length to prevent memory exhaustion
    guard n >= 0 else {
      throw NSError(domain: "payload", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid byte length: \(n)"])
    }
    guard n <= 100 * 1024 * 1024 else { // 100MB limit
      throw NSError(domain: "payload", code: 6, userInfo: [NSLocalizedDescriptionKey: "Byte length too large: \(n) bytes"])
    }
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
    // Normalize rotation to prevent NaN/Infinity issues
    let normalized = rotationDeg.isFinite ? rotationDeg : 0
    self.rotationDeg = normalized.truncatingRemainder(dividingBy: 360)
    super.init(bounds: bounds, forType: .stamp, withProperties: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(with box: PDFDisplayBox, in context: CGContext) {
    guard let cg = image.cgImage else { return }
    guard rotationDeg.isFinite else { return } // Safety check
    
    context.saveGState()
    defer { context.restoreGState() }
    
    if let pageBounds = page?.bounds(for: box) {
      context.translateBy(x: -pageBounds.origin.x, y: -pageBounds.origin.y)
    }
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    guard center.x.isFinite && center.y.isFinite else { return }
    
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: rotationDeg * .pi / 180.0)
    context.translateBy(x: -center.x, y: -center.y)
    context.draw(cg, in: bounds)
  }
}

// MARK: - PDFKit stamping

private func stampWithPdfKit(pdfData: Data, payload: Data) throws -> Data {
  guard let doc = PDFDocument(data: pdfData) else {
    throw NSError(domain: "pdf", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDFDocument from data"])
  }

  let pageCount = doc.pageCount
  guard pageCount > 0 else {
    throw NSError(domain: "pdf", code: 7, userInfo: [NSLocalizedDescriptionKey: "PDF has no pages"])
  }

  var r = BinaryReader(data: payload)
  
  // Validate magic number
  let magic = try r.u32()
  guard magic == 0x4D545350 else {
    throw NSError(domain: "payload", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid magic number: 0x\(String(magic, radix: 16, uppercase: true))"])
  }
  
  // Validate version
  let ver = try r.u32()
  guard ver == 1 else {
    throw NSError(domain: "payload", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unsupported version: \(ver), expected 1"])
  }
  
  // Validate count (prevent integer overflow)
  let countU32 = try r.u32()
  guard let count = Int(exactly: countU32) else {
    throw NSError(domain: "payload", code: 8, userInfo: [NSLocalizedDescriptionKey: "Stamp count too large: \(countU32)"])
  }
  guard count >= 0 && count <= 10000 else { // Reasonable limit
    throw NSError(domain: "payload", code: 9, userInfo: [NSLocalizedDescriptionKey: "Invalid stamp count: \(count), must be 0-10000"])
  }

  var processedCount = 0
  var errorCount = 0
  
  for stampIndex in 0..<count {
    do {
      let type = try r.u8()
      
      // Validate pageIndex
      let pageIndexU32 = try r.u32()
      guard let pageIndex = Int(exactly: pageIndexU32) else {
        errorCount += 1
        continue
      }
      guard pageIndex >= 0 && pageIndex < pageCount else {
        // Skip invalid page index but continue processing
        errorCount += 1
        continue
      }
      
      // Read coordinates and dimensions
      let cx = try r.f64()
      let cy = try r.f64()
      let w = try r.f64()
      let h = try r.f64()
      let rot = try r.f64()
      
      // Validate numeric values (prevent NaN/Infinity)
      guard cx.isFinite && cy.isFinite && w.isFinite && h.isFinite && rot.isFinite else {
        errorCount += 1
        continue
      }
      
      // Validate coordinate ranges (prevent overflow in calculations)
      guard abs(cx) <= 1e6 && abs(cy) <= 1e6 else {
        errorCount += 1
        continue
      }
      
      guard let page = doc.page(at: pageIndex) else {
        errorCount += 1
        continue
      }

      if type == 1 {
        // Image stamp
        let pngLenU32 = try r.u32()
        guard let pngLen = Int(exactly: pngLenU32) else {
          errorCount += 1
          continue
        }
        guard pngLen >= 0 && pngLen <= 50 * 1024 * 1024 else { // 50MB limit for PNG
          errorCount += 1
          continue
        }
        
        // Handle empty PNG (skip it)
        guard pngLen > 0 else {
          errorCount += 1
          continue
        }
        
        let png = try r.bytes(pngLen)
        guard let img = UIImage(data: png) else {
          errorCount += 1
          continue
        }
        
        // Validate image dimensions
        guard img.size.width > 0 && img.size.height > 0 else {
          errorCount += 1
          continue
        }
        
        // Validate bounds
        guard w > 0 && h > 0 && w <= 1e6 && h <= 1e6 else {
          errorCount += 1
          continue
        }
        
        let bounds = CGRect(x: cx - w / 2.0, y: cy - h / 2.0, width: w, height: h)
        guard bounds.isValid else {
          errorCount += 1
          continue
        }
        
        // Normalize rotation
        let normalizedRot = rot.truncatingRemainder(dividingBy: 360)
        
        let ann = ImageStampAnnotation(bounds: bounds, image: img, rotationDeg: CGFloat(normalizedRot))
        page.addAnnotation(ann)
        processedCount += 1
        
      } else if type == 2 {
        // Text stamp
        let fontSize = try r.f64()
        let argb = try r.u32()
        let tlenU32 = try r.u32()
        
        guard let tlen = Int(exactly: tlenU32) else {
          errorCount += 1
          continue
        }
        guard tlen >= 0 && tlen <= 10 * 1024 * 1024 else { // 10MB limit for text
          errorCount += 1
          continue
        }
        
        // Validate font size
        guard fontSize.isFinite && fontSize > 0 && fontSize <= 1000 else {
          errorCount += 1
          continue
        }
        
        let txt = try r.bytes(tlen)
        let s = String(data: txt, encoding: .utf8) ?? ""
        
        // Empty text is valid, but we should still create the annotation
        
        // Validate bounds (text stamps use point bounds)
        guard cx.isFinite && cy.isFinite else {
          errorCount += 1
          continue
        }
        
        let bounds = CGRect(x: cx, y: cy, width: 1, height: 1)
        guard bounds.isValid else {
          errorCount += 1
          continue
        }
        
        // Normalize rotation
        let normalizedRot = rot.truncatingRemainder(dividingBy: 360)
        
        let ann = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        ann.contents = s
        ann.font = UIFont.boldSystemFont(ofSize: CGFloat(fontSize))
        ann.color = .clear
        // Extract RGB components from ARGB (AARRGGBB format)
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        ann.fontColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        // Note: PDFKit doesn't directly support rotation on freeText annotations
        // Rotation would need to be handled differently if required
        page.addAnnotation(ann)
        processedCount += 1
        
      } else {
        // Unknown type - throw error to match Android behavior
        throw NSError(domain: "payload", code: 12, userInfo: [NSLocalizedDescriptionKey: "Unknown stamp type: \(type) at index \(stampIndex)"])
      }
      
    } catch let error as NSError where error.domain == "payload" && error.code == 1 {
      // Truncated payload - stop processing
      break
    } catch {
      // If we can't parse a stamp, skip it but continue with others
      errorCount += 1
      // Re-throw if it's a fatal error (unknown type)
      if let nsError = error as NSError?, nsError.domain == "payload" && nsError.code == 12 {
        throw error
      }
    }
  }

  // If we processed at least one stamp, return the result
  // Otherwise throw if all stamps failed
  if processedCount == 0 && errorCount > 0 {
    throw NSError(domain: "pdf", code: 11, userInfo: [NSLocalizedDescriptionKey: "Failed to process any stamps: \(errorCount) errors out of \(count) stamps"])
  }

  guard let out = doc.dataRepresentation() else {
    throw NSError(domain: "pdf", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PDF data representation"])
  }
  return out
}

// MARK: - CGRect validation extension

private extension CGRect {
  var isValid: Bool {
    return !isInfinite && !isNull && 
           width.isFinite && height.isFinite && 
           width > 0 && height > 0 && 
           origin.x.isFinite && origin.y.isFinite &&
           abs(origin.x) <= 1e6 && abs(origin.y) <= 1e6 &&
           width <= 1e6 && height <= 1e6
  }
}
