Pod::Spec.new do |s|
  s.name         = "Cheetah"
  s.version      = "2.0.0"
  s.summary      = "A really fast JSON library"
  s.homepage     = "http://openkitten.org"
  s.license      = "MIT"
  s.author    = "OpenKitten"
  s.source       = { :git => "https://github.com/OpenKitten/Cheetah.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/Cheetah"
end
