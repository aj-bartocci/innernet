# Innernet (Inner Network)

For an example app checkout this [example app](https://github.com/aj-bartocci/innernet-example)

## What is this?
This framework allows you to create an inner network inside of your application.  Normally your network requests will not fail, or will require you to have a deep knowledge of the api's in ordrer to get the data to be in the form that you would like. Innernet allows you to intercept live network requests before they reach the outside world and return mock data or errors instead. This is ideal for testing or mocking out network requests to force your app into specific scenarios easily. 

## Why?
Dependency injection is hard. Many times projects do not have proper dependency injection which makes it very difficult to unit test or force the app to do specific things. Dependency injection can also lead to a ton of protocols that add complexity to the project and make things harder to understand. Everyone seems to do it differently.

This framework aims to be a less intrusive way to take control of your network requests. It uses URLProtocol to intercept network requests or allow them to pass through to their real destination. The goal was to require the least amount of configuration so that it will be easy to drop into existing projects without needing to refactor a bunch of things.

Ideally this framework will complement dependency injection, not replace it. 

## How to use it
At its core the framework is built around URLProtocol, so any networking library that allows you to configure the underlying URLSessionConfiguration (URLSession, Alamofire, etc) will work. 

## Register the interceptor
**When URLSession.shared register the interceptor before any requests:**
```swift 
URLProtocol.registerClass(Innernet.InterceptProtocol.self)
```
**When using a custom URLSession add the protocol to the configuration before any requests:**
```swift 
let config = URLSessionConfiguration.default
config.protocolClasses = [Innernet.InterceptProtocol.self]
let session = URLSession(configuration: config)
```
**When using Alamofire add the protocol to the configuration before any requests:**
```swift 
let config = URLSessionConfiguration.default
config.protocolClasses = [Innernet.InterceptProtocol.self]
let afSession = Session(configuration: config)
```
## Specify which requests to intercept
When intercepting a request you will have access to the incoming request and a completion handler. You must call the completion handler or the request will timeout.

You can return mock data or a networkError in the completion handler.

**Exact matching**
```swift
Innernet.intercept(.get, matching: "somefakedomain.com/items") { req, completion in
    let items: [ExampleItem] = [
        ExampleItem(id: "1", value: "Foo"),
        ExampleItem(id: "2", value: "Bar"),
        ExampleItem(id: "3", value: "Baz"),
    ]
    let data = try? JSONEncoder().encode(items)
    completion(.mock(status: 200, data: data, headers: nil, httpVersion: nil))
}
```
An exact match will need to match the url exactly in order to trigger the intercept.

**Variable matching**
```swift
Innernet.intercept(.get, matching: "somefakedomain.com/items/*/info") { req, completion in
    let item = ExampleItem(id: "1", value: "Foo")
    let data = try? JSONEncoder().encode(item)
    completion(.mock(status: 200, data: data, headers: nil, httpVersion: nil))
}
```
A variable match is denoted wiht a single asterisk(\*). This will match a single path in the url. In the above example an incoming request of 'somefakedomain.com/items/1/info' will trigger the intercept.

**Wildcard matching**
```swift
Innernet.intercept(.get, matching: "somefakedomain.com/**") { req, completion in
    let item = ExampleItem(id: "1", value: "Foo")
    let data = try? JSONEncoder().encode(item)
    completion(.mock(status: 200, data: data, headers: nil, httpVersion: nil))
}
```
A wildcard match is denoted wiht a double asterisk(\**). This will match any paths that come after the wildcard. In the above example any incoming requests that have 'somefakedomain.com' domain like 'somefakedomain.com/items/1/info', 'somefakedomain.com/items/', etc will trigger the intercept.

## Additional Configuration
**Passthrough Requests**
```swift
Innernet.allowsPassthroughRequests = true / false
```
Since Innernet uses URLProtocol under the hood, all network reqeusts are processed and checked if they should be intercepted. By default Innernet will return an error for any requests that do not have a corresponding intercept.

If you want to intercept specific requests but allow others to actually hit the network then you should set allowsPassthroughRequests to true. 

By default allowsPassthroughRequests is set to false, which will block prevent all network requests from hitting the live network. 

##Timeout Threshold**
```swift
Innernet.timeoutThreshold = 15.0
```
If a request takes too long or you forget to call the completion handler of an intercepted request then it will trigger an timeout error. By default this is set to 15 seconds. 

## Roadmap
- Add the ability to re-route requests. I.e yourserver.com/foo -> localhost:8000/foo
- Companion app for managing intercepts. Since writing intercept code means that you need to modify your codebase it's not ideal. This is fine for tests but when trying to manipulate your app on the fly it's cumbersome. A companion app that allows you to create / delete intercepts on the fly would be ideal because your codebase will not need to be modified but you can still intercept requests as needed without rebuilding the app. This is pretty much like a proxy that allows you to modify responses on the fly.