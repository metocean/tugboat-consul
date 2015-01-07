// Generated by CoffeeScript 1.8.0
var Tugboat, Watch, consulhost, fatalerror, host, http, key, launch, os, parse_url, path, series, temperrors, url;

Watch = require('redwire-consul').Watch;

Tugboat = require('tugboat');

os = require('os');

http = require('http');

parse_url = require('url').parse;

require('colors');

series = function(tasks, callback) {
  var next, result;
  tasks = tasks.slice(0);
  next = function(cb) {
    var task;
    if (tasks.length === 0) {
      return cb();
    }
    task = tasks.shift();
    return task(function() {
      return next(cb);
    });
  };
  result = function(cb) {
    return next(cb);
  };
  if (callback != null) {
    result(callback);
  }
  return result;
};

host = os.hostname();

if (process.env.TUGBOAT_HOST != null) {
  host = process.env.TUGBOAT_HOST;
}

consulhost = 'http://127.0.0.1:8500';

if (process.env.CONSUL_HOST != null) {
  consulhost = process.env.CONSUL_HOST;
}

if (consulhost.indexOf('http://') !== 0) {
  consulhost = "http://" + consulhost;
}

key = "tugboat/" + host + "/";

path = "/v1/kv/" + key;

url = "" + consulhost + path + "?keys";

temperrors = function(errors) {
  var e, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = errors.length; _i < _len; _i++) {
    e = errors[_i];
    _results.push(console.error(e));
  }
  return _results;
};

fatalerror = function(e) {
  console.error(e);
  return process.exit(-1);
};

launch = function() {
  console.log("Tugboat Consul is running for host " + host + "...");
  return new Watch(url, function(groups) {
    var tugboat;
    groups = groups.map(function(g) {
      return g.substr(key.length);
    }).filter(function(g) {
      if (g.length === 0) {
        return false;
      }
      if (g.indexOf('/') !== -1) {
        return false;
      }
      return true;
    });
    tugboat = new Tugboat.API();
    return tugboat.init(function(errors) {
      if (errors != null) {
        return temperrors(errors);
      }
      return tugboat.diff(function(err, results) {
        var g, group, groupname, tasks, _fn, _fn1, _i, _len;
        tasks = [];
        _fn = function(g) {
          return tasks.push(function(cb) {
            var group;
            if (results[g] == null) {
              return console.log(("" + g + " is (unknown) and has no containers... nothing to do").magenta);
            } else {
              group = results[g];
              if (!group.isknown) {
                console.log("tug up " + g + " (unknown)...");
              } else {
                console.log("tug up " + g + "...");
              }
              delete results[g];
              return tugboat.groupup(group, function(errors, messages) {
                var message, _j, _k, _len1, _len2;
                for (_j = 0, _len1 = errors.length; _j < _len1; _j++) {
                  err = errors[_j];
                  if (err.stack) {
                    console.error(err.stack);
                  } else {
                    console.error(err);
                  }
                }
                for (_k = 0, _len2 = messages.length; _k < _len2; _k++) {
                  message = messages[_k];
                  console.log(message);
                }
                return cb();
              });
            }
          });
        };
        for (_i = 0, _len = groups.length; _i < _len; _i++) {
          g = groups[_i];
          _fn(g);
        }
        _fn1 = function(groupname, group) {
          return tasks.push(function(cb) {
            console.log("tug rm " + groupname);
            return cb();
          });
        };
        for (groupname in results) {
          group = results[groupname];
          _fn1(groupname, group);
        }
        return series(tasks, function() {});
      });
    });
  });
};

http.get(url, function(res) {
  var params;
  if (res.statusCode !== 404) {
    return launch();
  }
  params = parse_url(consulhost);
  params.path = path;
  params.method = 'PUT';
  return http.request(params, function(res) {
    return launch();
  }).on('error', fatalerror).end();
}).on('error', fatalerror);
