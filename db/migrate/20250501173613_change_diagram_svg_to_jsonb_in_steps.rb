class ChangeDiagramSvgToJsonbInSteps < ActiveRecord::Migration[8.0]
  def up
    # Asegúrate de que todo es JSON válido
    Step.where.not(diagram_svg: [nil, ""]).find_each do |step|
      begin
        JSON.parse(step.diagram_svg)
      rescue JSON::ParserError
        raise ActiveRecord::IrreversibleMigration, "diagram_svg contiene datos inválidos en el paso ID #{step.id}"
      end
    end

    # Cambiar tipo a JSONB
    change_column :steps, :diagram_svg, 'jsonb USING diagram_svg::jsonb'
    rename_column :steps, :diagram_svg, :svgdata
  end

  def down
    # Reversión: pasar de jsonb a texto plano
    rename_column :steps, :svgdata, :diagram_svg
    change_column :steps, :diagram_svg, :text
  end
end
