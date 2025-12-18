#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pdf_stamp_editor.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pdf_stamp_editor'
  s.version          = '0.1.0'
  s.summary          = 'PDF viewer with draggable stamp overlays and a pluggable export layer (Android+iOS supported).'
  s.description      = <<-DESC
PDF viewer with draggable stamp overlays and a pluggable export layer (Android+iOS supported).
                       DESC
  s.homepage         = 'https://github.com/ondrahracek/flutter_pdf_stamp_editor'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'OndiTech' => 'ondra.hracek@seznam.cz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

