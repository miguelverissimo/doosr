# frozen_string_literal: true

class AgendaController < ApplicationController
  before_action :authenticate_user!
  before_action { authorize! :access, :agenda }
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def show
    @posts = latest_posts_by_type

    render ::Views::Agenda::Show.new(posts: @posts)
  end

  private

  def latest_posts_by_type
    current_user.agenda_posts
                .select("DISTINCT ON (type) *")
                .order("type, created_at DESC")
  end
end
