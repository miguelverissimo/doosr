module Api
  module V1
    class AgendaController < Api::BaseController
      before_action :authorize_agenda_access!

      resource_description do
        short "Agenda"
        description "View latest agenda posts by type"
        meta group: "Agenda"
        formats [ "json" ]
      end

      api :GET, "/agenda", "Get latest agenda posts"
      description "Returns the most recent post of each type for the current user."
      def show
        posts = latest_posts_by_type

        render json: {
          data: posts.map { |post| serialize_post(post) },
          meta: {}
        }, status: :ok
      end

      private

      def authorize_agenda_access!
        authorize_feature!(:agenda)
      end

      def latest_posts_by_type
        AgendaPost.where(user: current_user)
                  .select("DISTINCT ON (type) *")
                  .order("type, created_at DESC")
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
