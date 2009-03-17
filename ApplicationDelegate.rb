#
#  ApplicationDelegate.rb
#  
#  88Miles' application delegate - use it to ensure
#  stuff is done at specific times during the application
#  life cycle.
#
#  Created by Darcy Laycock on 17/03/09.
#  Copyright (c) 2009 BrownBeagle. All rights reserved.
#

class ApplicationDelegate

  def applicationShouldTerminateAfterLastWindowClosed(app)
    return true
  end

end
