module StripeMock
  module RequestHandlers
    module SubscriptionItems

      def SubscriptionItems.included(klass)
        klass.add_handler 'get /v1/subscription_items', :retrieve_subscription_items
        klass.add_handler 'post /v1/subscription_items', :create_subscription_items
        klass.add_handler 'post /v1/subscription_items/(.*)', :update_subscription_items
      end

      def list_subscription_items(route, method_url, params, headers)
        route =~ method_url

        require_param(:subscription) unless params[:subscription]

        Data.mock_list_object(subscriptions_items, params)
      end

      def create_subscription_items(route, method_url, params, headers)
        params[:id] ||= new_id('si')

        require_param(:subscription) unless params[:subscription]
        require_param(:plan) unless params[:plan]

        subscriptions_items[params[:id]] = Data.mock_subscription_item(params.merge(plan: plans[params[:plan]]))
      end

      def update_subscription_item(route, method_url, params, headers)
        route =~ method_url

        subscription_item = assert_existence :subscription_item, $1, subscriptions_items[$1]
        subscription_item.merge!(params.merge(plan: plans[params[:plan]]))

        subscription_id = params[:subscription][:id]
        subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]
        verify_active_status(subscription)
        Data.mock_list_object(subscription[:items][:data], params)
      end

      def update_subscription_items(route, method_url, params, headers)
        route =~ method_url

        subscription_item_id = $1
        subscription_id = subscriptions.keys.first

        subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]
        verify_active_status(subscription)

        customer_id = subscription[:customer]
        customer = assert_existence :customer, customer_id, customers[customer_id]

        subscription_item = subscription[:items][:data].find { |si| si[:id] == subscription_item_id }
        subscription[:items][:data].delete_if { |si| si[:id] == subscription_item_id }
        new_item = Data.mock_subscription_item(subscription_item.merge({ 'quantity': params[:quantity]}))
        subscription[:items][:data] << new_item

        subscriptions[subscription[:id]] = subscription
        subscription_item
      end

      def create_subscription_items(route, method_url, params, headers)
        route =~ method_url
        subscription_id = params[:subscription][:id]
        subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]
        verify_active_status(subscription)

        customer_id = subscription[:customer]
        customer = assert_existence :customer, customer_id, customers[customer_id]

        subscription_plans = get_subscription_plans_from_params(params)

        new_item = Data.mock_subscription_item( id: "#{params[:plan]}-#{rand(10000)}", plan: { id: params[:plan] }, quantity: params[:quantity], metadata: params[:metadata])
        subscription[:items][:data] << new_item

        subscriptions[subscription[:id]] = subscription
        add_subscription_to_customer(customer, subscription)

        subscriptions[subscription[:id]]
      end
    end
  end
end
