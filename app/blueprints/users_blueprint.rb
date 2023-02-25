class UsersBlueprint < Blueprinter::Base
  identifier :id, name: :user_id
  view :normal do
    fields :name, :email
  end
end
