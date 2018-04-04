class LessonsController < ApplicationController
  include ContentPermissioning
  include Pdfing

  breadcrumbs "Security Education" => routes.root_path,
              "Lessons" => routes.topics_path

  skip_before_action :verify_authenticity_token, only: :show

  def show
    @topic = Topic.friendly.find(params[:topic_id])
    protect_unpublished! @topic
    @lesson = @topic.lessons.with_level(params[:id]).take
    redirect_to @topic && return if @lesson.nil?

    breadcrumbs @topic.name

    og_object @lesson, description: ""

    respond_to do |format|
      format.html { render "topics/show" }
      format.js
      format.pdf do
        if Rails.env.development?
          UpdateLessonPdf.perform_now(@lesson.id)
          send_file(@lesson.reload.pdf.path, disposition: "inline")
        else
          redirect_to @lesson.pdf.url
        end
      end
    end
  end
end
