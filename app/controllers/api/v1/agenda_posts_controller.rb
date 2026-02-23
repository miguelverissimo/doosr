module Api
  module V1
    class AgendaPostsController < Api::BaseController
      before_action :authorize_agenda_access!

      resource_description do
        short "Agenda Posts"
        description "Create agenda posts (appointments, study plans, etc.)"
        meta group: "Agenda"
        formats [ "json" ]
      end

      api :POST, "/agenda_posts", "Create an agenda post"
      description "Creates a new agenda post of the specified type."
      param :type, String, desc: "Post type: 'appointment' or 'study_plan'", required: true
      param :data, Hash, desc: "Post data with entries array", required: true do
        param :entries, Array, desc: "Array of entry objects (schema varies by type)", required: true
      end
      def create
        klass = post_class_for(params[:type])
        unless klass
          render_error("Invalid type. Must be 'appointment' or 'study_plan'", status: :unprocessable_entity)
          return
        end

        post = klass.new(user: current_user, data: data_params)
        if post.save
          render json: { data: serialize_post(post), meta: {} }, status: :created
        else
          render_error(
            post.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: post.errors.full_messages
          )
        end
      end

      private

      def authorize_agenda_access!
        authorize_feature!(:agenda)
      end

      def post_class_for(type)
        {
          "appointment" => AgendaPost::Appointment,
          "study_plan" => AgendaPost::StudyPlan
        }[type]
      end

      def data_params
        # For JSONB data, we permit the structure and let model validation handle schema
        data = params.require(:data)
        if data.is_a?(ActionController::Parameters)
          data.permit!.to_h
        else
          data.to_unsafe_h
        end
      end

      def serialize_post(post)
        {
          id: post.id,
          type: post.type.demodulize.underscore,
          data: post.data,
          created_at: post.created_at.iso8601,
          updated_at: post.updated_at.iso8601
        }
      end
    end
  end
end
