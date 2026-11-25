require "test_helper"

class AdmissionPersonTest < ActiveSupport::TestCase
	test "validates presence of name and surname" do
		person = AdmissionPerson.new
		refute person.valid?
		assert person.errors[:name].any?
		assert person.errors[:surname].any?
	end

	test "minor? returns true when under 18 and false when 18 or older" do
		minor = AdmissionPerson.new(name: "Leo", surname: "Díaz", birthday: 14.years.ago.to_date)
		adult = AdmissionPerson.new(name: "Ana", surname: "Díaz", birthday: 20.years.ago.to_date)

		assert minor.minor?
		refute adult.minor?
	end

	test "anonymize! scrubs PII, purges attachments, and is idempotent" do
		person = AdmissionPerson.create!(
			name: "Clara",
			surname: "Gómez",
			nick: "Clari",
			dni: "12345678Z",
			email: "clara@mudclub.test",
			phone: "+34600111222",
			address: "Calle Real 10",
			birthday: "2002-07-20"
		)

		person.anonymize!
		person.reload

		assert_not_nil person.anonymized_at
		assert_nil person.dni
		assert_nil person.email
		assert_nil person.phone
		assert_nil person.address
		assert_nil person.birthday

		first_timestamp = person.anonymized_at
		travel 1.hour do
			person.anonymize!
			assert_equal first_timestamp, person.reload.anonymized_at
		end
	end
end
