Pod::Spec.new do |s|
  s.name         = "MYEntry+JSON"
  s.version      = "1.0"
  s.summary      = "JSON extend of MYEntry."
  s.homepage     = "https://github.com/Whirlwind/MYEntry-JSON"
  s.license      = 'MIT'
  s.author       = { "Whirlwind" => "Whirlwindjames@foxmail.com" }
  s.source       = { :git => "https://github.com/Whirlwind/MYEntry-JSON.git", :tag=>'v1.0'}
  s.platform     = :ios, '5.0'
  s.source_files = 'MYEntry+JSON/MYEntry+JSON/Shared/**/*.{h,m}'
  # s.resources = "src/*.{broadcast,route}"
  s.frameworks = 'UIKit', 'Foundation'
  #s.prefix_header_file = 'MYEntry+JSON/MYEntry+JSON-SharedPrefix.pch'
  s.requires_arc = true

  s.dependency 'MYEntry'
  s.dependency 'ASIHTTPRequest'
  s.dependency 'JSONAPI'
  s.dependency 'UIDevice'
  # s.dependency 'MTStatusBarOverlay'
end
