class ApplicationController < ActionController::Base
  def redirect_unlogged
    if current_user.present?
      format.html { redirect_to new_session_path, flash: 'Necesita registrarse.' }
      format.json { render :index, status: :ok, location: new_session_path }
    end
  end
end
