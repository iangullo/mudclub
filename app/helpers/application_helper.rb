module ApplicationHelper
  def create_topbar
     TopbarComponent.new(user: user_signed_in? ? current_user : nil)
  end
end
