# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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
# Helper shared by Participation context views
module ParticipationHelper
	def participation_search_bar(obj, search_url:, title: nil, scratch: nil, cols: nil)
		search_filters = "#{obj.to_s.downcase}_filters"
		session.delete(search_filters) if scratch
		fields = [
			{ kind: :search_text, key: :search, placeholder: title, value: @search, size: 10 },
			{ kind: :search_select, key: :status, value: @status, blank: obj.fld(:status), options: obj.status_options },
			{ kind: :hidden, key: :kind, value: @kind }
			# { kind: :search_select, key: :kind, value: s_kind, blank: obj.fld(:kind), options: obj.kind_list }
		]
		[ { kind: :search_box, url: search_url, fields:, cols: } ]
	end

	def participation_title(obj, title: nil, status_url: nil, just_icon: true, cols: nil)
		icon     = obj.picture
		title  ||= obj.to_s
		subtitle = obj.kind_label

		fields = person_title(icon:, title:, subtitle:, cols:)
		fields = participation_fields(obj, fields, status_url:, just_icon:)

		fields << [
			{ kind: :string, value: date_string(obj&.birthday), class: "items-center" },
			gap_field,
			{ kind: :contact, email: obj&.email, phone: obj&.phone, device: device, align: "left", cols: 3 }
		]
	end

	def participation_fields(obj, fields, status_url: nil, just_icon: true)
		fields[0] += [
			gap_field,
			participation_club_field(obj, align: :left),
			gap_field,
			participation_kind_field(obj, align: :right)
		]
		fields[1] += [
			gap_field,
			participation_status_field(obj, status_url:, just_icon:, f_opts: { align: :left, cols: 3 })
		]
		fields
	end

	# standardised generator of club member field for member/assignment
	def participation_club_field(obj, align: "center")
		if obj&.club
			icon  = obj.club.logo
			title = obj.club.nick
			label = Assignment.fld(:shirt_number_short) + obj.number.to_s if obj.is_a?(Player)
			{ kind: :icon_label, icon:, title:, label:, align: }
		else
			{ kind: :string, value: "(#{Club.fld(:none)})",	dclass: "font-semibold text-gray-500 justify-center",	align: }
		end
	end

	# Field to use in forms to select club of a assignment/coach/team
	def participation_club_selector(obj, align: "center")
		[
			{ kind: :icon, icon: "mudclub.svg", title: ("club.single"), align: },
			{ kind: :select_box, key: :club_id, options: current_user.club_list, value: obj.club_id, cols: 4, align: }
		]
	end

	# object kind field - obj class must implement picture/kind_label
	def participation_kind_field(obj, align: "center", class: nil)
		concept = obj.kind_image
		title   = obj.kind_label(:hint)

		symbol_field(concept, { title: }, align:, class:)
	end

	# object status field - obj class expected to have Partipatory included
	def participation_status_field(obj, f_opts: nil, status_url: nil, just_icon: true)
		concept = :status
		variant = obj.status
		label   = obj.status_label(:short)
		s_date  = date_string(
			case obj.status
			when :active then obj.starts_on
			when :terminated then obj.ends_on
			else
				obj.updated_at
			end
		)

		if status_url
			frame = :modal unless obj.kind.to_sym == :board_member
			button_field({ kind: :action, symbol: symbol_hash(concept, variant:), label:, url: status_url, frame: }, **f_opts)
		elsif just_icon
			title = "(#{s_date})"
			symbol_field(concept, { variant:, title: "#{label}\n#{title}" }, **f_opts)
		else
			title = s_date
			{ kind: :icon_label, symbol: symbol_hash(concept, variant:, title:), label:, **f_opts }
		end
	end

	def participation_status_form_fields(obj)
		fields = participation_title(
				@member,
				title: @member.act(:change_status),
				cols: 2
			)
		fields.pop
		fields << [
			{ kind: :select_box, key: :status, options: obj.status_list, cols: 3 }
		]
	end

	# attempt at unified definition for Assignment/Membership tables
	def participation_table(objects, kind: @kind)
		return nil if objects == nil || objects.empty?
		p_class = objects&.first
		o_class = p_class&.model_name&.singular_route_key.to_sym
		{
			title: participation_table_header(p_class, o_class, kind&.to_sym),
			rows: participation_table_rows(o_class, objects, kind&.to_sym)
		}
	end

	def participation_origin
		return :team   if @team
		return :member if @member
		:club
	end

	def participation_base_path(origin: participation_origin)
		path_for(participation_anchor(origin), rdx: @rdx)
	end

	def participation_index_path(origin: participation_origin, club: @club, team: @team, kind: nil, search: nil)
		case origin
		when :team
			club_team_roster_path(club, team, search:, rdx: @rdx)
		when :club
			club_assignments_path(club, kind:, search:, rdx: @rdx)
		when :member  # dicussion on whether this makes sense in future
			club_member_path(@member.club, @member, kind:, search:, rdx: @rdx)
		end
	end

	private
		def participation_anchor(origin)
			case origin
			when :team   then @team
			when :member then @member
			when :club   then @club
			end
		end

		# p_class should be Membership or Assignment - maybe Registration in future
		def participation_table_header(p_class, o_class, kind)
			header = kind ? [] : [ { kind: :normal, value: p_class.fld(:kind, :short) } ]
			if kind == :board_member
				header << { kind: :normal, value: Assignment.fld(:role) }
			elsif kind == :athlete
				header << { kind: :normal, value: Assignment.fld(:number, :short) }
			end
			header << { kind: :normal, value: Person.fld(:name) }
			header << { kind: :normal, value: Person.fld(:age) } if [ :athlete, :coach ].include?(@kind)

			header += [
				{ kind: :normal, value: p_class.fld(:starts_on, :short) },
				{ kind: :normal, value: p_class.fld(:status) }
			]
			header << button_field({ kind: :add, url: new_path_for(@club, o_class, kind: @kind), frame: :modal }) if @policy.new?
			header
		end

		def participation_table_rows(o_class, objects, kind)
				rows    = Array.new
				frame   = :modal if o_class == :assignment
				objects.each { |object|
					m_obj = (o_class == :member ? object : object&.membership)
					a_obj = (o_class == :assignment ? object : object&.assignments&.last)
					row   = { url: path_for(object, rdx: 3), items: [], frame: }
					case kind
					when :athlete
						row[:items] << { kind: :normal, value: a_obj.number }
					when :board_member
						row[:items] << { kind: :normal, value: a_obj.kind_label }
					when nil
						row[:items] << participation_kind_field(object, class: "border px py")
					end
					row[:items] << { kind: :normal, value: object.s_name }
					row[:items] << { kind: :normal, value: object.age, align: :center } if [ :athlete, :coach ].include?(m_obj.kind.to_sym)
					row[:items] << { kind: :normal, value: object.starts_on }
					row[:items] << participation_status_field(object, f_opts: { align: :center, class: "border px py" })
					rows << row
				}
				rows
		end
end
