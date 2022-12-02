module Serializers
  module StipVerifications
    class Response
      using Refinements::HashTransformations

      REJECT_QUESTIONS = /application_has_potential*/i.freeze
      REJECT_DOCUMENT_QUESTIONS = /income_paystub_does_not_/i.freeze
      DOCUMENT_MISSING_QUESTIONS = /no_acceptable_documents/i.freeze
      DOCUMENT_BLURRY_QUESTIONS = /document_image_quality_not_acceptable/i.freeze
      STRUCTURED_DATA = 'structured_data'.freeze

      def self.serialize(application, payload, job_id, timestamp)
        new(application, payload, job_id, timestamp).serialize
      end

      attr_reader :application, :payload

      def initialize(application, payload, job_id, timestamp)
        @application = application
        @payload = payload
        @job_id = job_id
        @timestamp = timestamp
      end

      def serialize
        preprocess.underscore_keys
      end

      private

      def preprocess
        serialized_verifications = payload&.each_with_object({}) do |(stip_type, value), response|
          response[stip_type] = []
          value.each do |val|
            result = val[:result]
            verifications = val[:verifications]
            applicant_id = val[:applicant_id]
            description = val[:description]
            relevant_docs = val.dig(:result, :relevant_docs)&.flatten || []
            # TODO: we'll make it application later
            belongs_to = ApplicationFundingEngine::Driver::DEALER_STIPS.keys.include?(stip_type.to_sym) ? 'application' : applicant_id # rubocop:disable Layout/LineLength
            response[stip_type] << {
              status:                 result[:status],
              belongs_to:             belongs_to,
              updated_at:             @timestamp,
              description:            description,
              verification_questions: stipulation_questions(applicant_id, verifications),
              acceptable_documents:   acceptable_documents(applicant_id, verifications, relevant_docs, result[:status]),
              recommendations:        recommendations(applicant_id, result, verifications)
            }
          end
        end
        {
          data_sources:  data_sources,
          verifications: serialized_verifications
        }
      end

      def data_sources
        image_files = {}
        structured_data = []
        application.documents.each do |doc|
          if doc.input_source == STRUCTURED_DATA
            structured_data << { document_id: doc.id, document_reference_id: doc.document_reference_id }
          else
            # Attach file_ids and file_reference_ids by index
            doc.file_ids.zip(doc.file_reference_ids).each do |file_id, file_reference_id|
              # Dictionary will not allow duplicate file_ids to be added
              image_files[file_id] = { file_id: file_id, file_reference_id: file_reference_id }
            end
          end
        end
        {
          image_files:     image_files.values,
          structured_data: structured_data
        }
      end

      def stipulation_questions(applicant_id, verifications)
        vers = verifications.select { |ver| ver[:verification_type] == :stipulation }
        vers = vers.reject { |v| v[:question]&.match?(REJECT_QUESTIONS) }
        vers.each_with_object({}) do |detail, result|
          info = { name: full_name(applicant(applicant_id)) }
          document_question_key = ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get(
            'ferrite', ['question_check_list', detail[:question].to_s, 'question_key'], info
          )
          engligh_question = ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get(
            'ferrite', ['question_check_list', detail[:question].to_s, 'question'], info
          )
          status = detail[:status] || false
          result[document_question_key] = {
            question:  engligh_question,
            expected:  detail[:answer]&.second,
            answer:    detail[:answer]&.first,
            status:    status,
            serialize: detail[:serialize]
          }
        end
      end

      def acceptable_documents(applicant_id, verifications, relevant_docs, status)
        # If the stip status is pass, only use serialize income calculated documents
        if status == :pass
          verifications = verifications.select do |ver|
            ver[:verification_type] == :document && relevant_docs.include?(ver[:document_id])
          end
        end

        vers = verifications.select { |ver| ver[:verification_type] == :document }
        vers = vers.reject { |v| v[:question]&.match?(REJECT_DOCUMENT_QUESTIONS) }
        acceptable_documents = vers.group_by { |ver| ver[:document_type] }
        acceptable_documents.each_with_object({}) do |(key, questions), result|
          info = { name: full_name(applicant(applicant_id)), document: sanitize_document_types([key.to_s]) }
          groups = questions.group_by { |q| q[:document_id] }.values
          result[key] = groups.map do |group|
            document_questions = group.each_with_object({}) do |q, obj|
              document_question_key = ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get(
                'ferrite', ['question_check_list', q[:question].to_s, 'question_key'], info
              )
              engligh_question = ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get(
                'ferrite', ['question_check_list', q[:question].to_s, 'question'], info
              )
              obj[document_question_key] = {
                question:  engligh_question,
                expected:  q[:answer]&.second,
                answer:    q[:answer]&.first,
                status:    q[:status],
                serialize: q[:serialize]
              }
            end
            {
              document_id:        group.first[:document_id],
              file_ids:           group.first[:file_ids],
              file_reference_ids: group.first[:file_reference_ids],
              category:           document_label(group.first[:label]),
              document_questions: document_questions
            }
          end
        end
      end

      def recommendations(applicant_id, result, verifications)
        return [] if result[:status] == :pass || result[:status] == :waived

        vers = verifications.select { |v| v[:recommendation] }
        return [] if vers.blank?

        return missing_recommendations(applicant_id, vers) if result[:status] == :missing

        recommendations = []
        relevant_doc_ids = result[:relevant_docs]&.flatten&.compact || []

        # When the relevant documents are blurry
        blurry_doc_ids = blurry_relevant_docs(vers, relevant_doc_ids)
        recommendations += blurry_recommendations(applicant_id, vers, blurry_doc_ids)

        # Remove the blurry_doc_ids from relevant_doc_ids
        relevant_doc_ids = relevant_doc_ids - blurry_doc_ids + [nil]
        vers = vers.select { |v| relevant_doc_ids.include?(v[:document_id]) }

        info = { name: full_name(applicant(applicant_id)) }
        recommendations += vers.map do |v|
          ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get('ferrite', ['question_check_list', v[:question], 'recommendation'], info.merge!(document: sanitize_document_types([v[:label]]))) # rubocop:disable Layout/LineLength
        end.compact

        recommendations.compact
      end

      def missing_recommendations(applicant_id, verifications)
        verification = verifications.select { |v| v[:question]&.match?(DOCUMENT_MISSING_QUESTIONS) }.first
        return [] if verification.blank?
        info = { name: full_name(applicant(applicant_id)), document: sanitize_document_types(verification[:answer]) }
        [ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get(
          'ferrite', ['question_check_list', verification[:question], 'recommendation'], info
        )]
      end

      def sanitize_document_types(types)
        clean_doc_types = types.flatten.select(&:present?).map do |type|
          document_label(type) || type&.split('_')&.map(&:capitalize)&.join(' ')
        end
        clean_doc_types.join(' or ')
      end

      def document_label(label)
        ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get('ferrite',
                                                                            ['custom_documents', label]) || label
      end

      def blurry_relevant_docs(verifications, relevant_doc_ids)
        blurry_verifications(verifications, relevant_doc_ids).map { |v| v[:document_id] }.uniq
      end

      def blurry_recommendations(applicant_id, verifications, relevant_doc_ids)
        verifications = blurry_verifications(verifications, relevant_doc_ids)
        return [] if verifications.blank?
        verifications.map do |v|
          info = { name: full_name(applicant(applicant_id)), document: sanitize_document_types([v[:label]]) }
          ApplicationFundingEngine::Helpers::VerificationGuidelinesHelper.get(
            'ferrite', ['question_check_list', v[:question], 'recommendation'], info
          )
        end
      end

      def blurry_verifications(verifications, relevant_doc_ids)
        verifications.select { |v| v[:question]&.match?(DOCUMENT_BLURRY_QUESTIONS) && relevant_doc_ids.include?(v[:document_id]) } # rubocop:disable Layout/LineLength
      end

      def applicant(applicant_id)
        application.applicants.find { |a| a.id == applicant_id }
      end

      def full_name(applicant)
        "#{applicant.first_name} #{applicant.last_name}"
      end
    end
  end
end
