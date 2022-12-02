FROM public.ecr.aws/lambda/ruby:2.7

RUN yum groupinstall -y "Development Tools" \
  && yum clean metadata \
  && yum clean all -y

# RUN amazon-linux-extras install ruby3.0
RUN yum install -y ruby-devel git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel
RUN yum -y install cmake curl-dev libcurl

COPY Gemfile ${LAMBDA_TASK_ROOT}/
COPY Gemfile.lock ${LAMBDA_TASK_ROOT}/

WORKDIR ${LAMBDA_TASK_ROOT}

RUN gem install bundler -v 2.2.32

RUN bundle install --deployment --jobs 12 --retry 3

COPY app_demo_verification_service ${LAMBDA_TASK_ROOT}/app_demo_verification_service
COPY app_demo_verification_service.rb ${LAMBDA_TASK_ROOT}/
COPY setup_verification_service.rb ${LAMBDA_TASK_ROOT}/

CMD [ "app_demo_verification_service.VerificationService.handler" ]
