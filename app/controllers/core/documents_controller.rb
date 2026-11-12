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
	rescue_from ArgumentError, with: :stale_transition

	#-------------------------------------
	# CRUD
	#-------------------------------------
	def index
		@policy = check_policy!(DocumentPolicy, owner: @owner)

		@documents = @owner.documents

		title  = helpers.document_title(subtitle: Document.label(:plural))
		page   = paginate(@documents, 1.5)
		table  = helpers.document_table(documents: page)
		retlnk = path_for(@owner)
		create_index(title:, table:, retlnk:)
	end

	def show
		@policy = check_policy!(DocumentPolicy, owner: @owner)

		@fields = create_fields(helpers.document_show)
		@submit = create_submit(submit: edit_path_for(@document), frame: :modal) if @policy.edit?
	end

	def new
		@policy = check_policy!(DocumentPolicy, owner: @owner)

		prepare_form(:create)
	end

	def create
		@policy   = check_policy!(DocumentPolicy, owner: @owner)

		@document = @owner.documents.new(document_params)
		if @document.save
			redirect_to index_path_for(@document),
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
			@document.assign_attributes(document_params)
			if @document.modified?
				if @document.save
					notice = "#{@document.msg(:updated)} '#{@document.title}'"
					register_action(:updated, notice, url: path_for(@document))
					format.html do
						redirect_to index_path_for(@document), notice:
					end
				else
					prepare_form(:edit)
					format.html { render :new, status: :unprocessable_entity }
				end
			else
					format.html do
						redirect_to index_path_for(@document),
												notice: "#{@document.msg(:unchanged)}"
					end
			end
		end
	end

	def destroy
		@policy = check_policy!(DocumentPolicy, owner: @owner)

		notice  = "#{@document.msg(:deleted)} '#{@document.title}'"
		redirect_to index_path_for(@document), notice:
	end

	#-------------------------------------
	# Status transitions
	#-------------------------------------
	def submit_for_verification
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		transition_with_notice(:submit_for_verification!, Document.msg(:submitted))
	end

	def verify
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		transition_with_notice(:verify!, Document.msg(:verified))
	end

	def reject
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		transition_with_notice(:reject!, Document.msg(:rejected))
	end

	def activate
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		transition_with_notice(:activate!, Document.msg(:activated))
	end

	def archive
		@policy = check_policy!(DocumentPolicy, owner: @owner)
		transition_with_notice(:archive!, Document.msg(:archived))
	end

	def versions
		@policy = check_policy!(DocumentPolicy, owner: @owner)

		@header = create_fields(helpers.document_versions_header)
		@table  = create_fields(helpers.document_versions_table)
		@submit = create_submit(submit: nil)
	end

	private
		def transition_with_notice(method, message)
			@document.public_send(method)
			redirect_to index_path_for(@document),
									notice: helpers.flash_message(message, :success)
		rescue ActiveRecord::RecordInvalid => e
			redirect_to index_path_for(@document),
									alert: helpers.flash_message(e.message, :error)
		end

		def stale_transition(error)
			redirect_to index_path_for(@document),
									alert: helpers.flash_message(error.message, :error)
		end

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
			@document ||= @owner.documents.new(kind: Document.kind_list(@owner).first[1])
			fields  = helpers.document_form_fields(Document.act(action))
			@fields = create_fields(fields)
			@submit = create_submit
		end

		def document_params
			params.require(:document).permit(
				:kind, :title, :summary, :file,
				:remarks, :status, :activated_at
			)
		end
end
