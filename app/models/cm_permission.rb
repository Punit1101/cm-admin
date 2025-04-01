class CmPermission < ApplicationRecord
  after_create :create_hidden_permission
  after_destroy :destroy_hidden_permission

  validates :action_name, presence: true, uniqueness: { scope: %i[ar_model_name cm_role_id] }

  def create_hidden_permission
    if action_name == 'new'
      CmPermission.where(action_name: 'create', ar_model_name:, cm_role_id:).first_or_create
    elsif action_name == 'edit'
      CmPermission.where(action_name: 'update', ar_model_name:, cm_role_id:).first_or_create
    end
  end

  def destroy_hidden_permission
    if action_name == 'new'
      CmPermission.where(action_name: 'create', ar_model_name:, cm_role_id:).first&.destroy
    elsif action_name == 'edit'
      CmPermission.where(action_name: 'update', ar_model_name:, cm_role_id:).first&.destroy
    end
  end
end
