require 'fc'

class GroupsBlueprint < Blueprinter::Base
  identifier :id, name: :group_id
  view :normal do
    field :name
    field :category, name: :type
    field :simplify
    # GREEDY ALGORITHM FOR SIMPLIFYING BALANCES
    # for every user in the group
    #   calculate cumulative balance owed by each user as part of the group.
    # if simplify is disabled
    #   add paid and owed transactions of each user to their hash.
    # if simplify is enabled
    #   define a max heap pos and push abs value of all negative balances owed to pos
    #   define a min heap neg and push all positive balances owed to neg
    #   NOTE: balance owed > 0 means that this user has paid more than owed
    #         and thus needs to get paid, and vice versa.
    #   until pos is empty
    #     amount = max(pos.top, neg.top)
    #     pos.top -= amount
    #     neg.top -= amount
    #     pop 0 values from pos/neg
    #     add a transaction between corresponding users worth amount
    #   for each resulting transaction vector (f,t,a) in simplified set
    #     create temporary transaction (t, f, a) to both involved users' balance hashes.
    field :members do |group, _options|
      res = {}
      group.users.each do |user|
        owed = group.transactions.where({ to_id: user.id }).select(:amount).map(&:amount).inject(0.0, :+)
        paid = group.transactions.where({ from_id: user.id }).select(:amount).map(&:amount).inject(0.0, :+)
        res[user.id] = {
          user_id: user.id,
          name: user.name,
          email: user.email,
          total_balance: (paid - owed).round(2),
          balances: {
            paid: if group[:simplify]
                    []
                  else
                    TransactionsBlueprint
                      .render_as_hash(user.paid_transactions.where({ group_id: group.id })
                      .and(user.paid_transactions.where.not({ to_id: user.id })),
                                      view: :balance_paid)
                  end,
            owed: if group[:simplify]
                    []
                  else
                    TransactionsBlueprint
                      .render_as_hash(user.owed_transactions.where({ group_id: group.id })
                      .and(user.owed_transactions.where.not({ from_id: user.id })),
                                      view: :balance_owed)
                  end
          }
        }
      end
      if group[:simplify]
        transactions = []
        pos = FastContainers::PriorityQueue.new(:max)
        neg = FastContainers::PriorityQueue.new(:min)
        res.each do |key, val|
          if val[:total_balance].positive?
            neg.push(key, val[:total_balance])
          elsif val[:total_balance].negative?
            pos.push(key, val[:total_balance].abs)
          end
        end
        until pos.empty?
          from_id = pos.top
          from_amount = pos.top_key
          to_id = neg.top
          to_amount = neg.top_key
          pos.pop
          neg.pop
          amount = [from_amount, to_amount].min
          from_amount = (from_amount - amount).round(2)
          to_amount = (to_amount - amount).round(2)
          transactions += [{ from_id:, to_id:, amount: }]
          pos.push(from_id, from_amount) unless from_amount.zero?
          neg.push(to_id, to_amount) unless to_amount.zero?
        end
        transactions.each do |val|
          res[val[:to_id]][:balances][:paid] += [Transaction.new({ from_id: val[:to_id], to_id: val[:from_id],
                                                                   amount: val[:amount] })]
          res[val[:from_id]][:balances][:owed] += [Transaction.new({ from_id: val[:to_id], to_id: val[:from_id],
                                                                     amount: val[:amount] })]
        end
        res.each do |_key, val|
          val[:balances][:paid] = TransactionsBlueprint.render_as_hash(val[:balances][:paid], view: :balance_paid)
          val[:balances][:owed] = TransactionsBlueprint.render_as_hash(val[:balances][:owed], view: :balance_owed)
        end
      end
      res.values
    end
  end
  view :index do
    field :name
    field :category, name: :type
    association :users, name: :members, blueprint: UsersBlueprint, view: :normal
  end
end
