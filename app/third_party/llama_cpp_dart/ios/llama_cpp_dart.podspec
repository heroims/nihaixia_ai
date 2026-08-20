Pod::Spec.new do |s|
  s.name             = 'llama_cpp_dart'
  s.version          = '0.0.7'
  s.summary          = 'Dart binding for llama.cpp (ffi)'
  s.description      = 'FFI plugin; native libllama is force-linked into the Runner.'
  s.homepage         = 'https://github.com/netdur/llama_cpp_dart'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'netdur' => 'netdur@gmail.com' }
  s.source           = { :git => '', :tag => '0.0.7' }
  s.platform         = :ios, '13.0'
  s.source_files     = 'Classes/**/*'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.0'
end
