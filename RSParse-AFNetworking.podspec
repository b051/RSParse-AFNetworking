Pod::Spec.new do |s|
  s.name         = "RSParse-AFNetworking"
  s.version      = "0.0.1"
  s.summary      = "Connect Parse.com BaaS (via its REST API) using AFNetworking."
  s.homepage     = "https://github.com/b051/RSParse-AFNetworking"
  s.license      = 'MIT'
  s.author       = { "Rex Sheng" => "shengning@gmail.com" }
  s.source       = { :git => "https://github.com/b051/RSParse-AFNetworking.git", :tag => "0.0.1" }
  s.source_files = 'RSParse'
  s.requires_arc = true
  
  s.dependency 'AFNetworking', '~> 1.0'

end
