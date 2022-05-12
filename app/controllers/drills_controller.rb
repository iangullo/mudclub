class DrillsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :edit, :update, :check_reload]
	before_action :set_drill, only: %i[ show edit update destroy ]

	# GET /drills or /drills.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			# Simple search by name/description for now
			@drills        = Drill.search(params[:search])
			@header_fields = header_fields(I18n.t(:l_drill_index))
	    @header_fields << [{kind: "text-search", url: drills_path}]
			@grid = drill_grid
		else
			redirect_to "/"
		end
	end

	# GET /drills/1 or /drills/1.json
	def show
		unless current_user.present? and (current_user.admin? or current_user.is_coach?)
			redirect_to "/"
		end
		@header_fields = header_fields(I18n.t(:l_drill_show), rows: 3)
		@header_fields << [{kind: "subtitle", value: @drill.name}, {kind: "string", value: "(" + @drill.kind.name + ")"}]
	end

	# GET /drills/new
	def new
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@drill         = Drill.new
			@header_fields = header_fields(I18n.t(:l_drill_new))
			@form_fields   = form_fields
		else
			redirect_to "/"
		end
	end

	# GET /drills/1/edit
	def edit
		unless current_user.present? and (current_user.admin? or (@drill.coach_id == current_user.person.coach_id))
			redirect_to drills_url
		end
		@header_fields = header_fields(I18n.t(:l_drill_edit))
		@form_fields   = form_fields
	end

	# POST /drills or /drills.json
	def create
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			respond_to do |format|
				@drill = Drill.new
				rebuild_drill	# rebuild drill
				if @drill.save
					format.html { redirect_to drills_url, notice: t(:drill_created) + "'#{@drill.name}'" }
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
						format.html { redirect_to drills_url, notice: t(:drill_updated) + "'#{@drill.name}'" }
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
				format.html { redirect_to drills_url, notice: t(:drill_deleted) + "'#{d_name}'" }
				format.json { head :no_content }
			end
		else
			redirect_to "/"
		end
	end

	def autocompletable_skills
		aux = ""
		Skill.all.each { |s|
			aux += '<li class="list-group-item" role="option" data-autocomplete-value="#{s.id}">Blackbird</li>\n'
		}
		aux
	end

	def explanation
		render partial: 'drills/explanation', locals: { drill: @drill }
	end

	private

		# return icon and top of FieldsComponent
		def header_fields(title, cols: nil)
			[[{kind: "header-icon", value: "drill.svg"}, {kind: "title", value: title, cols: cols}]]
		end

		# return FormComponent @fields for edit/new
		def form_fields
			return [
				# DO WE INCLUDE NESTED FORM TYPE??? HOW?
				# NESTED FORM for Targets...
				[{kind: "label", value: I18n.t(:l_mat), align: "right"}, {kind: "text-box", key: :material, size: 40, value: @drill.material, cols: 3}],
				[{kind: "label", value: I18n.t(:l_desc), align: "right"}, {kind: "text-area", key: :description, size: 40, lines: 2, value: @drill.material, cols: 3}],
				[{kind: "label", value: I18n.t(:l_expl), align: "left", cols: 3}, {kind: "select-file", align: "right", icon: "playbook.png", label: "Playbook", key: :playbook}],
				[{kind: "rich-text-area", key: :explanation, align: "left", cols: 4}],
				# NESTED FORM for Skills...
				[{kind: "label", value: I18n.t(:l_auth), align: "right"}, {kind: "select-collection", key: :coach_id, collection: Coach.active}]
		]
		end

		# return grid for @drills GridComponent
	  def drill_grid
	    head = [
				{kind: "normal", value: I18n.t(:h_name)},
	      {kind: "normal", value: I18n.t(:h_kind), align: "center"},
	      {kind: "normal", value: I18n.t(:h_targ)}
	    ]
			head << {kind: "add", url: new_drill_path, turbo: "modal"} if current_user.admin? or current_user.is_coach?

	    rows = Array.new
	    @drills.each { |drill|
	      row = {url: drill_path(drill), turbo: "modal", items: []}
	      row[:items] << {kind: "normal", value: drill.name}
	      row[:items] << {kind: "normal", value: drill.kind.name, align: "center"}
	      row[:items] << {kind: "lines", value: drill.print_targets}
	      row[:items] << {kind: "delete", url: row[:url], name: drill.name} if current_user.admin?
	      rows << row
	    }
			{header: head, rows: rows}
	  end

		# build new @drill from raw input given by submittal from "new"
		# return nil if unsuccessful
		def rebuild_drill
			p_data = params.fetch(:drill)
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
