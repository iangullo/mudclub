# MudClub - The open source Rails platform to manage amateur sports clubs.
# Copyright (C) 2026  Iván González Angullo
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

# DocumentsController
#
# Manages documents within Mudclub.
#
class DocumentsController < ApplicationController
	include Filterable
	before_action :set_document_context

	#-------------------------------------
	# CRUD
	#-------------------------------------
	def index
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		@documents = @owner.documents
		page = paginate(@documents)
		title = helpers.document_title(subtitle: Document.label(:plural))
		table = helpers.document_table(documents: page)
		create_index(
			title:,
			table:,
			retlnk: helpers.document_owner_path
		)
	end

	def show
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		@fields = create_fields(helpers.document_show)
		@submit = create_submit(submit: helpers.edit_document_path, frame: :modal)
	end

	def new
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		prepare_form(:create)
	end

	def create
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		binding.break
		@document = @owner.documents.new(document_params)
		if @document.save
			redirect_to return_path_for(@document),
									notice: "#{@document.msg(:created)} '#{@document.title}'"
		else
			prepare_form(:create)
			render :new, status: :unprocessable_entity
		end
	end

	def edit
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		prepare_form(:edit)
	end

	def update
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		respond_to do |format|
			if @document.modified?
				if @document.save
					notice = "#{@document.msg(:updated)} '#{@document.title}'"
					register_action(:updated, notice, url: path_for(@document))
					format.html do
						redirect_to return_path_for(@document), notice:
					end
				else
					prepare_form(:edit)
					format.html { render :new, status: :unprocessable_entity }
				end
			else
					format.html do
						redirect_to return_path_for(@document),
												notice: "#{@document.msg(:unchanged)}"
					end
			end
		end
	end

	def destroy
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		notice = "#{@document.msg(:deleted)} '#{@document.title}'"
		redirect_to return_path_for(@document), notice:
	end

	#-------------------------------------
	# Administrative
	#-------------------------------------
	def activate
		@document.activate!
		redirect_to return_path_for(@document)
	end

	private

		def set_document_context
			if params[:registration_id]
				@owner = Registration.find(params[:registration_id])
			elsif params[:person_id]
				@owner = User.find_by(person_id: params[:person_id])
			elsif params[:club_id]
				@owner = Club.find(params[:club_id])
			else
				raise ActiveRecord::RecordNotFound
			end

			load_document if @owner
		end

		def load_document
			@document = @owner.documents.find_by_id(params[:id].presence)
		end

		# Helper method to prepare form for creating or editing documents
		def prepare_form(action)
			@document ||= @owner.documents.new
			fields  = helpers.document_form_fields(Document.act(action))
			@fields = create_fields(fields)
			@submit = create_submit
		end

		def document_params
			params.require(:document).permit(
				:kind,
				:title,
				:summary,
				:season_id,
				:file,
				:remarks,
				:verified,
				:verified_at,
				:active
			)
		end
end
