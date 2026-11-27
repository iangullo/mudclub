require "test_helper"

class PersonDataTest < ActiveSupport::TestCase
	test "age and minor? calculate accurately across birthday boundary" do
		minor = Person.new(name: "A", surname: "B", birthday: 17.years.ago.to_date)
		adult = Person.new(name: "C", surname: "D", birthday: 18.years.ago.to_date)

		assert minor.minor?
		refute adult.minor?
		assert_equal 0, Person.new(name: "E", surname: "F").age
	end

	test "idpics_attached? requires both id_front and id_back" do
		person = Person.create!(name: "A", surname: "B")
		refute person.idpics_attached?

		attach_test_image(person, :id_front, filename: "front.png")
		refute person.idpics_attached?

		attach_test_image(person, :id_back, filename: "back.png")
		assert person.idpics_attached?
	end

	test "person_attributes with include_attachments folds in attached blobs" do
		person = Person.create!(name: "Ana", surname: "Gil", dni: "12345678Z")
		blob   = attach_test_image(person, :avatar, filename: "ana.png")

		attrs = person.person_attributes(include_attachments: true)
		assert_equal "Ana", attrs[:name]
		assert_equal blob, attrs[:avatar]
	end
end
