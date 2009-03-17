framework 'Cocoa'

dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation

Dir.entries(dir_path).each do |path|
  if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
    require path
  end
end

NSApplicationMain(0, nil)
