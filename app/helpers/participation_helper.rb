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
    s_stat = params[:status].presence || @status
    # s_kind = params[:kind].presence || @kind
    fields = [
      { kind: :search_text, key: :search, placeholder: title, value: params[:search].presence || session.dig("#{@kind}_filters", "search"), size: 10 },
      { kind: :search_select, key: :status, value: s_stat, blank: obj.fld(:status), options: obj.status_options },
      { kind: :hidden, key: :kind, value: @kind }
      # { kind: :search_select, key: :kind, value: obj.kind, blank: obj.fld(:kind), options: obj.kind_list }
    ]
    [ { kind: :search_box, url: search_url, fields:, cols: } ]
  end

  def participation_title(obj, title: nil, status_url: nil, just_icon: true, cols: nil)
    icon     = obj.picture
    title  ||= obj.kind_label
    subtitle = obj.to_s

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

  # standardised generator of club member field for user/player/coach
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

  # Field to use in forms to select club of a user/player/coach/team
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
      button_field({ kind: :action, symbol: symbol_hash(concept, variant:), label:, url: status_url, frame: :modal }, **f_opts)
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
        title: @member.t_path(:action, :change_status),
        cols: 2
      )
    fields.pop
    fields << [
      { kind: :select_box, key: :status, options: obj.status_list, cols: 3 }
    ]
  end

  def participation_origin
    return :team if @team
    return :club if @club
    :member if @member
  end

  def participation_base_path(origin: participation_origin, club: @club, team: @team, member: @member)
    case origin
    when :team
      club_team_path(club, team, rdx: @rdx)

    when :member
      club_member_path(club, member, rdx: @rdx)

    when :club
      club_path(club, rdx: @rdx)
    end
  end

  def participation_index_path(origin: participation_origin, club: @club, team: @team, kind: nil)
    case origin
    when :team
      club_team_roster_path(club, team, rdx: @rdx)

    else
      club_assignments_path(club, kind:, rdx: @rdx)
    end
  end
end
