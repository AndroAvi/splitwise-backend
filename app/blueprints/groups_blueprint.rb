class GroupsBlueprint < Blueprinter::Base
  identifier :id, name: :group_id
  view :normal do
    field :name
    field :category, name: :type
    association :users, name: :members, blueprint: UsersBlueprint
  end
  view :index do
    field :name
    field :category, name: :type
    association :users, name: :members, blueprint: UsersBlueprint, view: :normal, if: lambda { |_field_name, group, _options|
                                                                                        group.category == 'friend'
                                                                                      }
  end
end
