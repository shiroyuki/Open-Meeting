require 'ostruct'
require 'yaml'

module ControlInterface
  def get_settings
    settings = YAML.load_file "#{RAILS_ROOT}/config/settings.yml" || {}
    #settings = OpenStruct.new(settings_raw)
    return settings
  end
end