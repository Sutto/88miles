#
#  ApplicationController.rb
#  88Miles
#
#  Created by Darcy Laycock on 17/03/09.
#  Copyright (c) 2009 BrownBeagle. All rights reserved.
#

class ApplicationController
  
  # Windows
  attr_accessor :mainWindow, :preferencesWindow
  
  # Controls
  attr_accessor :controlButton, :timerLabel, :usernameField, :passwordField, :projectsList, :clockOutWindow, :logMessage, :tagsField, :timeZoneField
  
  # Data
  attr_accessor :apiAccess, :hasCredentials, :timer
  
  # Timer Tracker
  attr_accessor :startTime, :timeZones
  
  # View Trackers
  attr_accessor :upperGradient, :middleGradient, :lowerGradient
  
  def showPreferences(sender)
    usernameField.stringValue = Preferences.username.to_s
    passwordField.stringValue = Preferences.password.to_s
    timeZoneField.selectItemWithTitle(@timeZones.invert[currentTimeZone])
    NSApp.beginSheet(preferencesWindow, modalForWindow: mainWindow, modalDelegate: self, didEndSelector: "sheetDidClose:withCode:andEventContext:", contextInfo: nil)
  end
  
  def hidePreferences(sender)
    NSApp.endSheet(preferencesWindow)
    Preferences.update_all(username: usernameField.stringValue,
                           password: passwordField.stringValue)
    updateAuth!
  end
  
  def showClockOutDialog
    logMessage.stringValue = ""
    tagsField.stringValue  = ""
    NSApp.beginSheet(clockOutWindow, modalForWindow: mainWindow, modalDelegate: self, didEndSelector: "sheetDidClose:withCode:andEventContext:", contextInfo: nil)
  end
  
  def cancelLoggingTime(sender)
    NSApp.endSheet(clockOutWindow)
    @last_details = nil
  end
  
  def logTimeFromOptions(sender)
    NSApp.endSheet(clockOutWindow)
    project, start_time, end_time = @last_details
    apiAccess.clock_time(project, start_time, end_time, logMessage.stringValue.strip, tagsField.stringValue.to_s.strip)
    @last_details = nil
  end
  
  def sheetDidClose(sheet, withCode: returnCode, andEventContext: context)
    sheet.orderOut(nil)
  end
  
  def awakeFromNib
    @timeZones = {}
    NSTimeZone.knownTimeZoneNames.each do |zone_name|
      english_name = zone_name.gsub("_", " ").split("/").join(" - ")
      @timeZones[english_name] = zone_name
    end
    timeZoneField.removeAllItems
    timeZoneField.addItemsWithTitles(@timeZones.keys.sort)
    projectsList.removeAllItems
    updateAuth! if !hasCredentials
    startTimer if @clockedIn
    upperGradient.startColour  = NSColor.colorWithCalibratedWhite(0.80, alpha: 1.0)
    upperGradient.endColour    = NSColor.colorWithCalibratedWhite(0.98, alpha: 1.0)
    middleGradient.startColour = NSColor.colorWithCalibratedWhite(0.05, alpha: 1.0)
    middleGradient.endColour   = NSColor.colorWithCalibratedWhite(0.14, alpha: 1.0)
    lowerGradient.startColour  = NSColor.colorWithCalibratedWhite(0.65, alpha: 1.0)
    lowerGradient.endColour    = NSColor.colorWithCalibratedWhite(0.80, alpha: 1.0)
  end
  
  def windowDidBecomeMain(notification)
    if !hasCredentials
      showPreferences(self)
    end
  end
  
  def storeLastProject(sender)
    i = projectsList.indexOfSelectedItem
    Preferences.lastProjectKey = apiAccess.projects[i].id if i >= 0
  end
  
  def attemptToRestoreProject
    if apiAccess && (id = Preferences.lastProjectKey.to_i) != 0
      index = apiAccess.projects.index { |p| p.id == id }
      projectsList.selectItemAtIndex index unless index.nil?
    end
  end
  
  def toggleClockedStatus(sender)
    if @clockedIn
      clockOut(sender)
    else
      clockIn(sender)
    end
  end
  
  def clockOut(sender)
    NSLog("Clocking Out")
    @clockedIn = false
    startTime = @startTime
    endTime = Time.now
    @startTime = nil
    projectsList.enabled = true
    controlButton.title = "Clock In"
    stopTimer
    logTime(startTime, endTime)
  end
  
  def clockIn(sender)
    NSLog("Clocking In")
    @clockedIn = true
    @startTime = Time.now
    projectsList.enabled = false
    controlButton.title = "Clock Out"
    updateSecondsDisplay
    startTimer
  end
  
  def updateAuth!
    username, password = Preferences.get_all(:username, :password)
    if username.to_s == "" || password.to_s == ""
      NSLog("No Credentials")
      disableTimeTracking!
    else
      NSLog("Credentials Ahoy-there!")
      begin
        self.setHasCredentials true
        projectsList.enabled = false unless projectsList.nil?
        self.setApiAccess EightyEightMiles.new(username, password, currentTimeZone)
        NSLog("Reloading Drop Down Data!")
        unless projectsList.nil?
          updateProjectsList
          projectsList.enabled = true
          controlButton.enabled = true
          projectsList.selectItemAtIndex 0 if hasCredentials && apiAccess.projects.size > 0
          attemptToRestoreProject
        end
      rescue EightyEightMiles::Error
        # Consider that the new details are incorrect
        disableTimeTracking!
        showWarning("The credentials you entered seem to be invalid - please check them.")
      end
    end
  end
  
  def disableTimeTracking!
    projectsList.removeAllItems
    self.setHasCredentials false
    self.setApiAccess nil
    projectsList.enabled = false
    controlButton.enabled = false
  end
  
  def updateSecondsDisplay(timer = nil)
    NSLog("Timer Fired!")
    timerLabel.stringValue = timeDiffToString(@startTime)
  end
  
  def windowShouldClose(window)
    NSLog("Asked if I should close!")
    if @clockedIn
      showWarning("You need to clock out before you can close the application")
      return false
    else
      return true
    end
  end
  
  def updateTimeZonePreference(sender)
    Preferences.time_zone = @timeZones[timeZoneField.titleOfSelectedItem]
  end
  
  protected
  
  def startTimer
    return if @timer || !@clockedIn
    @timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateSecondsDisplay:", userInfo: nil, repeats: true)
  end
  
  def stopTimer
    timer.invalidate unless timer.nil?
    @timer = nil
    updateSecondsDisplay
  end
  
  def logTime(startedAt, endedAt)
    return if apiAccess.nil?
    index = projectsList.indexOfSelectedItem
    project = apiAccess.projects[index]
    unless project.nil?
      @last_details = [project, startedAt, endedAt]
      showClockOutDialog
    end
  end
  
  def timeDiffToString(startTime)
    return "" if startTime.nil?
    diff = (Time.now - startTime).to_i
    seconds = diff % 60
    minutes = diff / 60 % 60
    hours   = diff / 3600
    return "%d:%02d:%02d" % [hours, minutes, seconds]
  end
  
  def updateProjectsList
    projectsList.removeAllItems
    if hasCredentials
      projectsList.addItemsWithTitles apiAccess.projects.map { |p| p.name }
    end
  end

  def showWarning(text)
    alert = NSAlert.alertWithMessageText(text, defaultButton: "ok", alternateButton: nil, otherButton: nil, informativeTextWithFormat: "")
    alert.alertStyle = NSWarningAlertStyle
    alert.beginSheetModalForWindow(mainWindow, modalDelegate: self, didEndSelector: nil, contextInfo: nil)
  end
  
  def currentTimeZone
    Preferences.time_zone ||= NSTimeZone.localTimeZone.name
  end

end
