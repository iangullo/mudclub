class EnableUnaccent < ActiveRecord::Migration[7.0]
  def change
    exec_query("CREATE EXTENSION IF NOT EXISTS \"unaccent\"").tap {
      reload_type_map
    }
  end
end
