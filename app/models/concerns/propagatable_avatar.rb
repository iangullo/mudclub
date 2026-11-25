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
# frozen_string_literal: true

# app/models/concerns/propagatable_avatar.rb
module PropagatableAvatar
	extend ActiveSupport::Concern

	included do
		after_commit :propagate_avatar_upward, on: %i[create update]
	end

	private
		def propagate_avatar_upward
			return unless avatar.attached?

			target = avatar_propagation_target
			return unless target && target.respond_to?(:avatar)

			return if target.avatar.attached? && target.avatar.blob_id == avatar.blob_id

			target.avatar.attach(avatar.blob)
		end

		def avatar_propagation_target
			raise NotImplementedError, "#{self.class.name} must define #avatar_propagation_target"
		end
end
