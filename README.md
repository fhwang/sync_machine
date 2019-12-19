# SyncMachine

## Summary

SyncMachine is a Ruby mini-framework for intelligently orchestrating updates of complex model changes to an external API.

## The problem

Imagine a Rails e-commerce site with a Customer model, and an Order model.  Customers have zero or more Orders.

Customer
- id
- first_name
- last_name
- email

Order
- id
- customer_id
- status (purchased/shipped/received)
- warehouse_code

This site publishes orders to an external API in the following form:

```
{
  "id": "1234",
  "customer_full_name": "Jane Yang",
  "order_status": "shipped"
}
```

The desired behavior is that the Rails app updates the API any time that data changes in such a way that this payload would change.

Generating this payload and sending this payload are typically not hard problems.  But handling the logic of *when* to send this payload can be frustrating.  Consider:

- Changes to `Order#status` should result in a re-post of that Order to the API
- Changes to `Order#warehouse_code` should not result in a re-post, because that field is not reflected in the document sent to the API
- Changes to `Customer#first_name` or `Customer#last_name` should result in re-posts of all Orders belonging to the Customer

In addition, there is no obvious way to integrate this logic with the day-to-day activities supported by a web application under active development.  How do you tell this process to start?

- You can automatically listen for changes to Rails models via callbacks or some sort of publish-subscribe mechanism.  But since most model changes won't actually result in a change to the payload, you run the risk of spamming the API with redundant updates.
- You can ask programmers to manually start the syncing process, but that burdens them with having to remember a sync mechanism they don't otherwise need to know about.

So the ideal solution should have these characteristics:

- Listen automatically to all changes on all relevant models, but reduce downstream work so this does not result in redundant updates to the API
- Listen to multiple models and have some way to reduce those changes to a single kind of model
- Since models can sometimes change in large bursts due to migration scripts, etc, dedupe this syncing logic when possible, to keep background queues clear and spare the API from excessive work

## About SyncMachine

SyncMachine orchestrates this syncing logic through a coordinated pipeline of steps.  It is primarily concerned with *orchestration* -- when should we check for changes, when should we publish changes to the API, and how can we reduce redundant work?

SyncMachine includes a number of features:

- Support for ActiveRecord or Mongoid models
- Built-in optimizations to remove excessive work from Sidekiq workers and the API
- Built-in observability support via [OpenTracing](https://opentracing.io/)

It's built on top of [Sidekiq](https://sidekiq.org/) for background jobs, and [Wisper](https://github.com/krisleech/wisper) for publish-subscribe.

It's composed of three steps, which answer these questions:

- `ChangeListener`: Which changed models are we listening to?
- `FindSubjectsWorker`: Given a changed model, which subjects are we considering for publication to the API?
- `EnsurePublicationWorker`: Given a subject, is it time to publish the resulting payload to the API?

## Example

Here's an example of implementing `SyncMachine` for the ecommerce application described above.  First, install the Gem:

```
gem "sync_machine"
```

Then run the generator:

```
$ rails generate sync_machine OrderToApiSync --subject=order
      invoke  active_record
      create    app/models/order_to_api_sync/payload.rb
    generate    migration
      invoke  active_record
      create    db/migrate/20191219172934_create_order_to_api_sync_payloads.rb
      create  app/services/order_to_api_sync.rb
      create  app/workers/order_to_api_sync/find_subjects_worker.rb
      create  app/workers/order_to_api_sync/ensure_publication_worker.rb
      create  app/services/order_to_api_sync/change_listener.rb
      create  config/initializers/sync_machines.rb
      append  config/initializers/sync_machines.rb
```

`app/services/order_to_api_sync.rb` is just the top-level shell for the sync machine instance. 

```
module OrderToApiSync
  extend SyncMachine

  subject :order
end
```

All sync machines need a "subject": This is the model class in your application that most cleanly maps to what the API cares about.

`app/services/order_to_api_sync/change_listener.rb` defines which models we are listening to for changes.  Since both `Customer` and `Order` can possibly affect the final payload, we listen to both.  This uses Wisper to listen to all changes on all customers and orders: For every such change it enqueues one `FindSubjectsWorker` job in Sidekiq.

```
module OrderToApiSync
  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :customer, :order
  end
end
```

`app/workers/order_to_api_sync/find_subjects_worker.rb` is run for each changed `Customer` and `Order`: Its job is to map those changed models to one or more `Order` records, since that is the subject of this sync machine.  For each subject, this enqueues one `EnsurePublicationWorker` job in Sidekiq.

```
module OrderToApiSync
  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_order
    
    subject_ids_from_customer do |customer|
      customer.order_ids
    end
  end
end
```

Lastly we have `app/workers/order_to_api_sync/ensure_publication_worker.rb`.

```
module OrderSync
  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    build do |order|
      {
        id: order.id,
        customer_full_name: order.customer.full_name,
        order_status: order.status
      }
    end

    publish do |order, payload|
      ApiClient.post_order(order, payload)
    end
  end
end
```

If you tell SyncMachine how to build the payload, and how to send it, SyncMachine takes care of all the orchestration logic around it.

- If the payload is the same as the last payload that was sent, don't send it to the API again.
- Use a global lock (in Redis) to prevent multiple Sidekiq workers from running `EnsurePublicationWorker` on the same subject record at the same time.
- If the payload is sent to the API, record it locally for comparisons in the future.

# Observability

If you'd like to monitor the behavior of your SyncMachine workflows, in production or otherwise, you can configure SyncMachine to log its behavior via any [OpenTracing](https://opentracing.io/)-compliant tool.

For this example we'll run [Jaeger](https://www.jaegertracing.io/), an open-source tracing application, locally.

First, [install Jaeger](https://www.jaegertracing.io/docs/1.16/getting-started/#all-in-one) with the pre-built Docker image.

Add these three Gems to your `Gemfile`:

```
gem "rack-tracer"
gem "sfx-sidekiq-opentracing"
gem "jaeger-client"
```

Configure `Rack::Tracer` in `config/application.rb`:

```
module MyApp
  class Application < Rails::Application
    config.middleware.use(Rack::Tracer)
  end
end
```

Configure a global tracer in an initializer such as `config/initializers/open_tracing.rb`:

```
require "opentracing"
require "jaeger/client"

OpenTracing.global_tracer =
  Jaeger::Client.build(
    service_name: "my_app"
  ) 
```

Once you run your Rails app and change a `Customer` or `Order`, you should see the sync machine steps visible in your Jaeger interface.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fhwang/sync_machine. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SyncMachine project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fhwang/sync_machine/blob/master/CODE_OF_CONDUCT.md).

