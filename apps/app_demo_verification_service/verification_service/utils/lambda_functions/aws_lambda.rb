module LambdaFunctions
  class AwsLambda
    TMP_S3_FOLDER = 'tmp'.freeze

    attr_reader :resource, :function_name

    def initialize(function_name)
      @function_name = "techno-core-#{ENV.fetch('Environment', 'dev')}-#{function_name}"
      @resource = Aws::Lambda::Resource.new
    end

    def execute(payload)
      resource.client.invoke(function_name: function_name, invocation_type: 'RequestResponse', payload: payload.to_json)
    end
  end
end
