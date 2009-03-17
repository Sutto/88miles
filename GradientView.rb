#
#  GradientView.rb
#
#  Simple view which draws a user-configurable gradient.
#  Based off code from http://tr.im/hs7J (in Obj-C, ported
#  to MacRuby)
#
#  Created by Darcy Laycock on 17/03/09.
#  Copyright (c) 2009 BrownBeagle. All rights reserved.
#

class GradientView <  NSView
  
  attr_accessor :startColour, :endColour, :gradientAngle

  def initWithFrame(frame)
    super
    self.startColour   = NSColor.colorWithCalibratedWhite(1.0, alpha: 1.0)
    self.endColour     = nil
    self.gradientAngle = 90
    return self
  end

  def drawRect(rect)
    if endColour == nil || startColour == endColour
      startColour.set
      NSRectFill(rect)
    else
      gradient = NSGradient.alloc.initWithStartingColor(startColour, endingColor: endColour)
      gradient.drawInRect(self.bounds, angle: gradientAngle)
    end
  end

end
