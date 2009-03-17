$:.unshift(File.dirname(__FILE__))

require 'httparty'
require 'cgi'

class EightyEightMiles

  class Error < StandardError; end

  DEFAULT_TIME_ZONE = "Australia/Perth"
  
  class Project

    attr_accessor :name, :id

    def initialize(id, name)
      self.name, self.id = name, id
    end

    def to_path(*actions)
      actions.unshift(self.id)
      actions.unshift("/projects")
      return "#{File.join(*actions.map { |a| a.to_s })}.xml"
    end

    def xml_for_shift(time_zone, start_time, end_time, note = nil, tags = "")
      parts = [
        "<start>#{start_time.strftime("%a, %d %b %Y %H:%M:%S")}</start>",
        "<stop>#{end_time.strftime("%a, %d %b %Y %H:%M:%S")}</stop>",
        "<time_zone>#{time_zone}</time_zone>",
        "<notes>#{CGI.escapeHTML note.to_s}</notes>",
        "<tag_list>#{CGI.escapeHTML tags.to_s}</tag_list>"
      ].join("")
      return "<shift>#{parts}</shift>"
    end

  end
  
  include HTTParty
  
  base_uri '88miles.net'
  
  attr_accessor :user, :pass, :projects, :time_zone, :staff
  
  def initialize(user, pass, tz = DEFAULT_TIME_ZONE, auto_load = true)
    @time_zone = tz
    @user, @pass = user, pass
    @projects  = []
    @staff     = []
    if auto_load
      # load_staff
      load_projects
    end
  end
  
  def load_staff
    staff_raw = self.class.get('/staff.xml', opts).to_hash
  end
  
  def load_shifts_for(project)
    raw_shifts = self.class.get(project.to_path(:shifts), opts)
    check_error! raw_shifts
  end
  
  def load_companies
    companies = self.class.get('/companies.xml', opts).to_hash
  end
  
  def load_projects
    projects = self.class.get('/projects.xml', opts).to_hash
    check_error! projects
    projects["projects"].each do |project|
      if project["active"] == "true"
        self.projects << Project.new(project["id"].to_i, project["name"].to_s)
      end
    end
  end
  
  def project(name_or_id)
    self.projects.detect { |p| p.id.to_s == name_or_id.to_s || p.name == name_or_id }
  end
  
  def clock_time(project, start_time, end_time, message = nil, tags = nil)
    shift_xml = project.xml_for_shift(self.time_zone, start_time, end_time, message, tags)
    self.class.post(project.to_path(:shifts), {:body => shift_xml, :headers => xml_headers}.merge(opts))
    nil
  rescue NoMethodError # frakking bug in httparty
    nil
  end
  
  protected
  
  def check_error!(hash)
    if hash && hash.has_key?("errors") && hash["errors"].is_a?(Hash) && hash["errors"].has_key?("error")
      raise EightyEightMiles::Error, hash["errors"]["error"]
    end
  end
  
  def xml_headers
    { "Content-Type" => "application/xml" }
  end
  
  def opts(opts = {})
    return {:query => opts, :basic_auth => {:username => user, :password => pass}}
  end
  
end