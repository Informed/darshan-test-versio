class AwsS3
  attr_reader :bucket

  class << self
    def factory(key_prefix, **kwargs)
      AwsS3.new(key_prefix, **kwargs)
    end

    def honeybadger
      factory('honeybadger')
    end

    def application_factory(application_id, partner_id, key = 'application')
      key = key.present? ? "/#{key}" : ''
      factory("#{partner_id}/#{application_id}#{key}")
    end

    def documents(application_id, partner_id)
      application_factory(application_id, partner_id, 'documents')
    end

    def stipulation_service_results(application_id, partner_id, action)
      application_factory(application_id, partner_id, action.to_s.underscore)
    end

    def restore_object(key_prefix, file_name)
      delete_marker = client.list_object_versions(bucket: ENV.fetch('AWS_DEFAULT_BUCKET', nil), prefix: "#{key_prefix}/#{file_name}").delete_markers.first # rubocop:disable Layout/LineLength
      return unless delete_marker&.is_latest
      version_id = delete_marker.version_id
      factory(key_prefix).delete_version(file_name, version_id)
    end

    def client
      @@client ||= Aws::S3::Client.new
    end

    # assumes URI object and version_id present
    def file_content(uri, version)
      client.get_object({
                          bucket:     uri.host,
                          key:        uri.path.from(1),
                          version_id: version
                        }).body.read
    end
  end

  def initialize(key_prefix, options = {})
    bucket = options.fetch(:bucket, nil)
    proxy_url = options.fetch(:proxy_url, nil)

    @key_prefix = key_prefix
    @s3 = Aws::S3::Resource.new
    @proxy_url = proxy_url.present? ? "https://#{proxy_url}" : nil
    @bucket = bucket || ENV.fetch('AWS_DEFAULT_BUCKET', 'informed-techno-core-dev-exchange')
  end

  def uri_for(file_name, version_id = nil)
    version_id = version_id ? "##{version_id}" : nil
    return "s3://#{bucket}/#{@key_prefix}/#{file_name}#{version_id}" if @key_prefix.present?
    "s3://#{bucket}/#{file_name}#{version_id}"
  end

  def upload_from_link(link, file_name, public_access = false)
    # We need to save it to a temp file before we can upload to S3
    upload_from_temp_file(write_to_temp_file(link), file_name, public_access)
  end

  def upload_from_content(content, file_name, public_access = false)
    tmp_file = Tempfile.new('tmp_file', '/tmp')
    File.binwrite(tmp_file.path, content)
    upload_from_temp_file(tmp_file, file_name, public_access)
  end

  def direct_upload_from_content(content, file_name, ignore_key_prefix = false)
    object_file_name = ignore_key_prefix ? file_name : "#{@key_prefix}/#{file_name}"
    @s3.bucket(bucket).object(object_file_name).put(body: content)
  end

  def upload_from_temp_file(tmp_file, file_name, public_access = false, unlink = true)
    url = upload_from_file_name(tmp_file.path, file_name, public_access)
    tmp_file.unlink if unlink
    url
  end

  def upload_from_file_name(local_file_name, file_name, public_access = false)
    # Create the S3 object and upload the file
    obj = file_object(file_name)
    obj.upload_file(local_file_name)
    obj.acl.put(acl: 'public-read') if public_access
    file_url(file_name)
  end

  # to should include new key prefix
  def move_file(from, options = {})
    to = options.fetch(:to, nil)

    file_object(from).move_to("#{bucket}/#{to}")
  end

  # Moves a file by copying the file located at 'from' to the location 'to' and creating a delete marker version
  # as the new version at location 'from'. This function deletes all versions at location 'from'.
  # Make sure this is really the right method for you to call and make sure your arguments are correct.
  def move_file_and_delete_versions!(from, options = {})
    to = options.fetch(:to, nil)

    move_file(from, to: to)
    delete_versions!(from)
  end

  # to should include new key prefix
  def copy_file(from, to, options = {})
    to_bucket = options.fetch(:to_bucket, nil)
    file_object(from).copy_to("#{to_bucket || bucket}/#{to}")
  end

  def file_exists?(file_name)
    !!file_object(file_name)&.exists?
  end

  # Pass an array to tmp_file_name to enforce an extension in the filename; ['tmp_file', '.csv']
  def download_to_temp_file(file_name, tmp_file = 'tmp_file')
    write_to_temp_file(presigned_url(file_name), tmp_file)
  end

  def presigned_url(file_name, expiration = 3600)
    file_object(file_name).presigned_url(:get, expires_in: expiration, response_content_disposition: "attachment; filename = #{file_name}") # rubocop:disable Layout/LineLength
  end

  def presigned_upload_url(file_name, expiration = 3600)
    file_object(file_name).presigned_url(:put, expires_in: expiration)
  end

  def delete_file(file_name)
    file_object(file_name).delete
  end

  def delete_version(file_name, version)
    file_object(file_name).version(version).delete
  end

  # Deletes all versions in the S3 bucket whose prefix equals the instance's @key_prefix concatenated
  # with the file_name argument, e.g. document_pages/00007f13-fbc1-4d1d-8e02-1e23f97abf0e-9.png.
  # This is a dangerous method that can delete all of Informed's S3 production data if used incorrectly.
  # If you use this method incorrectly, and it deletes files, those files are gone forever. There is no recovering.
  # Make sure this is really the right method for you to call and make sure your arguments are correct.
  def delete_versions!(file_name)
    raise ArgumentError, '@key_prefix must be present.' unless @key_prefix.present?
    raise ArgumentError, 'file_name must be present.' unless file_name.present?

    # Verify if the object exists in s3
    return unless file_exists?(file_name)

    object_versions = @s3.bucket(bucket).object_versions(prefix: file_path(file_name))
    object_versions.batch_delete!
  end

  def all_object_versions(file_name)
    @s3.bucket(bucket).object_versions(prefix: file_path(file_name))
  end

  private

  def file_object(file_name)
    @s3.bucket(bucket).object(file_path(file_name))
  end

  def write_to_temp_file(link, tmp_file = 'tmp_file')
    tmp_file = Tempfile.new(tmp_file, '/tmp') unless tmp_file.is_a?(Tempfile)
    File.binwrite(tmp_file.path, http_client.get(link))
    tmp_file
  end

  def http_client
    return HTTP unless @proxy_url.present?
    url = URI.parse(@proxy_url)
    HTTP.via(url.host, url.port, url.user, url.password)
  end

  def file_path(file_name)
    @key_prefix.present? ? "#{@key_prefix}/#{file_name}" : file_name
  end

  def file_url(file_name)
    "https://s3.amazonaws.com/#{bucket}/#{file_path(file_name)}"
  end
end
