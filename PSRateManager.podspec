Pod::Spec.new do |spec|
  spec.name             = ‘PSRateManager’
  spec.version          = ‘1.0’
  spec.license          =  :type => 'BSD' 
  spec.homepage         = 'https://github.com/panda-systems/pandaLibrary'
  spec.authors          = ‘Panda Systems’
  spec.summary          = ''
  #spec.source           =  :git => 'https://github.com/panda-systems/pandaLibrary.git', :tag => 'v1.0' 
  spec.source_files     = ‘PSRateManager.h,m’
  spec.requires_arc     = true
end