class UpdateCategorySexToEnum < ActiveRecord::Migration[7.0]
  def up
    Category.where(sex: 'Masc.').update_all(sex: :male)
    Category.where(sex: 'Fem.').update_all(sex: :female)
    Category.where(sex: 'Mixto').update_all(sex: :mixed)
    # You can set "mixed" for existing categories that don't have a specific sex value
    Category.where(sex: nil).update_all(sex: :mixed)
  end

  def down
    Category.where(sex: :male).update_all(sex: 'Masc.')
    Category.where(sex: :female).update_all(sex: 'Fem.')
    Category.where(sex: :mixed).update_all(sex: 'Mixto')
  end
end
