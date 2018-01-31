module ApplicationHelper
  def menu_class(path)
    'is-active' if current_page?(path)
  end

  def new_provision_class
    path = current_page?('/') ? '/' : new_provision_path
    menu_class(path)
  end
end
