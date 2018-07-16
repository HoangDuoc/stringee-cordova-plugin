/*global cordova, module*/

// TODO: Khai báo lớp trung mà bên ngoài sẽ gọi Plugin

var StringeePlugin, StringeeError, StringeeSuccess;

StringeePlugin = "StringeePlugin";

StringeeError = function (error) {
  return console.log("Error: ", error);
};

StringeeSuccess = function () {
  return console.log("success");
};

window.Stringee = {
  initStringeeClient: function() {
    return new StringeeClient();
  },
  showLog: function(a) {
    return console.log(a);
  },
  getHelper: function () {
    if (typeof jasmine === "undefined" || !jasmine || !jasmine['getEnv']) {
      window.jasmine = {
        getEnv: function () { }
      };
    }
    this.StringeeHelper = this.StringeeHelper || StringeeHelpers.noConflict();
    return this.StringeeHelper;
  }
};

// TODO: Tạo lớp StringeeClient

var StringeeClient,
  __bind = function(fn, me) {
    return function() {
      return fn.apply(me, arguments);
    };
  };

StringeeClient = (function() {

  // Kết nối
  StringeeClient.prototype.connect = function(token) {
    this.token = token;
    if (token !== "" && token != null) {
      Stringee.showLog("Can not connect to Stringee server. Token is invalid");
      return;
    }

    Cordova.exec(this.eventReceived, StringeeError, StringeePlugin, "addEvent", [
      "clientEvents"
    ]);
    Cordova.exec(StringeeSuccess, StringeeError, StringeePlugin, "connect", [this.token]);
  };

  // Hàm khởi tạo
  function StringeeClient() {
    this.didConnect = __bind(this.didConnect, this);
    this.eventReceived = __bind(this.eventReceived, this);
    Stringee.getHelper().eventing(this);
  }

  // Events

  StringeeClient.prototype.eventReceived = function (response) {
    return this[response.eventType](response.data);
  };

  StringeeClient.prototype.didConnect = function (event) {
    var connectionEvent = new StringeeEvent("didConnect");
    this.dispatchEvent(connectionEvent);
    return this;
  };

  return StringeeClient;
})();

// TODO: Tạo lớp StringeeEvent

var StringeeEvent,
  __bind = function(fn, me) {
    return function() {
      return fn.apply(me, arguments);
    };
  };

StringeeEvent = (function() {
  function StringeeEvent(type, cancelable) {
    this.preventDefault = __bind(this.preventDefault, this);
    this.isDefaultPrevented = __bind(this.isDefaultPrevented, this);
    this.type = type;
    this.cancelable = cancelable !== void 0 ? cancelable : true;
    this._defaultPrevented = false;
    return;
  }

  StringeeEvent.prototype.isDefaultPrevented = function() {
    return this._defaultPrevented;
  };

  StringeeEvent.prototype.preventDefault = function() {
    if (this.cancelable) {
      this._defaultPrevented = true;
    } else {
      console.log(
        "Event.preventDefault: Trying to prevent default on an Event that isn't cancelable"
      );
    }
  };

  return StringeeEvent;
})();


!(function (window, undefined) {


  var StringeeHelpers = function (domId) {
    return document.getElementById(domId);
  };

  var previousStringeeHelpers = window.StringeeHelpers;

  window.StringeeHelpers = StringeeHelpers;

  StringeeHelpers.keys = Object.keys || function (object) {
    var keys = [], hasOwnProperty = Object.prototype.hasOwnProperty;
    for (var key in object) {
      if (hasOwnProperty.call(object, key)) {
        keys.push(key);
      }
    }
    return keys;
  };

  var _each = Array.prototype.forEach || function (iter, ctx) {
    for (var idx = 0, count = this.length || 0; idx < count; ++idx) {
      if (idx in this) {
        iter.call(ctx, this[idx], idx);
      }
    }
  };

  StringeeHelpers.forEach = function (array, iter, ctx) {
    return _each.call(array, iter, ctx);
  };

  var _map = Array.prototype.map || function (iter, ctx) {
    var collect = [];
    _each.call(this, function (item, idx) {
      collect.push(iter.call(ctx, item, idx));
    });
    return collect;
  };

  StringeeHelpers.map = function (array, iter) {
    return _map.call(array, iter);
  };

  var _filter = Array.prototype.filter || function (iter, ctx) {
    var collect = [];
    _each.call(this, function (item, idx) {
      if (iter.call(ctx, item, idx)) {
        collect.push(item);
      }
    });
    return collect;
  };

  StringeeHelpers.filter = function (array, iter, ctx) {
    return _filter.call(array, iter, ctx);
  };

  var _some = Array.prototype.some || function (iter, ctx) {
    var any = false;
    for (var idx = 0, count = this.length || 0; idx < count; ++idx) {
      if (idx in this) {
        if (iter.call(ctx, this[idx], idx)) {
          any = true;
          break;
        }
      }
    }
    return any;
  };

  StringeeHelpers.some = function (array, iter, ctx) {
    return _some.call(array, iter, ctx);
  };

  var _indexOf = Array.prototype.indexOf || function (searchElement, fromIndex) {
    var i,
      pivot = (fromIndex) ? fromIndex : 0,
      length;

    if (!this) {
      throw new TypeError();
    }

    length = this.length;

    if (length === 0 || pivot >= length) {
      return -1;
    }

    if (pivot < 0) {
      pivot = length - Math.abs(pivot);
    }

    for (i = pivot; i < length; i++) {
      if (this[i] === searchElement) {
        return i;
      }
    }
    return -1;
  };

  StringeeHelpers.arrayIndexOf = function (array, searchElement, fromIndex) {
    return _indexOf.call(array, searchElement, fromIndex);
  };

  var _bind = Function.prototype.bind || function () {
    var args = Array.prototype.slice.call(arguments),
      ctx = args.shift(),
      fn = this;
    return function () {
      return fn.apply(ctx, args.concat(Array.prototype.slice.call(arguments)));
    };
  };

  StringeeHelpers.bind = function () {
    var args = Array.prototype.slice.call(arguments),
      fn = args.shift();
    return _bind.apply(fn, args);
  };

  var _trim = String.prototype.trim || function () {
    return this.replace(/^\s+|\s+$/g, '');
  };

  StringeeHelpers.trim = function (str) {
    return _trim.call(str);
  };

  StringeeHelpers.noConflict = function () {
    StringeeHelpers.noConflict = function () {
      return StringeeHelpers;
    };
    window.StringeeHelpers = previousStringeeHelpers;
    return StringeeHelpers;
  };

  StringeeHelpers.isNone = function (obj) {
    return obj === undefined || obj === null;
  };

  StringeeHelpers.isObject = function (obj) {
    return obj === Object(obj);
  };

  StringeeHelpers.isFunction = function (obj) {
    return !!obj && (obj.toString().indexOf('()') !== -1 ||
      Object.prototype.toString.call(obj) === '[object Function]');
  };

  StringeeHelpers.isArray = StringeeHelpers.isFunction(Array.isArray) && Array.isArray ||
    function (vArg) {
      return Object.prototype.toString.call(vArg) === '[object Array]';
    };

  StringeeHelpers.isEmpty = function (obj) {
    if (obj === null || obj === undefined) return true;
    if (StringeeHelpers.isArray(obj) || typeof (obj) === 'string') return obj.length === 0;

    // Objects without enumerable owned properties are empty.
    for (var key in obj) {
      if (obj.hasOwnProperty(key)) return false;
    }

    return true;
  };

  // Returns the number of millisceonds since the the UNIX epoch, this is functionally
  // equivalent to executing new Date().getTime().
  //
  // Where available, we use 'performance.now' which is more accurate and reliable,
  // otherwise we default to new Date().getTime().
  StringeeHelpers.now = (function () {
    var performance = window.performance || {},
      navigationStart,
      now = performance.now ||
        performance.mozNow ||
        performance.msNow ||
        performance.oNow ||
        performance.webkitNow;

    if (now) {
      now = StringeeHelpers.bind(now, performance);
      navigationStart = performance.timing.navigationStart;

      return function () { return navigationStart + now(); };
    } else {
      return function () { return new Date().getTime(); };
    }
  })();


})(window);


(function (window, StringeeHelpers, undefined) {

  /**
  * This base class defines the <code>on</code>, <code>once</code>, and <code>off</code>
  * methods of objects that can dispatch events.
  *
  * @class EventDispatcher
  */
  StringeeHelpers.eventing = function (self, syncronous) {
    var _events = {};

    // Call the defaultAction, passing args
    function executeDefaultAction(defaultAction, args) {
      if (!defaultAction) return;

      defaultAction.apply(null, args.slice());
    }

    // This is identical to executeListenersAsyncronously except that handlers will
    // be executed syncronously.
    //
    // On completion the defaultAction handler will be executed with the args.
    //
    // @param [Array] listeners
    //    An array of functions to execute. Each will be passed args.
    //
    // @param [Array] args
    //    An array of arguments to execute each function in  +listeners+ with.
    //
    // @param [String] name
    //    The name of this event.
    //
    // @param [Function, Null, Undefined] defaultAction
    //    An optional function to execute after every other handler. This will execute even
    //    if +listeners+ is empty. +defaultAction+ will be passed args as a normal
    //    handler would.
    //
    // @return Undefined
    //
    function executeListenersSyncronously(name, args) { // defaultAction is not used
      var listeners = _events[name];
      if (!listeners || listeners.length === 0) return;

      StringeeHelpers.forEach(listeners, function (listener) { // index
        (listener.closure || listener.handler).apply(listener.context || null, args);
      });
    }

    var executeListeners = syncronous === true ?
      executeListenersSyncronously : executeListenersSyncronously;


    var removeAllListenersNamed = function (eventName, context) {
      if (_events[eventName]) {
        if (context) {
          // We are removing by context, get only events that don't
          // match that context
          _events[eventName] = StringeeHelpers.filter(_events[eventName], function (listener) {
            return listener.context !== context;
          });
        }
        else {
          delete _events[eventName];
        }
      }
    };

    var addListeners = StringeeHelpers.bind(function (eventNames, handler, context, closure) {
      var listener = { handler: handler };
      if (context) listener.context = context;
      if (closure) listener.closure = closure;

      StringeeHelpers.forEach(eventNames, function (name) {
        if (!_events[name]) _events[name] = [];
        _events[name].push(listener);
      });
    }, self);


    var removeListeners = function (eventNames, handler, context) {
      function filterHandlerAndContext(listener) {
        return !(listener.handler === handler && listener.context === context);
      }

      StringeeHelpers.forEach(eventNames, StringeeHelpers.bind(function (name) {
        if (_events[name]) {
          _events[name] = StringeeHelpers.filter(_events[name], filterHandlerAndContext);
          if (_events[name].length === 0) delete _events[name];
        }
      }, self));

    };

    // Execute any listeners bound to the +event+ Event.
    //
    // Each handler will be executed async. On completion the defaultAction
    // handler will be executed with the args.
    //
    // @param [Event] event
    //    An Event object.
    //
    // @param [Function, Null, Undefined] defaultAction
    //    An optional function to execute after every other handler. This will execute even
    //    if there are listeners bound to this event. +defaultAction+ will be passed
    //    args as a normal handler would.
    //
    // @return this
    //
    self.dispatchEvent = function (event, defaultAction) {
      if (!event.type) {
        String.showLog("DispatchEvent error: Event has no type");
        throw new Error("DispatchEvent error: Event has no type");
      }

      if (!event.target) {
        event.target = this;
      }

      if (!_events[event.type] || _events[event.type].length === 0) {
        executeDefaultAction(defaultAction, [event]);
        return;
      }

      executeListeners(event.type, [event], defaultAction);

      return this;
    };

    // Execute each handler for the event called +name+.
    //
    // Each handler will be executed async, and any exceptions that they throw will
    // be caught and logged
    //
    // How to pass these?
    //  * defaultAction
    //
    // @example
    //  foo.on('bar', function(name, message) {
    //    alert("Hello " + name + ": " + message);
    //  });
    //
    //  foo.trigger('OpenTok', 'asdf');     // -> Hello OpenTok: asdf
    //
    //
    // @param [String] eventName
    //    The name of this event.
    //
    // @param [Array] arguments
    //    Any additional arguments beyond +eventName+ will be passed to the handlers.
    //
    // @return this
    //
    self.trigger = function (eventName) {
      if (!_events[eventName] || _events[eventName].length === 0) {
        return;
      }

      var args = Array.prototype.slice.call(arguments);

      // Remove the eventName arg
      args.shift();

      executeListeners(eventName, args);

      return this;
    };

    /**
     * Adds an event handler function for one or more events.
     *
     * <p>
     * The following code adds an event handler for one event:
     * </p>
     *
     * <pre>
     * obj.on("eventName", function (event) {
     *     // This is the event handler.
     * });
     * </pre>
     *
     * <p>If you pass in multiple event names and a handler method, the handler is
     * registered for each of those events:</p>
     *
     * <pre>
     * obj.on("eventName1 eventName2",
     *        function (event) {
     *            // This is the event handler.
     *        });
     * </pre>
     *
     * <p>You can also pass in a third <code>context</code> parameter (which is optional) to
     * define the value of <code>this</code> in the handler method:</p>
     *
     * <pre>obj.on("eventName",
     *        function (event) {
     *            // This is the event handler.
     *        },
     *        obj);
     * </pre>
     *
     * <p>
     * The method also supports an alternate syntax, in which the first parameter is an object
     * that is a hash map of event names and handler functions and the second parameter (optional)
     * is the context for this in each handler:
     * </p>
     * <pre>
     * obj.on(
     *    {
     *       eventName1: function (event) {
     *               // This is the handler for eventName1.
     *           },
     *       eventName2:  function (event) {
     *               // This is the handler for eventName2.
     *           }
     *    },
     *    obj);
     * </pre>
     *
     * <p>
     * If you do not add a handler for an event, the event is ignored locally.
     * </p>
     *
     * @param {String} type The string identifying the type of event. You can specify multiple event
     * names in this string, separating them with a space. The event handler will process each of
     * the events.
     * @param {Function} handler The handler function to process the event. This function takes
     * the event object as a parameter.
     * @param {Object} context (Optional) Defines the value of <code>this</code> in the event
     * handler function.
     *
     * @returns {EventDispatcher} The EventDispatcher object.
     *
     * @memberOf EventDispatcher
     * @method #on
     * @see <a href="#off">off()</a>
     * @see <a href="#once">once()</a>
     * @see <a href="#events">Events</a>
     */
    self.on = function (eventNames, handlerOrContext, context) {
      if (typeof (eventNames) === 'string' && handlerOrContext) {
        addListeners(eventNames.split(' '), handlerOrContext, context);
      }
      else {
        for (var name in eventNames) {
          if (eventNames.hasOwnProperty(name)) {
            addListeners([name], eventNames[name], handlerOrContext);
          }
        }
      }

      return this;
    };

    /**
     * Removes an event handler or handlers.
     *
     * <p>If you pass in one event name and a handler method, the handler is removed for that
     * event:</p>
     *
     * <pre>obj.off("eventName", eventHandler);</pre>
     *
     * <p>If you pass in multiple event names and a handler method, the handler is removed for
     * those events:</p>
     *
     * <pre>obj.off("eventName1 eventName2", eventHandler);</pre>
     *
     * <p>If you pass in an event name (or names) and <i>no</i> handler method, all handlers are
     * removed for those events:</p>
     *
     * <pre>obj.off("event1Name event2Name");</pre>
     *
     * <p>If you pass in no arguments, <i>all</i> event handlers are removed for all events
     * dispatched by the object:</p>
     *
     * <pre>obj.off();</pre>
     *
     * <p>
     * The method also supports an alternate syntax, in which the first parameter is an object that
     * is a hash map of event names and handler functions and the second parameter (optional) is
     * the context for this in each handler:
     * </p>
     * <pre>
     * obj.off(
     *    {
     *       eventName1: event1Handler,
     *       eventName2: event2Handler
     *    });
     * </pre>
     *
     * @param {String} type (Optional) The string identifying the type of event. You can
     * use a space to specify multiple events, as in "accessAllowed accessDenied
     * accessDialogClosed". If you pass in no <code>type</code> value (or other arguments),
     * all event handlers are removed for the object.
     * @param {Function} handler (Optional) The event handler function to remove. The handler
     * must be the same function object as was passed into <code>on()</code>. Be careful with
     * helpers like <code>bind()</code> that return a new function when called. If you pass in
     * no <code>handler</code>, all event handlers are removed for the specified event
     * <code>type</code>.
     * @param {Object} context (Optional) If you specify a <code>context</code>, the event handler
     * is removed for all specified events and handlers that use the specified context. (The
     * context must match the context passed into <code>on()</code>.)
     *
     * @returns {Object} The object that dispatched the event.
     *
     * @memberOf EventDispatcher
     * @method #off
     * @see <a href="#on">on()</a>
     * @see <a href="#once">once()</a>
     * @see <a href="#events">Events</a>
     */
    self.off = function (eventNames, handlerOrContext, context) {
      if (typeof eventNames === 'string') {
        if (handlerOrContext && StringeeHelpers.isFunction(handlerOrContext)) {
          removeListeners(eventNames.split(' '), handlerOrContext, context);
        }
        else {
          StringeeHelpers.forEach(eventNames.split(' '), function (name) {
            removeAllListenersNamed(name, handlerOrContext);
          }, this);
        }

      } else if (!eventNames) {
        // remove all bound events
        _events = {};

      } else {
        for (var name in eventNames) {
          if (eventNames.hasOwnProperty(name)) {
            removeListeners([name], eventNames[name], handlerOrContext);
          }
        }
      }

      return this;
    };


    /**
     * Adds an event handler function for one or more events. Once the handler is called,
     * the specified handler method is removed as a handler for this event. (When you use
     * the <code>on()</code> method to add an event handler, the handler is <i>not</i>
     * removed when it is called.) The <code>once()</code> method is the equivilent of
     * calling the <code>on()</code>
     * method and calling <code>off()</code> the first time the handler is invoked.
     *
     * <p>
     * The following code adds a one-time event handler for the <code>accessAllowed</code> event:
     * </p>
     *
     * <pre>
     * obj.once("eventName", function (event) {
     *    // This is the event handler.
     * });
     * </pre>
     *
     * <p>If you pass in multiple event names and a handler method, the handler is registered
     * for each of those events:</p>
     *
     * <pre>obj.once("eventName1 eventName2"
     *          function (event) {
     *              // This is the event handler.
     *          });
     * </pre>
     *
     * <p>You can also pass in a third <code>context</code> parameter (which is optional) to define
     * the value of
     * <code>this</code> in the handler method:</p>
     *
     * <pre>obj.once("eventName",
     *          function (event) {
     *              // This is the event handler.
     *          },
     *          obj);
     * </pre>
     *
     * <p>
     * The method also supports an alternate syntax, in which the first parameter is an object that
     * is a hash map of event names and handler functions and the second parameter (optional) is the
     * context for this in each handler:
     * </p>
     * <pre>
     * obj.once(
     *    {
     *       eventName1: function (event) {
     *                  // This is the event handler for eventName1.
     *           },
     *       eventName2:  function (event) {
     *                  // This is the event handler for eventName1.
     *           }
     *    },
     *    obj);
     * </pre>
     *
     * @param {String} type The string identifying the type of event. You can specify multiple
     * event names in this string, separating them with a space. The event handler will process
     * the first occurence of the events. After the first event, the handler is removed (for
     * all specified events).
     * @param {Function} handler The handler function to process the event. This function takes
     * the event object as a parameter.
     * @param {Object} context (Optional) Defines the value of <code>this</code> in the event
     * handler function.
     *
     * @returns {Object} The object that dispatched the event.
     *
     * @memberOf EventDispatcher
     * @method #once
     * @see <a href="#on">on()</a>
     * @see <a href="#off">off()</a>
     * @see <a href="#events">Events</a>
     */
    self.once = function (eventNames, handler, context) {
      var names = eventNames.split(' '),
        fun = StringeeHelpers.bind(function () {
          var result = handler.apply(context || null, arguments);
          removeListeners(names, handler, context);

          return result;
        }, this);

      addListeners(names, handler, context, fun);
      return this;
    };


})(window, window.StringeeHelpers);

// module.exports = {
//   greet: function(name, successCallback, errorCallback) {
//     cordova.exec(successCallback, errorCallback, "StringeePlugin", "greet", [
//       name
//     ]);
//   }
// };
