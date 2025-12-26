class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  layout :layout_by_resource

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def switch_locale
    session[:locale] = params[:locale] if params[:locale].present?
    redirect_back(fallback_location: root_path)
  end

  private

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end
end
