class GroupsBlueprint < Blueprinter::Base
  identifier :id, name: :group_id
  view :normal do
    field :name
    field :category, name: :type
    field :members do |group, options|
      res = []
      group.users.each do |user|
        paid = group.transactions.where({ from_id: options[:current_user].id,
                                          to_id: user.id }).select(:amount).map(&:amount).inject(0.0, :+)
        owed = group.transactions.where({ from_id: user.id,
                                          to_id: options[:current_user].id })
                    .select(:amount).map(&:amount).inject(0.0, :+)
        res += [{
          user_id: user.id,
          name: user.name,
          email: user.email,
          balance: paid - owed
        }]
      end
      res
    end
  end
  view :index do
    field :name
    field :category, name: :type
    association :users, name: :members, blueprint: UsersBlueprint, view: :normal, if: lambda {
      |_field_name, group, _options|
                                                                                        group.category == 'friend'
                                                                                      }
  end
end
