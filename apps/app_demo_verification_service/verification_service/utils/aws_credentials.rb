module AwsCredentials
  def self.aws_credentials
    return @hardcoded_creds if defined?(@hardcoded_creds) && @hardcoded_creds
    creds = Aws::InstanceProfileCredentials.new(http_open_timeout: 1, http_read_timeout: 1, retries: 0).credentials unless ENV['RACK_ENV']&.to_sym == :test # rubocop:disable Layout/LineLength
    creds = nil if creds&.access_key_id.nil?
    creds ||= Aws::SharedCredentials.new.credentials if ENV['AWS_SDK_CONFIG_OPT_IN']
    @hardcoded_creds = Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID', nil), ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)) unless creds # rubocop:disable Layout/LineLength
    creds || @hardcoded_creds
  end
end
