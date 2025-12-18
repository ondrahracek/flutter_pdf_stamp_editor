package com.ondrahracek.pdf_stamp_editor

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream.AppendMode
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject
import com.tom_roush.pdfbox.util.Matrix
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import java.io.ByteArrayOutputStream
import kotlin.math.PI

class PdfStampEditorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var appContext: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    // Required for PdfBox-Android resource access.
    PDFBoxResourceLoader.init(appContext)

    channel = MethodChannel(binding.binaryMessenger, "pdf_stamp_editor")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method != "stampPdf") {
      result.notImplemented()
      return
    }

    try {
      @Suppress("UNCHECKED_CAST")
      val args = call.arguments as Map<String, Any?>
      val pdf = args["pdf"] as ByteArray
      val payload = args["payload"] as ByteArray

      val out = stampWithPdfBox(pdf, payload)
      result.success(out)
    } catch (t: Throwable) {
      result.error("STAMP_FAILED", t.message, null)
    }
  }

  // ===== Payload parsing (matches Dart binary format) =====

  private class R(private val b: ByteArray) {
    private var i = 0
    private fun need(n: Int) {
      if (i + n > b.size) error("payload truncated")
    }

    fun u8(): Int {
      need(1); return b[i++].toInt() and 0xFF
    }

    fun u32(): Long {
      need(4)
      val v = (b[i].toLong() and 0xFF) or
          ((b[i + 1].toLong() and 0xFF) shl 8) or
          ((b[i + 2].toLong() and 0xFF) shl 16) or
          ((b[i + 3].toLong() and 0xFF) shl 24)
      i += 4
      return v
    }

    fun f64(): Double {
      need(8)
      var bits = 0L
      for (k in 0 until 8) bits = bits or ((b[i + k].toLong() and 0xFF) shl (8 * k))
      i += 8
      return Double.fromBits(bits)
    }

    fun bytes(n: Int): ByteArray {
      need(n)
      val out = b.copyOfRange(i, i + n)
      i += n
      return out
    }
  }

  private sealed interface Stamp {
    val pageIndex: Int
    val cx: Float
    val cy: Float
    val rotDeg: Float
  }

  private data class ImageStamp(
    override val pageIndex: Int,
    override val cx: Float,
    override val cy: Float,
    val wPt: Float,
    val hPt: Float,
    override val rotDeg: Float,
    val png: ByteArray
  ) : Stamp

  private data class TextStamp(
    override val pageIndex: Int,
    override val cx: Float,
    override val cy: Float,
    override val rotDeg: Float,
    val fontSize: Float,
    val argb: Int,
    val text: String
  ) : Stamp

  private fun parseStamps(payload: ByteArray): List<Stamp> {
    val r = R(payload)
    val magic = r.u32()
    require(magic == 0x4D545350L) { "bad magic" } // "PSTM"
    val ver = r.u32()
    require(ver == 1L) { "unsupported version $ver" }
    val count = r.u32().toInt()

    val out = ArrayList<Stamp>(count)
    repeat(count) {
      val type = r.u8()
      val pageIndex = r.u32().toInt()
      val cx = r.f64().toFloat()
      val cy = r.f64().toFloat()
      val w = r.f64().toFloat()
      val h = r.f64().toFloat()
      val rot = r.f64().toFloat()

      if (type == 1) {
        val pngLen = r.u32().toInt()
        val png = r.bytes(pngLen)
        out.add(ImageStamp(pageIndex, cx, cy, w, h, rot, png))
      } else if (type == 2) {
        val fontSize = r.f64().toFloat()
        val argb = r.u32().toInt()
        val tlen = r.u32().toInt()
        val txtBytes = r.bytes(tlen)
        val txt = txtBytes.toString(Charsets.UTF_8)
        out.add(TextStamp(pageIndex, cx, cy, rot, fontSize, argb, txt))
      } else {
        error("unknown stamp type $type")
      }
    }
    return out
  }

  // ===== Actual stamping (vector) using PdfBox-Android =====

  private fun stampWithPdfBox(pdf: ByteArray, payload: ByteArray): ByteArray {
    val stamps = parseStamps(payload)
    PDDocument.load(pdf).use { doc ->
      val byPage = stamps.groupBy { it.pageIndex }
      for ((pageIndex, pageStamps) in byPage) {
        val page = doc.getPage(pageIndex)
        PDPageContentStream(doc, page, AppendMode.APPEND, true, true).use { cs ->
          for (s in pageStamps) {
            when (s) {
              is ImageStamp -> drawImageStamp(doc, cs, s)
              is TextStamp -> drawTextStamp(cs, s)
            }
          }
        }
      }
      val out = ByteArrayOutputStream()
      doc.save(out)
      return out.toByteArray()
    }
  }

  private fun drawImageStamp(doc: PDDocument, cs: PDPageContentStream, s: ImageStamp) {
    val img = PDImageXObject.createFromByteArray(doc, s.png, "stamp")
    val x = s.cx - s.wPt / 2f
    val y = s.cy - s.hPt / 2f
    val angle = (s.rotDeg * PI / 180.0).toFloat()

    cs.saveGraphicsState()
    if (s.rotDeg != 0f) {
      cs.transform(Matrix.getRotateInstance(angle.toDouble(), s.cx, s.cy))
    }
    cs.drawImage(img, x, y, s.wPt, s.hPt)
    cs.restoreGraphicsState()
  }

  private fun drawTextStamp(cs: PDPageContentStream, s: TextStamp) {
    val font = PDType1Font.HELVETICA_BOLD
    val fontSize = s.fontSize
    val angle = (s.rotDeg * PI / 180.0).toFloat()

    val textWidth = (font.getStringWidth(s.text) / 1000f) * fontSize
    val capHeight = (font.fontDescriptor.capHeight / 1000f) * fontSize

    val x = s.cx - textWidth / 2f
    val y = s.cy - capHeight / 2f

    val r = (s.argb shr 16) and 0xFF
    val g = (s.argb shr 8) and 0xFF
    val b = (s.argb) and 0xFF

    cs.saveGraphicsState()
    if (s.rotDeg != 0f) {
      cs.transform(Matrix.getRotateInstance(angle.toDouble(), s.cx, s.cy))
    }

    cs.beginText()
    cs.setFont(font, fontSize)
    cs.setNonStrokingColor(r, g, b)
    cs.newLineAtOffset(x, y)
    cs.showText(s.text)
    cs.endText()

    cs.restoreGraphicsState()
  }
}

