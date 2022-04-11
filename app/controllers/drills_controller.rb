class DrillsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :edit, :update, :check_reload]
	before_action :set_drill, only: %i[ show edit update destroy ]

	# GET /drills or /drills.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			# Simple search by name/description for now
			@drills = Drill.search(params[:search])
		else
			redirect_to "/"
		end
	end

	# GET /drills/1 or /drills/1.json
	def show
		unless current_user.present? and (current_user.admin? or current_user.is_coach?)
			redirect_to "/"
		end
	end

	# GET /drills/new
	def new
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@drill = Drill.new
		else
			redirect_to "/"
		end
	end

	# GET /drills/1/edit
	def edit
		unless current_user.present? and (@drill.coach_id == current_user.person.coach_id)
			redirect_to drills_url
		end
	end

	# POST /drills or /drills.json
	def create
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			respond_to do |format|
				@drill = Drill.new
				rebuild_drill(params)	# rebuild drill
				if @drill.save
					format.html { redirect_to drills_url }
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
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			respond_to do |format|
				rebuild_drill(params)	# rebuild drill
				if @drill.coach_id == current_user.person.coach_id # author can modify
					if @drill.save
						format.html { redirect_to drills_url }
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
			@drill.drill_targets.each { |d_t| dt.delete }
			@drill.destroy
			respond_to do |format|
				format.html { redirect_to drills_url }
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
	# build new @drill from raw input given by submittal from "new"
	# return nil if unsuccessful
	def rebuild_drill(params)
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
			s[1][:name] = s[1][:name].mb_chars.titleize
			a_skills << s[1] unless a_skills.detect { |a| a[:name] == s[1][:name] }
		}
		a_skills.each { |s| # second pass - manage associations
			if s[:_destroy] == "1"
				@drill.skills.delete(s[:id])
			else
				unless s.key?("id")	# if no id included, we check
					sk = Skill.find_by(name: s[:name])
					sk = Skill.create(name: s[:name]) unless sk
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
				@drill.targets.delete(t[:id])
			else
				dt = DrillTarget.fetch(t)
				@drill.drill_targets ? @drill.drill_targets << dt : @drill.drill_targets |= dt
			end
		}
	end

	# search all drills for specific subsets
	# NOT WORKING!! - disable for now
	def search(search=nil)
		if search
			if search.length > 0
				res = search_skill(search)
				res = search_kind(res, search)
				res = search_name(res, search)
			else
				res = Drill.all
			end
		else
			res = Drill.all
		end
		res.order(:kind_id)
	end

	# filter for fundamentals
	def search_skill(res=Drill.all, search)
		s_s = search.scan(/f:(\w+)/)
		if s_s # matched something
			return s_s.empty? ? res : Skill.search_drills(s_s.first.first)
		else
			return res
		end
	end

	# filter drills by kind
	def search_kind(res=Drill.all, search)
		s_k = search.scan(/t:(\w+)/)
		if s_k	# matched something
			res = s_k.empty? ? res : res.where(kind_id: Kind.find_by(name: s_k.first.first).id)
		else
			return res
		end
	end

	# filter by name/description
	def search_name(res=Drill.all, search)
		s_n = search.scan(/\s*(.+)\sf:\w+|\st:\w+/)
		if s_n # matched something
		unless s_n.empty?
					s_n = s_n.first.first
				res = res.where("unaccent(name) ILIKE unaccent(?) OR unaccent(description) ILIKE unaccent(?)","%#{s_n}%","%#{s_n}%")
			else
				return res
			end
		end
	end

	# Use callbacks to share common setup or constraints between actions.
	def set_drill
		@drill = Drill.find(params[:id]) unless @drill.try(:id)==params[:id]
	end

	# Only allow a list of trusted parameters through.
	def drill_params
		params.require(:drill).permit(:name, :material, :description, :coach_id, :explanation, :playbook, :kind_id, target_ids: [], skill_ids: [], skills_attributes: [:id, :name, :_destroy], drill_targets_attributes: [:id, :priority, :drill_id, :target_id, :_destroy], targets_attributes: [:id, :concept])
	end
end
