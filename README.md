## PX: paymentexpress library

```ruby

    url = PX.request(...)
    # redirect to the url / iframe target it

    # get redirected to a URL with `result` parameter then
    data = PX.response(response: result)

    # you can now use this as your customer token
    # if you want to charge the same card in the future
    # for recurring and/or pay per use type scenarios.
    data[:token]

    # Sometime in the future:
    PX.post(amount: 1, token: token)

```

### LICENSE: MIT
