require 'bundler/setup'

# Adds all the gems
SETUP_ENV = ENV.fetch('Environment', 'development')
Bundler.require(:default, SETUP_ENV)

# Rails active support extension
# Refer to this page: https://guides.rubyonrails.org/active_support_core_extensions.html#from-position
require 'active_support'
require 'active_support/core_ext/string/access'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/inclusion'
require 'active_support/core_ext/hash/deep_transform_values'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/string/starts_ends_with'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/integer/inflections'

require 'active_record'
require 'action_view'

# Set up autoloading
loader = Zeitwerk::Loader.new
loader.push_dir('app_demo_verification_service')
loader.push_dir('app_demo_verification_service/lib')
loader.push_dir('app_demo_verification_service/utils')
loader.push_dir('app_demo_verification_service/ext_lib')
loader.enable_reloading
loader.setup
