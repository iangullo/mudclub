# MudClub - Simple Rails app to manage a team sports club.
# Copyright (C) 2025  Iván González Angullo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# contact email - iangullo@gmail.com.
#
module CategoriesHelper
 	# return icon and top of FieldsComponent
 	def category_title_fields(title:, rows: 2, cols: nil)
		title_start(icon: symbol_hash("category", namespace: "sport"), title:, rows:, cols:)
	end

	# FieldComponents for category.show
	def category_show_fields
		res = category_title_fields(title: I18n.t("category.single"), cols: 5, rows: 5)
		res << [
			{kind: :subtitle, value: @category.age_group, cols: 3},
			{kind: :subtitle, value: @category.sex, cols: 2}
		]
		res << [
			{kind: :label, value: I18n.t("stat.min")},
			{kind: :string, value: @category.min_years},
			gap_field,
			{kind: :label, value: I18n.t("stat.max")},
			{kind: :string, value: @category.max_years}
		]
		res
	end

	# return FieldsComponent @title for forms
	def category_form_fields(title:)
		@submit = SubmitComponent.new(submit: :save)
		res     = category_title_fields(title:, rows: 3, cols: 5)
		res << [
			{kind: :text_box, key: :age_group, value: @category.age_group, placeholder: I18n.t("category.single"), size: 10, cols: 3, mandatory: {length: 3}},
			{kind: :select_box, key: :sex, options: Category.sex_options, value: @category.sex, cols: 2}
		]
		res << [
			{kind: :label, value: I18n.t("stat.min")},
			{kind: :number_box, key: :min_years, min: 5, size: 3, value: @category.min_years, mandatory: {min: 5}},
			gap_field(size: 5),
			{kind: :label, value: I18n.t("stat.max")},
			{kind: :number_box, key: :max_years, min: 6, size: 3, value: @category.max_years, mandatory: {max: 99}}
		]
		res << [
			symbol_field("rules", {namespace: "sport"}),
			{kind: :select_box, key: :rules, options: @sport.rules_options, value: @category.rules ? @category.rules : @sport.try(:default_rules), cols: 4}
		]
		res
	end

	# return header for @categories GridComponent
	def category_grid
		title = [
			{kind: :normal, value: I18n.t("category.name")},
			{kind: :normal, value: I18n.t("sex.label")},
			{kind: :normal, value: I18n.t("stat.min")},
			{kind: :normal, value: I18n.t("stat.max")}
		]
		title <<  button_field({kind: :add, url: new_sport_category_path(@sport, rdx: @rdx), frame: "modal"}) if u_admin?

		rows = Array.new
		@categories.each { |cat|
			row = {url: edit_sport_category_path(@sport, cat, rdx: @rdx), frame: "modal", items: []}
			row[:items] << {kind: :normal, value: cat.age_group}
			row[:items] << {kind: :normal, value: I18n.t("sex.#{cat.sex}_a")}
			row[:items] << {kind: :normal, value: cat.min_years, align: "right"}
			row[:items] << {kind: :normal, value: cat.max_years, align: "right"}
			row[:items] << button_field({kind: :delete, url: sport_category_path(@sport, cat, rdx: @rdx), name: cat.name}) if u_admin?
			rows << row
		}
		{title:, rows:}
	end
end
