class DrillsController < ApplicationController
	skip_before_action :verify_authenticity_token, :only => [:create, :new, :edit, :update, :check_reload]
	before_action :set_drill, only: %i[ show edit update destroy ]

	# GET /drills or /drills.json
	def index
		if current_user.present? and (current_user.admin? or current_user.is_coach?)
			@drills = Drill.all
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
		unless current_user.present? and (@drill.coach_id == current_user.coach_id)
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
					format.html { redirect_to drills_url, notice: "Ejercicio creado." }
					format.json { render :index, status: :created, location: @drill }
				else
					format.html { render :new, status: :unprocessable_entity }
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
						format.html { redirect_to drills_url, notice: "Ejercicio actualizado." }
						format.json { render :index, status: :ok, location: @drill }
					else
						format.html { render :edit, status: :unprocessable_entity }
						format.json { render json: @drill.errors, status: :unprocessable_entity }
					end
				else
					redirect_to drills_url, flash: "Solo el autor puede editar"
				end
			end
		else
			redirect_to "/"
		end
	end

	# DELETE /drills/1 or /drills/1.json
	def destroy
		if current_user.present? and current_user.admin?
			@drill.destroy
			respond_to do |format|
				format.html { redirect_to drills_url, notice: "Ejercicio Borrado." }
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
		check_skills(p_data[:skills_attributes]) if p_data[:skills_attributes]
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

	# Use callbacks to share common setup or constraints between actions.
	def set_drill
		@drill = Drill.find(params[:id]) unless @drill.try(:id)==params[:id]
	end

	# Only allow a list of trusted parameters through.
	def drill_params
		params.require(:drill).permit(:name, :material, :description, :coach_id, :explanation, :kind_id, skill_ids: [], skills_attributes: [:id, :name, :_destroy])
	end
end
