class GroupsBlueprint < Blueprinter::Base
  identifier :id, name: :group_id
  view :normal do
    field :name
    field :category, name: :type
    field :members do |group, _options|
      res = []
      # for every user, get a cumulative balance as part of the group.
      # Display that.
      group.users.each do |user|
        owed = group.transactions.where({ to_id: user.id }).select(:amount).map(&:amount).inject(0.0, :+)
        paid = group.transactions.where({ from_id: user.id }).select(:amount).map(&:amount).inject(0.0, :+)
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
    association :users, name: :members, blueprint: UsersBlueprint, view: :normal
  end
end
