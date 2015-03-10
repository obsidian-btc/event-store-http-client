# Why?

* [https://geteventstore.com/](Eventstore) is awesome
* [https://vertx.io/](Vert.X) is awesome

Eventstore is a very exciting functional database, and Vert.X is a great platform for building applications.  Eventstore only has a couple of native clients, and Vert.X has a very specific set of asynchronous tools.

This library uses the Vert.X asynchronous HTTPClient libraries with ES-LongPoll.

Currently the full circuit of event generation, posting, and the long-poll has about 3-8ms cycle time on a laptop.
