class DrillsController < ApplicationController
  include Filterable
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :edit, :update, :check_reload]
	before_action :set_drill, only: %i[ show edit update destroy ]

	# GET /drills or /drills.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			# Simple search by name/description for now
			@title  = title_fields(I18n.t(:l_drill_index))
	    @title << [
				{kind: "search-text", key: :name, value: session.dig('drill_filters', 'name'), url: drills_path},
				{kind: "search-select", key: :kind_id, options: Kind.real.pluck(:name, :id), url: drills_path}
			]
			@drills = filter!(Drill)
			@grid   = GridComponent.new(grid: drill_grid)
		else
			redirect_to "/"
		end
	end

	# GET /drills/1 or /drills/1.json
	def show
		unless current_user.present? and (current_user.admin? or current_user.is_coach?)
			redirect_to "/"
		end
		@title  = title_fields(I18n.t(:l_drill_show))
		@title.last << {kind: "link", align: "right", icon: "playbook.png", size: "20x20", url: rails_blob_path(@drill.playbook, disposition: "attachment"), label: "Playbook"} if @drill.playbook.attached?
		@title << [{kind: "subtitle", value: @drill.name}, {kind: "string", value: "(" + @drill.kind.name + ")", cols: 2}]
		@intro  = [[{kind: "label", value: I18n.t(:l_targ)}, {kind: "lines", class: "align-top", value: @drill.drill_targets}]]
		@intro << [{kind: "label", value: I18n.t(:l_mat)}, {kind: "string", value: @drill.material}]
		@intro << [{kind: "label", value: I18n.t(:l_desc)}, {kind: "string", value: @drill.description}]
		@explain = [[{kind: "string", value: @drill.explanation}]]
		@tail = [[{kind: "label", value: I18n.t(:l_skill)}, {kind: "string", value: @drill.print_skills}]]
		@tail << [{kind: "label", value: I18n.t(:l_auth)}, {kind: "string", value: @drill.coach.s_name}]
	end

	# GET /drills/new
	def new
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@drill = Drill.new
			@title = title_fields(I18n.t(:l_drill_new))
			@form_fields = form_fields
		else
			redirect_to "/"
		end
	end

	# GET /drills/1/edit
	def edit
		unless current_user.present? and (current_user.admin? or (@drill.coach_id == current_user.person.coach_id))
			redirect_to drills_url
		end
		@title = title_fields(I18n.t(:l_drill_edit))
		@form_fields = form_fields
	end

	# POST /drills or /drills.json
	def create
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			respond_to do |format|
				@drill = Drill.new
				rebuild_drill	# rebuild drill
				if @drill.save
					format.html { redirect_to drills_url, notice: "#{I18n.t(:drill_created)} '#{@drill.name}'" }
					format.json { render :index, status: :created, location: @drill }
				else
					format.html { render :new }
					format.json { render json: @drill.errors, status: :unprocessable_entity }
				end
			end
		else
			redirect_to "/"
		end
	end

	# PATCH/PUT /drills/1 or /drills/1.json
	def update
		if current_user.present? and (current_user.admin? or (@drill.coach_id == current_user.person.coach_id))
			respond_to do |format|
				rebuild_drill	# rebuild drill
				if @drill.coach_id == current_user.person.coach_id # author can modify
				 	if @drill.save
						format.html { redirect_to drills_url, notice: "#{I18n.t(:drill_updated)} '#{@drill.name}'" }
						format.json { render :index, status: :ok, location: @drill }
					else
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @drill.errors, status: :unprocessable_entity }
					end
				else
					redirect_to drills_url
				end
			end
		else
			redirect_to "/"
		end
	end

	# DELETE /drills/1 or /drills/1.json
	def destroy
		if current_user.present? and current_user.admin?
			d_name = @drill.name
			@drill.drill_targets.each { |d_t| d_t.delete }
			@drill.destroy
			respond_to do |format|
				format.html { redirect_to drills_url, notice: "#{I18n.t(:drill_deleted)} '#{d_name}'" }
				format.json { head :no_content }
			end
		else
			redirect_to "/"
		end
	end

	def explanation
		render partial: 'drills/explanation', locals: { drill: @drill }
	end

	private

		# return icon and top of FieldsComponent
		def title_fields(title, rows: nil, cols: nil)
			title_start(icon: "drill.svg", title: title, rows: rows, cols: cols)
		end

		# return FormComponent @fields for edit/new
		def form_fields
			@title << [{kind: "text-box", key: :name, value: @drill.name}, {kind: "select-collection", key: :kind_id, options: Kind.all, value: @drill.kind_id, align: "center"}]
			@playbook = [[{kind: "select-file", icon: "playbook.png", label: "Playbook", key: :playbook, value: @drill.playbook.filename.to_s}]]
			return [
				# DO WE INCLUDE NESTED FORM TYPE??? HOW?
				# NESTED FORM for Targets...
				[{kind: "label", value: I18n.t(:l_mat), align: "right"}, {kind: "text-box", key: :material, size: 40, value: @drill.material}],
				[{kind: "label", value: I18n.t(:l_desc), align: "right"}, {kind: "text-area", key: :description, size: 40, lines: 2, value: @drill.description}],
				[{kind: "rich-text-area", key: :explanation, align: "left", cols: 2}],
				# NESTED FORM for Skills...
				[{kind: "label", value: I18n.t(:l_auth), align: "right"}, {kind: "select-collection", key: :coach_id, options: Coach.active}]
		]
		end

		# return grid for @drills GridComponent
	  def drill_grid
			track = {s_url: drills_path, s_filter: "drill_filters"}
	    title = [
				{kind: "normal", value: I18n.t(:h_name), sort: (session.dig('drill_filters', 'name') == "name"), order_by: "name"},
	      {kind: "normal", value: I18n.t(:h_kind), align: "center", sort: (session.dig('drill_filters', 'kind_id') == "kind_id"), order_by: "kind_id"},
	      {kind: "normal", value: I18n.t(:h_targ)}
	    ]
			title << {kind: "add", url: new_drill_path, turbo: "modal"} if current_user.admin? or current_user.is_coach?

			{track: track, title: title, rows: drill_rows}
	  end

		# get the grid rows for @drills
		def drill_rows
			rows = Array.new
	    @drills.each { |drill|
	      row = {url: drill_path(drill), turbo: "modal", items: []}
	      row[:items] << {kind: "normal", value: drill.name}
	      row[:items] << {kind: "normal", value: drill.kind.name, align: "center"}
	      row[:items] << {kind: "lines", value: drill.print_targets}
	      row[:items] << {kind: "delete", url: row[:url], name: drill.name} if current_user.admin?
	      rows << row
	    }
			rows
		end

		# build new @drill from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_drill
			p_data = params.fetch(:drill)
binding.break
			@drill.name        = p_data[:name]
			@drill.description = p_data[:description]
			@drill.material    = p_data[:material]
			@drill.coach_id    = p_data[:coach_id]
			@drill.kind_id     = p_data[:kind_id]
			@drill.explanation = p_data[:explanation]
			@drill.playbook    = p_data[:playbook]
			check_skills(p_data[:skills_attributes]) if p_data[:skills_attributes]
			check_targets(p_data[:drill_targets_attributes]) if p_data[:drill_targets_attributes]
			@drill
		end

		# checks skills parameter received and manage adding/removing
		# from the drill collection - remove duplicates from list
		def check_skills(s_array)
			a_skills = Array.new	# array to include only non-duplicates
			s_array.each { |s| # first pass
				#s[1][:name] = s[1][:name].mb_chars.titleize
				a_skills << s[1] unless a_skills.detect { |a| a[:name] == s[1][:name] }
			}
			a_skills.each { |s| # second pass - manage associations
				if s[:_destroy] == "1"
					@drill.skills.delete(s[:id].to_i)
				else
					unless s.key?("id")	# if no id included, we check
						sk = Skill.find_by(concept: s[:concept])
						sk = Skill.create(concept: s[:concept]) unless sk
						@drill.skills << sk	# add to collection
					end
				end
			}
		end

		# checks targets_attributes parameter received and manage adding/removing
		# from the target collection - remove duplicates from list
		def check_targets(t_array)
			a_targets = Array.new	# array to include only non-duplicates
			t_array.each { |t| # first pass
				a_targets << t[1] unless a_targets.detect { |a| a[:target_attributes][:concept] == t[1][:target_attributes][:concept] }
			}
			a_targets.each { |t| # second pass - manage associations
				if t[:_destroy] == "1"	# remove drill_target
					@drill.targets.delete(t[:target_attributes][:id])
				else
					dt = DrillTarget.fetch(t)
					@drill.drill_targets ? @drill.drill_targets << dt : @drill.drill_targets |= dt
				end
			}
		end

		# Use callbacks to share common setup or constraints between actions.
		def set_drill
			@drill = Drill.find(params[:id]) unless @drill.try(:id)==params[:id]
		end

		# Only allow a list of trusted parameters through.
		def drill_params
			params.require(:drill).permit(:name, :material, :description, :coach_id, :explanation, :playbook, :kind_id, target_ids: [], skill_ids: [], skills_attributes: [:id, :concept, :_destroy], drill_targets_attributes: [:id, :priority, :drill_id, :target_id, :_destroy], targets_attributes: [:id, :concept])
		end
end
