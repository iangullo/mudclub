module ApplicationHelper
  def tailwind_classes_for(flash_type)
    {
      notice: "bg-blue-300 border-l-4 border-indigo-900 text-indigo-900",
      error:  "bg-red-400 border-l-4 border-red-700 text-white",
    }.stringify_keys[flash_type.to_s] || flash_type.to_s
  end
end
